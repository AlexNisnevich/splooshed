require 'sinatra'
require 'json'

require File.expand_path('../splooshed.rb', __FILE__)

get '/' do
  File.read(File.join('public', 'index.html'))
end

get '/food' do
  content_type :json
  line = "#{request["inputAmount"]} #{request["inputUnit"]} of #{request["inputFood"]}"
  parse_recipe_line(line).to_json
end

post '/recipe' do
  content_type :json
  data = request.body.read
  responses = data.split("\n").map {|l| parse_recipe_line l}
  responses.to_json
end