require 'sinatra'
require 'haml'
require 'json'
require 'net/http'
require './lib/picasa'
require './lib/helpers'

class LightPicasaError < StandardError
end

class LightPicasa < Sinatra::Base
  set :public, "public"

  get '/' do
    haml :index
  end

  get '/stylesheet.css' do
    content_type 'text/css', :charset => 'utf-8'
    sass :stylesheet
  end

  get '/:username/?' do
    pass if (params[:username].downcase == 'javascript')

    begin
      @user = PicasaAPI::user(params[:username])
    rescue LightPicasaError => err
      error(404, "Wrong user name, must be the same as in Picasa")
    rescue StandardError => err
      p err
      raise
    end
    @page_title = @user[:name]

    add_http_cache
    haml :user
  end

  ['/:username/:album_id/*/?', '/:username/:album_id/?'].each do |route|
    get route do
      pass if (params[:username].downcase == 'javascript')

      begin
        @album = PicasaAPI::album(params[:username], params[:album_id])
      rescue LightPicasaError => err
        error(404, "Wrong user name or album, how did you get here?")
      rescue StandardError => err
        p err
        raise
      end
      @page_title = @album[:title]

      add_http_cache
      haml :album
    end
  end

  def add_http_cache
    cache_control :public, :max_age => 60*60 if production?
  end

  helpers do
    include Helpers
  end
end
