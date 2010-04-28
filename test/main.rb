require File.dirname(__FILE__) + '/../index'
require 'test/spec'
require 'rack/test'
require 'fakeweb'

set :environment, :test

describe 'The Picasa Minimzer App' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def fake_picasa(kind)
    picasa_api = %r(http://picasaweb.google.com/data/feed/api/.*)
    if (kind.to_s == "error")
      FakeWeb.register_uri(:get, picasa_api, :body => "", :status => 404)
    else
      content = File.read(File.dirname(__FILE__) + "/fixtures/#{kind}.json")
      FakeWeb.register_uri(:get, picasa_api, :body => content)
    end
  end

  it "does not crash on main page" do
    get '/'
    last_response.should.be.ok
  end

  ["user_id", "user_id/"].each do |url|
    it "does not crash on existing user #{url}" do
      fake_picasa(:user)

      get "/#{url}"
      last_response.should.be.ok
    end
  end

  it "returns 404 for wrong user id" do
    fake_picasa(:error)

    get "/bad_user_id"
    last_response.should.not.be.ok
    last_response.headers["Cache-control"].should.be.nil
  end


  ["album_id", "album_id/", "album_id/ignored_album_name", "album_id/ignored_album_name/"].each do |url|
    it "does not crash on existing album #{url}" do
      fake_picasa(:album)

      get "/user_id/#{url}"
      last_response.should.be.ok
    end
  end

  it "returns 404 for wrong user or album" do
    fake_picasa(:error)

    get "/bad_user_id/bad_album"
    last_response.should.not.be.ok
    last_response.headers["Cache-control"].should.be.nil
  end

  it "caches user's albums for 1 hour" do
    fake_picasa(:user)

    get "/user_id"
    last_response.headers["Cache-control"].should.equal "public, max-age=3600"
  end

  it "caches album's photos for 1 hour" do
    fake_picasa(:album)

    get "/user_id/album_id"
    last_response.headers["Cache-control"].should.equal "public, max-age=3600"
  end


  ["/", "/stylesheet.css"].each do |url|
    it "does not cache #{url}" do
      get url
      last_response.headers["Cache-control"].should.be.nil
    end
  end
end
