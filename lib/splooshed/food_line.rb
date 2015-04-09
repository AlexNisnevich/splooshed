class FoodLine
  def self.parse amount, unit, food
    RecipeLine.parse "#{amount} #{unit} of #{food}"
  end
end