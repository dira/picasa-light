class PicasaAPI
  API_BASE = "http://picasaweb.google.com/data/feed/api"

  def  self.api_url_user(username)
    global_fields = "author,link[@rel='alternate']"
    entry_fields = "title,summary,gphoto:id,gphoto:name,gphoto:location,media:group(media:thumbnail)"
    URI.parse("#{API_BASE}/user/#{URI.escape(username)}?alt=json&fields=#{global_fields},entry(#{entry_fields})")
  end

  def self.api_url_album(username, album)
    global_fields = "title,author,link[@rel='alternate']"
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

  def self.photo_with_size(url, size)
    url = url.gsub(/\/s\d{1,3}(-.)?/, '') # remove the size specifier, if present
    url.gsub(/(\/[^\/]+)$/, '/s' + size.to_s + '\1') # add the new one
  end

  def self.user(username)
    response = Net::HTTP.get_response(PicasaAPI::api_url_user(username))
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

  def self.album(username, album)
    response = Net::HTTP.get_response(PicasaAPI::api_url_album(username, album))
    throw "Inexistent user or album" unless response.is_a? Net::HTTPOK

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
    { :title => feed["title"]["$t"], :author => feed["author"][0]["name"]["$t"], :link => feed["link"][0]["href"], :photos => photos }
  end
end
