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

  def gallons_per_kg(food)
    begin
      @data[food]["gallons_per_kg"]
    rescue
      throw "No water usage data found for food: #{food}"
    end
  end

  def fuzzy_food_lookup(food)
    key = FuzzyMatch.new(@data.keys, :threshold => 0.1).find(food) || FuzzyMatch.new(@data.keys, :threshold => 0.2).find(food.split(" ").last)
    unless key
      throw "No water usage data found for food: #{food}" 
    end
    key
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