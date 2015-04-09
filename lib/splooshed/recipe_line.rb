class RecipeLine
  include Logging
  extend Logging

  attr_accessor :food, :gallons

  def self.parse line
    begin
      recipe_line = self.new(line)

      result = {
        :success => true,
        :input => line,
        :parsed_input => recipe_line.parse_result,
        :food => recipe_line.food.name,
        :gallons => recipe_line.gallons
      }
      log_info "Result: #{result}"
      result
    rescue => e
      log_error e
      {
        :success => false,
        :error => e.message.sub('uncaught throw ', '').gsub('"', ''),
        :input => line,
        :parsed_input => (recipe_line.parse_result rescue line)
      }
    end
  end

  def initialize(line)
    log_info "Input: #{line}"
    @line = preprocess_recipe_line(line)
    log_info "Processed into: #{@line}"

    begin
      # if Ingreedy parse fails, try again with everything before first number removed

      line_without_parens = @line.gsub(/ \(.*\)/, "")

      @parse = Ingreedy.parse(@line) rescue Ingreedy.parse(@line.sub(/.*?(?=[0-9])/im, ""))
      parse_without_parens = Ingreedy.parse(line_without_parens) rescue Ingreedy.parse(line_without_parens.sub(/.*?(?=[0-9])/im, ""))

      @parse.unit = parse_without_parens.unit

      puts parse_without_parens
    rescue
      if is_negligible? @line
        @food = Food.new @line
        @amount = 0.0
      else
        throw "Unable to parse line: #{line}"
      end
    end

    log_info "Parsed as: #{@parse.amount}, #{@parse.unit}, #{@parse.ingredient}"

    @food = Food.new @parse.ingredient
    @amount = @parse.amount
    @unit = @parse.unit

    @gallons = if @amount == 0.0
      0.0
    else
      @food.gallons(@amount, @unit)
    end
  end

  def parse_result
    @line.gsub(@parse.ingredient, @food.name) rescue @line
  end

  private

  def preprocess_recipe_line(line)
    line = remove_parens(line)
    line
      .to_ascii  # to avoid errors further in pipeline, converts non-ascii chars to "??" or "???"
      .downcase  # convert to lowercase for convenience
      .split(" ").reject {|w| DUMMY_WORDS.include?(w.sub(",", "")) }.join(" ")  # remove dummy words
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

  def remove_parens(str)
    # http://stackoverflow.com/a/1952970
    while str.gsub!(/\([^()]*?\)/, ''); end
    str
  end
end