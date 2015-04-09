require 'sinatra'
require 'json'
require "stringex"

require File.expand_path('../splooshed.rb', __FILE__)

get '/' do
  File.read(File.join('public', 'index.html'))
end

get '/list_foods' do
  WaterData.instance.search(params["term"]).to_json
end

get '/food' do
  content_type :json
  FoodLine.parse(request["inputAmount"], request["inputUnit"], request["inputFood"]).to_json
end

post '/recipe_line' do
  content_type :json
  RecipeLine.parse(request.body.read).to_json
end

post '/recipe' do
  content_type :json
  Recipe.parse(request.body.read).to_json
end