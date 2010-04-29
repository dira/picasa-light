require 'rubygems'
require 'sinatra'
require 'json'
require 'net/http'
require 'haml'
require 'sass'

before { mock_picasa if development? }

get '/' do
  haml :index
end

get '/stylesheet.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :stylesheet
end

get '/:username/?' do
  @user = user(params[:username]) rescue error(404, "Wrong user name, must be the same as in Picasa")
  @page_title = @user[:name]

  add_http_cache
  haml :user
end

def user_url(username)
  "/#{URI.escape(username)}"
end

['/:username/:album_id/*/?', '/:username/:album_id/?'].each do |route|
  get route do
    @album = album(params[:username], params[:album_id]) rescue error(404, "Wrong user name or album, how did you get here?")
    @page_title = @album[:title]

    add_http_cache
    haml :album
  end
end

def add_http_cache
  cache_control :public, :max_age => 60*60
end


def api_url_user(username)
  URI.parse("http://picasaweb.google.com/data/feed/api/user/#{URI.escape(username)}?alt=json&fields=author,link[@rel='alternate'],entry(title,summary,gphoto:id,gphoto:name,gphoto:location,media:group(media:thumbnail))")
end

def user(username)
  response = Net::HTTP.get_response(api_url_user(username))
  throw "Inexistent user" unless response.is_a? Net::HTTPOK

  feed = JSON.parse(response.body)['feed']
  albums = feed['entry'].map do |album|
    { :title => album["title"]["$t"],
      :summary => album["summary"]["$t"],
      :id => album["gphoto$id"]["$t"],
      :uri => album["gphoto$name"]["$t"],
      :location => album["gphoto$location"]["$t"],
      :thumbnail => album["media$group"]["media$thumbnail"][0]["url"]
    }
  end
  { :name => feed["author"][0]["name"]["$t"], :link => feed["link"][0]["href"], :albums => albums }
end


def api_url_album(username, album)
  URI.parse("http://picasaweb.google.com/data/feed/api/user/#{URI.escape(username)}/albumid/#{URI.escape(album)}?alt=json&fields=title,author,link[@rel='alternate'],entry(content,media:group(media:description),gphoto:id,gphoto:timestamp)")
end

def photo_with_size(url, size)
  url = url.gsub(/\/s\d{1,3}(-.)?/, '') # remove the size specifier, if present
  url.gsub(/(\/[^\/]+)$/, '/s' + size.to_s + '\1') # add the new one
end

def album(username, album)
  response = Net::HTTP.get_response(api_url_album(username, album))
  throw "Inexistent user or album" unless response.is_a? Net::HTTPOK

  feed = JSON.parse(response.body)['feed']
  photos = feed['entry'].map do |photo|
    { :src => photo["content"]["src"],
      :id => photo["gphoto$id"]["$t"],
      :description => photo["media$group"]["media$description"]["$t"],
      :time => Time.at(photo["gphoto$timestamp"]["$t"].to_i / 1000)
    }
  end
  { :title => feed["title"]["$t"], :author => feed["author"][0]["name"]["$t"], :link => feed["link"][0]["href"], :photos => photos }
end


def mock_picasa
  require 'fakeweb'
  user_content = File.read(File.dirname(__FILE__) + "/test/fixtures/user.json")
  FakeWeb.register_uri(:get, %r(http://picasaweb.google.com/data/feed/api/user/[^/]*$), :body => user_content)

  album_content = File.read(File.dirname(__FILE__) + "/test/fixtures/album.json")
  FakeWeb.register_uri(:get, %r(http://picasaweb.google.com/data/feed/api/user/[^/]*/albumid/.*), :body => album_content)
end


helpers do
  include Rack::Utils
  alias_method :h, :escape_html

  def album_title(album)
    title = h album[:summary]
    title += "@#{h album[:location]}" unless album[:location].empty?
  end

  AUTO_LINK_RE = %r{
      ( https?:// | www\. )
      [^\s<]+
    }x unless const_defined?(:AUTO_LINK_RE)

  BRACKETS = { ']' => '[', ')' => '(', '}' => '{' }

  # Thank you rails!
  # Turns all urls into clickable links.  If a block is given, each url
  # is yielded and the result is used as the link text.
  def auto_link_urls(text, html_options = {})
    link_attributes = html_options
    text.gsub(AUTO_LINK_RE) do
      href = $&
      punctuation = ''
      left, right = $`, $'
      # detect already linked URLs and URLs in the middle of a tag
      if left =~ /<[^>]+$/ && right =~ /^[^>]*>/
        # do not change string; URL is alreay linked
        href
      else
        # don't include trailing punctuation character as part of the URL
        if href.sub!(/[^\w\/-]$/, '') and punctuation = $& and opening = BRACKETS[punctuation]
          if href.scan(opening).size > href.scan(punctuation).size
            href << punctuation
            punctuation = ''
          end
        end

        link_text = block_given?? yield(href) : href
        href = 'http://' + href unless href.index('http') == 0

        "<a href=\"#{href}\">#{h(link_text)}</a>" + punctuation
      end
    end
  end
end
