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