require File.dirname(__FILE__) + '/../index'
require 'test/spec'
require 'rack/test'
require 'fakeweb'

set :environment, :test

describe 'The Light Picasa App' do
  include Rack::Test::Methods

  def app
    LightPicasa
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

describe 'Photo manipulation' do
  [
    [[1000, 500, 100], [100, 50]],
    [[500, 1000, 100], [50, 100]],
    [[50, 100, 1000],  [50, 100]],
    [[150, 100, 1000], [150, 100]]
  ].each do |photo, result|
    it "computes the size for a #{photo[0]}x#{photo[1]} photo, max #{photo[2]} as #{result[0]}x#{result[1]}" do
      PicasaAPI::photo_size({ :width => photo[0], :height => photo[1]}, photo[2]).should.equal ({ :width => result[0], :height => result[1]})
    end
  end
end
