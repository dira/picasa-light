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
  @user = user(params[:username])
  haml :user
end

['/:username/:album_id/*/?', '/:username/:album_id/?'].each do |route|
  get route do
    @album = album(params[:username], params[:album_id])
    haml :album
  end
end


def user_url(username)
  URI.parse("http://picasaweb.google.com/data/feed/api/user/#{URI.escape(username)}?alt=json&fields=author,entry(title,gphoto:id,gphoto:name,media:group(media:thumbnail))")
end

def photos_url(username, album)
  URI.parse("http://picasaweb.google.com/data/feed/api/user/#{URI.escape(username)}/albumid/#{URI.escape(album)}?alt=json&fields=title,entry(content)")
end

def photo_with_size(url, size)
  url = url.gsub(/\/s\d{1,3}(-.)?/, '') # remove the size specifier, if present
  url.gsub(/(\/[^\/]+)$/, '/s' + size.to_s + '\1') # add the new one
end

def user(username)
  content = Net::HTTP.get(user_url(username))
  feed = JSON.parse(content)['feed']
  albums = feed['entry'].map do |album|
    { :title => album["title"]["$t"],
      :id => album["gphoto$id"]["$t"],
      :uri => album["gphoto$name"]["$t"],
      :thumbnail => album["media$group"]["media$thumbnail"][0]["url"]
    }
  end
  { :name => feed["author"][0]["name"]["$t"], :albums => albums }
end

def album(username, album)
  content = Net::HTTP.get(photos_url(username, album))
  feed = JSON.parse(content)['feed']
  photos = feed['entry'].map do |photo|
    { :src => photo["content"]["src"] }
  end
  { :title => feed["title"]["$t"], :photos => photos }
end
