require 'rubygems'
require 'sinatra'
require 'test/spec'
require 'rack/test'
require 'fakeweb'

require File.dirname(__FILE__) + '/../index'

set :environment, :test

include Rack::Test::Methods

def app
  LightPicasa
end

def fake_picasa(kind, success = true)
  api_base = "http://picasaweb.google.com/data/feed/api"
  if (kind.to_s == 'user')
    url = %r(#{api_base}/user/[^/]+\?.*)
  else
    url = %r(#{api_base}/user/[^/]+/albumid/[^/]+\?.*)
  end

  if success
    content = File.read(File.dirname(__FILE__) + "/fixtures/#{kind}.json")
    FakeWeb.register_uri(:get, url, :body => content)
  else
    FakeWeb.register_uri(:get, url, :body => "", :status => 404)
  end
end
