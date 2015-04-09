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
        amount * measure["eqv"] * conversion / 1000
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