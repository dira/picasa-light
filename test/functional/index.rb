require File.dirname(__FILE__) + '/../test_helper'

describe 'picasa-light' do

  describe 'when browsing' do
    it "does not crash on the home page" do
      get '/'
      last_response.should.be.ok
    end

    ["user_id", "user_id/"].each do |url|
      it "does not crash on existing user page - #{url}" do
        fake_picasa(:user)

        get "/#{url}"
        last_response.should.be.ok
      end
    end

    it "returns 404 for wrong user id" do
      fake_picasa(:user, false)

      get "/bad_user_id"
      last_response.should.not.be.ok
      last_response.status.should.be 404
      last_response.headers["Cache-control"].should.be.nil
    end


    ["album_id", "album_id/", "album_id/ignored_album_name", "album_id/ignored_album_name/"].each do |url|
      it "does not crash on existing album page - #{url}" do
        fake_picasa(:album)

        get "/user_id/#{url}"
        last_response.should.be.ok
      end
    end

    it "returns 404 for wrong album" do
      fake_picasa(:album, false)

      get "/bad_user_id/bad_album"
      last_response.should.not.be.ok
      last_response.headers["Cache-control"].should.be.nil
    end
  end

  describe 'caching' do
    before do
      set :environment, :test
    end

    it "caches user's albums for 1 hour" do
      fake_picasa(:user)

      set :environment, :production
      get "/user_id"
      last_response.headers["Cache-Control"].should.equal "public, max-age=3600"
    end

    it "caches album's photos for 1 hour" do
      fake_picasa(:user)
      fake_picasa(:album)

      set :environment, :production
      get "/user_id/album_id"
      last_response.headers["Cache-Control"].should.equal "public, max-age=3600"
    end


    ["/", "/stylesheet.css"].each do |url|
      it "does not cache #{url}" do
        set :environment, :production
        get url
        last_response.headers["Cache-Control"].should.be.nil
      end
    end
  end
end
