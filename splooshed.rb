require 'open-uri'
require 'json'
require 'yaml'
require 'singleton'

require 'ingreedy'
require 'dalli'
require 'fuzzy_match'

USDA_API_KEY = "nkmsGMj3ChXLsbIBy22EwbORKK1BloEzmXFo5UdT"

WEIGHTS_TO_KG = {
  :gram => 0.001,
  :kilogram => 1.0,
  :milligram => 0.000001,
  :ounce => 0.028349,
  :pound => 0.453592
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

HARDCODED_NDBNOS = {
  "rice" => "20054",
  "canola oil" => "04582",
  "vegetable oil" => "04582"
}

class WaterData
  include Singleton

  def initialize
    @data = load_water_data
  end

  def search(term)
    # list all food names that don't have illegal characters ("?") and have gallons_per_kg defined
    # and that match search term, if any
    @data.select {|k, v| (!term || k.include?(term)) && !k.include?("?") && v && v["gallons_per_kg"] }.keys
  end

  def fuzzy_lookup(food)
    key = FuzzyMatch.new(@data.keys, :threshold => 0.1).find(food)
    key = FuzzyMatch.new(@data.keys, :threshold => 0.2).find(food.split(" ").last) unless key
    begin
      puts "Water usage record found matching #{@name}: #{key}"
      @data[key]["gallons_per_kg"]
    rescue => e
      throw "No water usage data found for food: #{@name}"
    end
  end

  private

  def load_water_data 
    data = YAML.load(open("water_data.yaml"))
    data["synonyms"].each do |synonym, definition|
      data["data"][synonym] = data["data"][definition]
    end
    data["data"]
  end
end

class Cache
  include Singleton

  def initialize
    @dc = Dalli::Client.new(
      (ENV["MEMCACHIER_SERVERS"] || "localhost:11211").split(","),
      {
        :username => ENV["MEMCACHIER_USERNAME"],
        :password => ENV["MEMCACHIER_PASSWORD"],
        :namespace => "app_v1",
        :failover => true,
        :socket_timeout => 1.5,
        :socket_failure_delay => 0.2
      }
    )
  end

  def get_and_cache(key)
    value = try_lookup(key)
    if value
      value
    else
      value = yield
      try_set(key, value)
      value
    end
  end

  private 

  def try_lookup(key)
    begin
      value = @dc.get(key)
      puts "Retrieving from cache: #{key} => #{value}" if value
      value
    rescue => e
      puts e
      nil
    end
  end

  def try_set(key, value)
    @dc.set(key, value) rescue nil
  end
end

class Recipe
  def self.parse lines
    lines.split("\n").map {|l| RecipeLine.parse l }
  end
end

class FoodLine
  def self.parse amount, unit, food
    RecipeLine.parse "#{amount} #{unit} of #{food}"
  end
end

class RecipeLine
  attr_accessor :food, :parse_result

  def self.parse line
    puts "----------------------------------------------------"
    begin
      recipe_line = self.new(line)

      {
        :success => true,
        :input => line,
        :parsed_input => recipe_line.parse_result,
        :food => recipe_line.food.name,
        :gallons => recipe_line.gallons
      }
    rescue => e
      puts e
      {
        :success => false,
        :error => e.message.sub('uncaught throw ', ''),
        :input => line,
        :parsed_input => (recipe_line.parse_result rescue line)
      }
    end
  end

  def initialize(line)
    line = preprocess_recipe_line(line)

    begin
      # if Ingreedy parse fails, try again with everything before first number removed
      result = Ingreedy.parse(line) rescue Ingreedy.parse(line.sub(/.*?(?=[0-9])/im, ""))
    rescue
      if is_negligible? line
        @food = Food.new line
        @amount = 0.0
        @parse_result = line
      else
        throw "Unable to parse line: #{line}"
      end
    end

    puts "Parsed as: #{result.amount}, #{result.unit}, #{result.ingredient}"

    @food = Food.new result.ingredient
    @amount = result.amount
    @unit = result.unit
    @parse_result = line.gsub(result.ingredient, @food.name)
  end

  def gallons
    if @amount == 0.0
      0.0
    else
      @food.gallons(@amount, @unit)
    end
  end

  private

  def preprocess_recipe_line(line)
    line
      .to_ascii  # to avoid errors further in pipeline, converts non-ascii chars to "??" or "???"
      .downcase  # convert to lowercase for convenience
      .split(" ").reject {|w| DUMMY_WORDS.include?(w) }.join(" ")  # remove dummy words like "about"
      .split(",").first  # remove everything after commas
      .sub("vegetable or canola", "canola")  # fix up common "or" statements
      .sub("canola or vegetable", "canola")
      .split(" or ").first  # remove every after "or"
      .sub("jalape??o", "jalapeno")  # and let's fix up common non-ASCII ingredient names too
      .sub("cr??me fra??che", "creme fraiche")
      .sub("1???2", "1/2")  # most common single-character fractions
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

  def is_negligible?(line)
    line.split(" ").length == 1 || line.include?("optional") || line == "kosher salt"
  end
end

class Food
  attr_accessor :name

  def initialize(name)
    @name = name.to_s.gsub(/\(.*\)/, "").strip  # remove everything inside parentheses
  end

  def gallons(amount, unit)
    if unit.nil? && GALLONS_OF_WATER_FOR_UNITLESS_ITEMS.include?(food_name)
      GALLONS_OF_WATER_FOR_UNITLESS_ITEMS[food_name] * amount
    else
      weight_in_kg(amount, unit) * gallons_water_per_kg
    end
  end

  private

  def gallons_water_per_kg
    WaterData.instance.fuzzy_lookup(@name)
  end

  def lookup_ndbno(name)
    if HARDCODED_NDBNOS.include? name
      return HARDCODED_NDBNOS[name]
    else
      Cache.instance.get_and_cache("ndbno:#{name}") {
        begin
          response = JSON.parse(open("http://api.nal.usda.gov/usda/ndb/search/?format=json&q=#{name}&max=25&offset=0&api_key=#{USDA_API_KEY}".gsub(" ", "%20")).read)
          foods = response["list"]["item"].reject {|m| IGNORED_FOOD_GROUPS.include?(m["group"])}
          puts "Food found: #{foods.first["name"]}"
          foods.first["ndbno"]
        rescue
          throw "Unknown food: #{name}"
        end
      }
    end
  end

  def weight_in_kg(amount, unit)
    if WEIGHTS_TO_KG.include? unit
      # unit is a unit of weight - convert it to grams here
      amount * WEIGHTS_TO_KG[unit]
    else
      # unit is (probably) a unit of volume or other kind of measurement - try to look it up with the USDA API

      # If ndbno lookup fails, try again with just the last word of the food name
      ndbno = begin
        lookup_ndbno(@name)
      rescue => e 
        puts e.message
        lookup_ndbno(@name.split(" ").last)
      end

      expected_measure = VOLUME_TO_CANONICAL_VOLUME[unit] || unit.to_s

      measures = Cache.instance.get_and_cache("measures:#{ndbno}") {
        response = JSON.parse(open("http://api.nal.usda.gov/usda/ndb/reports/?format=json&ndbno=#{ndbno}&max=25&offset=0&api_key=#{USDA_API_KEY}").read)
        response["report"]["food"]["nutrients"].first["measures"]
      }

      puts "Units of measure found: #{measures.map {|m| m["label"]}.join(", ")}"
      begin
        measure = measures.find {|m| measure_conversion(m["label"], expected_measure)}
        conversion = measure_conversion(measure["label"], expected_measure)
        puts "Unit of measure selected: #{measure["label"]} [#{expected_measure} * #{conversion}]"
        amount * measure["eqv"] * conversion
      rescue
        throw "Unknown unit of measurement: #{unit} of #{@name}"
      end
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
end