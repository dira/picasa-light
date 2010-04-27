require 'rubygems'
require 'sinatra'
get '/' do
  "Must add help here"
end

get '/:username' do
  "Albums of #{params[:username]}"
end

get '/:username/:album' do
  "Photos of #{params[:username]}, album #{params[:album]}"
end

