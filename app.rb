require 'sinatra'
require 'json'
require "stringex"

require File.expand_path('../splooshed.rb', __FILE__)

get '/' do
  File.read(File.join('public', 'index.html'))
end

get '/list_foods' do
  # list all food names that don't have illegal characters ("?") and have gallons_per_kg defined
  $water_data.select {|k, v| k.include?(params["term"]) && !k.include?("?") && v && v["gallons_per_kg"] }.keys.to_json
end

get '/food' do
  content_type :json
  line = "#{request["inputAmount"]} #{request["inputUnit"]} of #{request["inputFood"]}".to_ascii
  parse_recipe_line(line).to_json
end

post '/recipe' do
  content_type :json
  data = request.body.read
  responses = data.split("\n").map {|l| parse_recipe_line l.to_ascii}
  responses.to_json
end