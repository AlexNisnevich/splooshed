class Recipe
  def self.parse lines
    lines.split("\n").map {|l| RecipeLine.parse l }
  end
end