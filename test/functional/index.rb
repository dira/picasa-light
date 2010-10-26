require File.dirname(__FILE__) + '/../test_helper'

describe 'picasa-light' do

  describe 'when browsing' do
    before do
      FakeWeb.clean_registry
    end

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

    it 'does no crash if the user has no albums' do
        fake_picasa(:user, true, :empty => true)

        get "/user_id"
        last_response.should.be.ok
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
        fake_picasa(:user) # as id's are not numeric
        fake_picasa(:album)

        get "/user_id/#{url}"
        last_response.should.be.ok
      end
    end

    it "does not crash if the album is empty" do
      fake_picasa(:user) # as id's are not numeric
      fake_picasa(:album, true, :empty => true)

      get "/user_id/album_id"
      last_response.should.be.ok
    end

    it "returns 404 for wrong album" do
      fake_picasa(:user) # as the id is not numeric
      fake_picasa(:album, false)

      get "/bad_user_id/bad_album"
      last_response.should.not.be.ok
      last_response.headers["Cache-control"].should.be.nil
    end

    it "works with album name directly" do
      fake_picasa(:user)
      fake_picasa(:album, true,   :id => "5461881958625748465")
      fake_picasa(:album, false,  :id => 'innasimariuslove')

      get "/user_id/innasimariuslove" # from fixtures, lowercased
      last_response.should.be.ok
    end

    it "returns 404 for bad album name" do
      fake_picasa(:user)
      fake_picasa(:album, true,   :id => "5461881958625748465")
      fake_picasa(:album, false,  :id => 'innasimariuslove2')

      get "/user_id/innasimariuslove2" # from fixtures, lowercased
      last_response.should.not.be.ok
      last_response.status.should.be 404
    end

    it "works with numeric album name" do
      fake_picasa(:user)
      fake_picasa(:album, false,  :id => "123")
      fake_picasa(:album, true,   :id => "5532128439669121473")

      get "/user_id/123"
      last_response.should.be.ok
    end

  end

  describe 'caching' do
    before do
      set :environment, :test
      FakeWeb.clean_registry
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
