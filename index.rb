require 'rubygems'
require 'sinatra'
require 'json'
require 'net/http'
require 'haml'
require 'sass'

get '/' do
  "Must add help here"
end

get '/stylesheet.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :stylesheet
end

get '/:username/?' do
  @albums = albums(params[:username])
  haml :user
end

get '/:username/:album/?' do
  @photos = photos(params[:username], params[:album])
  haml :photos
end


def albums_url(username)
  URI.parse("http://picasaweb.google.com/data/feed/api/user/#{URI.escape(username)}?alt=json")
end

def photos_url(username, album)
  URI.parse("http://picasaweb.google.com/data/feed/api/user/#{URI.escape(username)}/albumid/#{URI.escape(album)}?alt=json")
end

def albums(username)
  content = Net::HTTP.get(albums_url(username))
  JSON.parse(content)['feed']['entry'].map do |album|
    { :title => album["title"]["$t"],
      :id => album["gphoto$id"]["$t"],
      :thumbnail => album["media$group"]["media$thumbnail"][0]["url"]
    }
  end
end

def photos(username, album)
  content = Net::HTTP.get(photos_url(username, album))
  JSON.parse(content)['feed']['entry'].map do |photo|
    { :src => photo["content"]["src"].gsub(/(\/[^\/]+)$/, '/s400\1') }
  end
end
