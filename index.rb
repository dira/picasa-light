require 'rubygems'
require 'sinatra'
require 'json'
require 'net/http'
require 'haml'
require 'sass'

get '/' do
  haml :index
end

get '/stylesheet.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :stylesheet
end

get '/:username/?' do
  @user = user(params[:username]) rescue error(404, "Wrong user name, must be the same as in Picasa")
  add_http_cache
  haml :user
end

['/:username/:album_id/*/?', '/:username/:album_id/?'].each do |route|
  get route do
    @album = album(params[:username], params[:album_id]) rescue error(404, "Wrong user name or album, how did you get here?")
    add_http_cache
    haml :album
  end
end

def add_http_cache
  cache_control :public, :max_age => 60*60
end

def user_url(username)
  URI.parse("http://picasaweb.google.com/data/feed/api/user/#{URI.escape(username)}?alt=json&fields=author,entry(title,gphoto:id,gphoto:name,media:group(media:thumbnail))")
end

def user(username)
  response = Net::HTTP.get_response(user_url(username))
  throw "Inexistent user" unless response.is_a? Net::HTTPOK

  feed = JSON.parse(response.body)['feed']
  albums = feed['entry'].map do |album|
    { :title => album["title"]["$t"],
      :id => album["gphoto$id"]["$t"],
      :uri => album["gphoto$name"]["$t"],
      :thumbnail => album["media$group"]["media$thumbnail"][0]["url"]
    }
  end
  { :name => feed["author"][0]["name"]["$t"], :albums => albums }
end

def album_url(username, album)
  URI.parse("http://picasaweb.google.com/data/feed/api/user/#{URI.escape(username)}/albumid/#{URI.escape(album)}?alt=json&fields=title,entry(content)")
end

def photo_with_size(url, size)
  url = url.gsub(/\/s\d{1,3}(-.)?/, '') # remove the size specifier, if present
  url.gsub(/(\/[^\/]+)$/, '/s' + size.to_s + '\1') # add the new one
end

def album(username, album)
  response = Net::HTTP.get_response(album_url(username, album))
  throw "Inexistent user or album" unless response.is_a? Net::HTTPOK

  feed = JSON.parse(response.body)['feed']
  photos = feed['entry'].map do |photo|
    { :src => photo["content"]["src"] }
  end
  { :title => feed["title"]["$t"], :photos => photos }
end
