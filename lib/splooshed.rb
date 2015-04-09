require 'open-uri'
require 'json'
require 'yaml'
require 'singleton'

require 'ingreedy'
require 'dalli'
require 'fuzzy_match'

[
  "cache.rb",
  "constants.rb",
  "food.rb",
  "food_line.rb",
  "recipe.rb",
  "recipe_line.rb",
  "water_data.rb"
].each do |file_name|
  require File.expand_path("../splooshed/#{file_name}", __FILE__)
end
