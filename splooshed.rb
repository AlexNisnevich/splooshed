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
  "cup->tbsp" => 16.0,
  "cup->tsp" => 48.0,
  "tbsp->tsp" => 3.0
}

IGNORED_FOOD_GROUPS = [
  "Baked Products",
  "Baby Foods"
]

DUMMY_WORDS = [
  "about",
  "and",
  "fresh",
  "minced",
  "peeled",
  "cut",
  "chopped"
]

options = { :namespace => "app_v1", :compress => true }
$dc = Dalli::Client.new('localhost:11211', options)

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
    result = Ingreedy.parse(preprocess_recipe_line(line))
    puts "Parsed as: #{result.amount}, #{result.unit}, #{result.ingredient}"
    food_name = result.ingredient.to_s.gsub(/\(.*\)/, "").strip  # remove everything inside parentheses
    weight_in_kg = result.amount * weight_by_food_grams(food_name, result.unit) / 1000
    gallons_water_per_kg = lookup_gallons_water_per_kg_by_food(food_name)
    {
      :success => true,
      :input => line,
      :food => food_name,
      :gallons => gallons_water_per_kg * weight_in_kg,
      :weight_in_kg => weight_in_kg,
      :gallons_water_per_kg => gallons_water_per_kg
    }
  rescue => e
    puts e
    {
      :success => false,
      :error => e.message,
      :input => line
    }
  end
end

def lookup_gallons_water_per_kg_by_food(food_name)
  key = FuzzyMatch.new($water_data.keys, :threshold => 0.2).find(food_name)
  key = FuzzyMatch.new($water_data.keys, :threshold => 0.2).find(food_name.split(" ").last) unless key
  if key
    puts "Water usage record found matching #{food_name}: #{key}"
    $water_data[key]["gallons_per_kg"]
  else
    throw "No water usage data found for food: #{food_name}"
  end
end

def preprocess_recipe_line(line)
  line
    .downcase  # convert to lowercase for convenience
    .split(" ").reject {|w| DUMMY_WORDS.include?(w) }.join(" ")  # remove dummy words like "about"
    .split(",").first  # remove everything after commas
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
      throw "Unknown unit of measurement: '#{unit} of #{food_name}'"
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
  if found_measure.include? expected_measure
    1
  elsif VOLUME_CONVERSIONS.include? "#{found_measure}->#{expected_measure}"
    1.0 / VOLUME_CONVERSIONS["#{found_measure}->#{expected_measure}"]
  elsif VOLUME_CONVERSIONS["#{expected_measure}->#{found_measure}"]
    VOLUME_CONVERSIONS["#{expected_measure}->#{found_measure}"]
  else
    nil
  end
end

def get_and_cache_ndbno_for_food(food_name)
  key = "ndbno:#{food_name}"
  if $dc.get(key)
    puts "Retrieving from cache: #{key}"
    $dc.get(key)
  else
    begin
      response = JSON.parse(open("http://api.nal.usda.gov/usda/ndb/search/?format=json&q=#{food_name}&max=25&offset=0&api_key=#{USDA_API_KEY}".gsub(" ", "%20")).read)
      foods = response["list"]["item"].reject {|m| IGNORED_FOOD_GROUPS.include? m["group"] }
      puts "Food found: #{foods.first["name"]}"
      ndbno = foods.first["ndbno"]
      $dc.set(key, ndbno)
      ndbno
    rescue
      throw "Unknown food: #{food_name}"
    end
  end
end
