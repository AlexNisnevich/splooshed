require 'open-uri'
require 'json'
require 'yaml'

require 'ingreedy'
require 'dalli'
require 'fuzzy_match'

USDA_API_KEY = "nkmsGMj3ChXLsbIBy22EwbORKK1BloEzmXFo5UdT"

WEIGHTS_TO_GRAMS = {
  :gram => 1.0,
  :kilogram => 1000.0,
  :milligram => 0.001,
  :ounce => 28.349,
  :pound => 453.592
}

VOLUME_TO_CANONICAL_VOLUME = {
  :tablespoon => "tbsp",
  :teaspoon => "tsp"
}

VOLUME_CONVERSIONS = {
  "dash->pinch" => 1.0,
  "cup->tablespoon" => 16.0,
  "cup->tbsp" => 16.0,
  "cup->teaspoon" => 48.0,
  "cup->tsp" => 48.0,
  "tablespoon->teaspoon" => 3.0,
  "tbsp->tsp" => 3.0,
  "tbsp->tsp unpacked" => 3.0,
  "servings->medium" => 1.0,
  "servings->med" => 1.0,
  "medium->fruit" => 1.0,
  "medium->clove" => 1.0,
  "large->pepper" => 1.0,
  "small->pepper" => 0.7,
  "large->cup chopped" => 1.0,
  "quart->cup" => 4.0
}

IGNORED_FOOD_GROUPS = [
  "Baked Products",
  "Baby Foods",
  "Snacks",
  "Fast Foods"
]

DUMMY_WORDS = [
  "about", "and", "fresh", "minced", "peeled", "cut", "chopped", "packed", "shaved", "freshly",
  "squeezed", "Italian", "leaves", "finely", "boneless", "shredded", "sliced", "toasted", "kosher"
]

GALLONS_OF_WATER_FOR_UNITLESS_ITEMS = {
  "cigarette" => 0.352,
  "cigarettes" => 0.352
}

$dc = Dalli::Client.new((ENV["MEMCACHIER_SERVERS"] || "localhost:11211").split(","),
                    {:username => ENV["MEMCACHIER_USERNAME"],
                     :password => ENV["MEMCACHIER_PASSWORD"],
                     :namespace => "app_v1",
                     :failover => true,
                     :socket_timeout => 1.5,
                     :socket_failure_delay => 0.2
                    })

def load_water_data 
  data = YAML.load(open("water_data.yaml"))
  data["synonyms"].each do |synonym, definition|
    data["data"][synonym] = data["data"][definition]
  end
  data["data"]
end

$water_data = load_water_data

def parse_recipe_line(line)
  puts "----------------------------------------------------"
  begin
    preprocessed_line = preprocess_recipe_line(line)

    # if Ingreedy parse fails, try again with everything before first number removed
    begin
      result = Ingreedy.parse(preprocessed_line) rescue Ingreedy.parse(preprocessed_line.sub(/.*?(?=[0-9])/im, ""))
    rescue
      if is_negligible? preprocessed_line
        return {
          :success => true,
          :parsed_input => preprocessed_line,
          :gallons => 0.0
        }
      else
        throw "Unable to parse line: #{preprocessed_line}"
      end
    end

    puts "Parsed as: #{result.amount}, #{result.unit}, #{result.ingredient}"
    food_name = result.ingredient.to_s.gsub(/\(.*\)/, "").strip  # remove everything inside parentheses

    if result.unit.nil? && GALLONS_OF_WATER_FOR_UNITLESS_ITEMS.include?(food_name)
      gallons_per_unit = GALLONS_OF_WATER_FOR_UNITLESS_ITEMS[food_name]

      {
        :success => true,
        :input => line,
        :parsed_input => preprocessed_line.gsub(result.ingredient, food_name),
        :food => food_name,
        :gallons => gallons_per_unit * result.amount
      }
    else
      weight_in_kg = result.amount * weight_by_food_grams(food_name, result.unit) / 1000.0

      gallons_lookup_result = lookup_gallons_water_per_kg_by_food(food_name)
      gallons_water_per_kg = gallons_lookup_result[:gallons_per_kg]
      food_name = gallons_lookup_result[:matched_name]
      
      {
        :success => true,
        :input => line,
        :parsed_input => preprocessed_line.gsub(result.ingredient, food_name),
        :food => food_name,
        :gallons => gallons_water_per_kg * weight_in_kg,
        :weight_in_kg => weight_in_kg,
        :gallons_water_per_kg => gallons_water_per_kg
      }
    end
  rescue => e
    puts e
    {
      :success => false,
      :error => e.message.sub('uncaught throw ', ''),
      :input => line,
      :parsed_input => (preprocessed_line.gsub(result.ingredient, food_name) rescue preprocessed_line)
    }
  end
end

def is_negligible?(line)
  line.split(" ").length == 1 || line.include?("optional") || line == "kosher salt"
end

def lookup_gallons_water_per_kg_by_food(food_name)
  key = FuzzyMatch.new($water_data.keys, :threshold => 0.1).find(food_name)
  key = FuzzyMatch.new($water_data.keys, :threshold => 0.2).find(food_name.split(" ").last) unless key
  begin
    puts "Water usage record found matching #{food_name}: #{key}"
    {
      :matched_name => key,
      :gallons_per_kg => $water_data[key]["gallons_per_kg"]
    }
  rescue => e
    throw "No water usage data found for food: #{food_name}"
  end
end

def preprocess_recipe_line(line)
  line
    .downcase  # convert to lowercase for convenience
    .split(" ").reject {|w| DUMMY_WORDS.include?(w) }.join(" ")  # remove dummy words like "about"
    .split(",").first  # remove everything after commas
    .sub("vegetable or canola", "canola")  # fix up common "or" statements
    .sub("canola or vegetable", "canola")
    .split(" or ").first  # remove every after "or"
    .sub("jalape??o", "jalapeno")  # and let's fix up common non-ASCII ingredient names too
    .sub("cr??me fra??che", "creme fraiche")
    .sub("1???2", "1/2")
    .sub("1???3", "1/3")
    .sub("1???4", "1/4")
    .sub("1???8", "1/8")
    .sub("2???3", "2/3")
    .sub("3???4", "3/4")
    .sub("1 to 2", "1.5")  # we're bad at ranges, let's hardcode the most common ones
    .sub("2 to 3", "2.5")
    .sub("3 to 4", "3.5")
    .sub("2 to 4", "3")
    .sub("garlic cloves", "raw garlic")  # misc
end

def weight_by_food_grams(food_name, unit)
  if WEIGHTS_TO_GRAMS.include? unit
    # unit is a unit of weight - convert it to grams here
    WEIGHTS_TO_GRAMS[unit]
  else
    # unit is (probably) a unit of volume or other kind of measurement - try to look it up with the USDA API

    ndbno = begin 
      get_and_cache_ndbno_for_food(food_name)
    rescue => e # try again with just the last word of the food name
      puts e.message
      get_and_cache_ndbno_for_food(food_name.split(" ").last)
    end

    expected_measure = VOLUME_TO_CANONICAL_VOLUME[unit] || unit.to_s

    measures = get_and_cache_measures_for_food(ndbno)    
    puts "Units of measure found: #{measures.map {|m| m["label"]}.join(", ")}"
    begin
      measure = measures.find {|m| measure_conversion(m["label"], expected_measure)}
      conversion = measure_conversion(measure["label"], expected_measure)
      puts "Unit of measure selected: #{measure["label"]} [#{expected_measure} * #{conversion}]"
      measure["eqv"] * conversion
    rescue
      throw "Unknown unit of measurement: #{unit} of #{food_name}"
    end
  end
end

def get_and_cache_measures_for_food(ndbno)
  key = "measures:#{ndbno}"
  if $dc.get(key)
    puts "Retrieving from cache: #{key}"
    $dc.get(key)
  else
    response = JSON.parse(open("http://api.nal.usda.gov/usda/ndb/reports/?format=json&ndbno=#{ndbno}&max=25&offset=0&api_key=#{USDA_API_KEY}").read)
    measures = response["report"]["food"]["nutrients"].first["measures"]
    $dc.set(key, measures)
    measures
  end
end

def measure_conversion(found_measure, expected_measure)
  found_measure = found_measure.gsub(/\(.*\)/, "").strip
  expected_measure = expected_measure.gsub(/\(.*\)/, "").strip

  if found_measure.include? expected_measure
    1
  elsif VOLUME_CONVERSIONS.include? "#{found_measure}->#{expected_measure}"
    1.0 / VOLUME_CONVERSIONS["#{found_measure}->#{expected_measure}"]
  elsif VOLUME_CONVERSIONS.include? "#{expected_measure}->#{found_measure}"
    VOLUME_CONVERSIONS["#{expected_measure}->#{found_measure}"]
  else
    nil
  end
end

HARDCODED_NDBNOS = {
  "rice" => "20054",  # otherwise we can't get rice right :-(
  "canola oil" => "04582",
  "vegetable oil" => "04582"
}

INVALID_NDBNOS = [
  "01123"  # this one ndbno crashes for some reason ... maybe there are others like it?
] 

def get_and_cache_ndbno_for_food(food_name)
  if HARDCODED_NDBNOS.include? food_name
    return HARDCODED_NDBNOS[food_name]
  end

  key = "ndbno:#{food_name}"
  if $dc.get(key) && !INVALID_NDBNOS.include?($dc.get(key))
    puts "Retrieving from cache: #{key}"
    $dc.get(key)
  else
    begin
      response = JSON.parse(open("http://api.nal.usda.gov/usda/ndb/search/?format=json&q=#{food_name}&max=25&offset=0&api_key=#{USDA_API_KEY}".gsub(" ", "%20")).read)
      foods = response["list"]["item"].reject {|m| IGNORED_FOOD_GROUPS.include?(m["group"]) || INVALID_NDBNOS.include?(m["ndbno"]) }
      puts "Food found: #{foods.first["name"]}"
      ndbno = foods.first["ndbno"]
      $dc.set(key, ndbno)
      ndbno
    rescue
      throw "Unknown food: #{food_name}"
    end
  end
end
