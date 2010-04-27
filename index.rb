require 'rubygems'
require 'sinatra'
require 'json'
require 'net/http'

get '/' do
  "Must add help here"
end

get '/:username' do
  "Albums of #{params[:username]}: #{albums(params[:username])}"
end

get '/:username/:album' do
  "Photos of #{params[:username]}, album #{params[:album]}: #{photos(params[:username], params[:album])}"
end

def albums(username)
  uri = URI.parse("http://picasaweb.google.com/data/feed/api/user/#{URI.escape(username)}?alt=json")
  content = Net::HTTP.get(uri)
  albums = JSON.parse(content)['feed']['entry']
  albums.map do |album|
    [album["title"]["$t"], album["gphoto$id"]["$t"], album["media$group"]["media$thumbnail"][0]["url"]]
  end
end

def photos(username, album)
  uri = URI.parse("http://picasaweb.google.com/data/feed/api/user/#{URI.escape(username)}/albumid/#{URI.escape(album)}?alt=json")
  content = Net::HTTP.get(uri)
  photos = JSON.parse(content)['feed']['entry']
  photos.map do |photo|
    photo["content"]["src"]
  end
end
