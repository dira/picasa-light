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

def fake_picasa(kind, success = true, *options)
  options = options[0] || {}
  api_base = "http://picasaweb.google.com/data/feed/api"
  id_part = options[:id] ? options[:id] : "[^/]+"

  if (kind.to_s == 'user')
    url = %r(#{api_base}/user/#{id_part}\?.*)
  else
    url = %r(#{api_base}/user/[^/]+/albumid/#{id_part}\?.*)
  end

  content = File.read(File.dirname(__FILE__) + "/fixtures/#{kind}#{options[:empty] ? '.empty' : ''}.json")
  if success
    FakeWeb.register_uri(:get, url, :body => content)
  else
    FakeWeb.register_uri(:get, url, :body => "", :status => 404)
  end
end
