class PicasaAPI
  API_BASE = "http://picasaweb.google.com/data/feed/api"

  def  self.api_url_user(username)
    global_fields = "author,link[@rel='alternate']"
    entry_fields = "title,summary,gphoto:id,gphoto:name,gphoto:location,media:group(media:thumbnail)"
    URI.parse("#{API_BASE}/user/#{URI.escape(username)}?alt=json&fields=#{global_fields},entry(#{entry_fields})")
  end

  def self.api_url_album(username, album)
    global_fields = "gphoto:id,title,gphoto:name,author,link[@rel='alternate']"
    entry_fields = "content,media:group(media:description),gphoto:id,gphoto:timestamp,title,gphoto:width,gphoto:height"
    URI.parse("#{API_BASE}/user/#{URI.escape(username)}/albumid/#{URI.escape(album)}?alt=json&fields=#{global_fields},entry(#{entry_fields})")
  end

  def self.photo_size(photo, max)
    width, height = photo[:width].to_i, photo[:height].to_i
    return { :width => width, :height => height} if [width, height].max < max

    if width > height
      { :width => max, :height => (height * max.to_f / width).round }
    else
      { :width => (width * max.to_f  / height).round, :height => max }
    end
  end

  def self.url_for_dimension(url, dimension)
    url = url.gsub(/\/s\d{1,3}(-.)?/, '') # remove the dimension specifier, if present
    url.gsub(/(\/[^\/]+)$/, '/s' + dimension.to_s + '\1') # add the new one
  end

  def self.user(username)
    response = Net::HTTP.get_response(PicasaAPI::api_url_user(username))
    raise LightPicasaError unless response.is_a? Net::HTTPOK

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

  def self.album(username, album)
    album_param = album
    if !album.numeric?  # must be the album's name (or a mistake)
      album = album_by_name(username, album)
    end

    response = Net::HTTP.get_response(PicasaAPI::api_url_album(username, album))

    if !response.is_a?(Net::HTTPOK) && album == album_param
      # maybe the album name is numeric
      album = album_by_name(username, album)
      response = Net::HTTP.get_response(PicasaAPI::api_url_album(username, album))
    end

    raise LightPicasaError unless response.is_a? Net::HTTPOK

    feed = JSON.parse(response.body)['feed']
    photos = feed['entry'].map do |photo|
      { :src => photo["content"]["src"],
        :id => photo["gphoto$id"]["$t"],
        :title => photo["title"]["$t"],
        :description => photo["media$group"]["media$description"]["$t"],
        :width => photo["gphoto$width"]["$t"],
        :height => photo["gphoto$height"]["$t"],
        :time => Time.at(photo["gphoto$timestamp"]["$t"].to_i / 1000)
      }
    end
    { :id => feed["gphoto$id"]["$t"],
      :uri => feed["gphoto$name"]["$t"],
      :title => feed["title"]["$t"],
      :author => feed["author"][0]["name"]["$t"],
      :link => feed["link"][0]["href"],
      :photos => photos
    }
  end

  protected
    def self.album_by_name(username, album_name)
      albums = user(username)[:albums] rescue []
      if found = (albums.find{|a| a[:uri].casecmp(album_name) == 0})
        return found[:id].to_s
      end
      album_name
    end
end

class String
  def numeric?
    match /^[0-9]+$/
  end
end
