class Food
  include Logging

  attr_accessor :name

  def initialize(name)
    @name = name.to_s
      .strip  # remove excess space
      .sub(/.*or.*(canola|vegetable).*oil/, "vegetable oil")
      .split(",").first  # remove everything after commas
      .split(" or ").first  # remove every after "or"
      .split(" for ").first  # remove every after "for"
    log_info "Food name \"#{name}\" interpreted as \"#@name\""
  end

  def gallons(amount, unit)
    if unit.nil? && GALLONS_OF_WATER_FOR_UNITLESS_ITEMS.include?(@name)
      GALLONS_OF_WATER_FOR_UNITLESS_ITEMS[@name] * amount
    else
      weight_in_kg(amount, unit) * gallons_water_per_kg
    end
  end

  private

  def gallons_water_per_kg
    @name = WaterData.instance.fuzzy_food_lookup @name
    WaterData.instance.gallons_per_kg @name
  end

  def lookup_ndbno(name)
    puts HARDCODED_NDBNOS.keys
    if HARDCODED_NDBNOS.keys.any? {|k| name.include? k }
      return HARDCODED_NDBNOS.find {|k, v| name.include? k }.last  # (ruby weirdness - returns value of matching hash entry)
    else
      Cache.instance.get_and_cache("ndbno:#{name}") {
        begin
          response = JSON.parse(open("http://api.nal.usda.gov/usda/ndb/search/?format=json&q=#{name}&max=25&offset=0&api_key=#{USDA_API_KEY}".gsub(" ", "%20")).read)
          food = response["list"]["item"].select {|m| is_valid_usda_entry? m}.first
          log_info "Food found: #{food["name"]}"
          food["ndbno"]
        rescue => e
          throw "Unknown food: #{name}"
        end
      }
    end
  end

  def is_valid_usda_entry? entry
    if IGNORED_FOOD_GROUPS.include? entry["group"]
      return false
    end

    unless (entry["name"].downcase + "s").include?(@name.split(" ").last)
      log_error "Found food \"#{entry["name"]}\", but it didn't include the term \"#{@name.split(" ").last}\""
      return false
    end

    true
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
        log_error e.message
        lookup_ndbno(@name.split(" ").last)
      end

      measures = Cache.instance.get_and_cache("measures:#{ndbno}") {
        response = JSON.parse(open("http://api.nal.usda.gov/usda/ndb/reports/?format=json&ndbno=#{ndbno}&max=25&offset=0&api_key=#{USDA_API_KEY}").read)
        response["report"]["food"]["nutrients"].first["measures"]
      }

      log_info "Units of measure found: #{measures.map {|m| m["label"]}.join(", ")}"
      begin
        measure = measures.find {|m| measure_conversion(m["label"], unit)}
        conversion = measure_conversion(measure["label"], unit)
        log_info "Unit of measure selected: #{measure["label"]} [#{unit} * #{conversion}]"
        amount * measure["eqv"] * conversion / 1000
      rescue => e
        puts e
        throw "Unknown unit of measurement: #{unit} of #{@name}"
      end
    end
  end

  def measure_conversion(found_measure, expected_measure)
    found_measure = to_canonical_measure(found_measure)
    expected_measure = to_canonical_measure(expected_measure)

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

  def to_canonical_measure(measure)
    volume_to_canonical_volume = {
      "tablespoon" => "tbsp",
      "teaspoon" => "tsp"
    }

    measure = measure.to_s
      .gsub(/\(.*\)/, "")  # remove expressions in parens
      .strip  # remove excess whitespace
      .split(" ").reject {|w| DUMMY_WORDS.include?(w.sub(",", "")) }.join(" ")  # remove dummy words
    measure = volume_to_canonical_volume[measure] || measure
  end
end