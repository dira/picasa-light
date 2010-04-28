require File.dirname(__FILE__) + '/../index'
require 'test/spec'
require 'rack/test'
require 'fakeweb'

set :environment, :test

#Proc.new{|uri| p 'getting ', uri; 'abc'}

describe 'The Picasa Minimzer App' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  it "does not crash on main page" do
    get '/'
    last_response.should.be.ok
  end

  ["5455730045737996369",
   "5455730045737996369/"].each do |url|
    it "does not crash on existing user #{url}" do
      FakeWeb.register_uri(:get, %r(http://picasaweb.google.com/data/feed/api/.*), :body => File.read(File.dirname(__FILE__) + '/fixtures/user.json'))

      get "/#{url}"
      last_response.should.be.ok
    end
  end

  it "returns 404 for inexisting user id" do
    FakeWeb.register_uri(:get, %r(http://picasaweb.google.com/data/feed/api/.*), :body => "", :status => 404)

    get "/bad_user_id"
    last_response.should.not.be.ok
  end

  ["5455730045737996369",
   "5455730045737996369/",
   "5455730045737996369/ignored_album_name",
   "5455730045737996369/ignored_album_name/"].each do |url|
    it "does not crash on existing album #{url}" do
      user = 'smart_joe'
      FakeWeb.register_uri(:get, %r(http://picasaweb.google.com/data/feed/api/.*), :body => File.read(File.dirname(__FILE__) + '/fixtures/album.json'))


      get "/irina.dumitrascu/#{url}"
      last_response.should.be.ok
    end
  end

  it "returns 404 for inexisting user or album" do
    FakeWeb.register_uri(:get, %r(http://picasaweb.google.com/data/feed/api/.*), :body => "", :status => 404)

    get "/bad_user_id/bad_album"
    last_response.should.not.be.ok
  end
end

