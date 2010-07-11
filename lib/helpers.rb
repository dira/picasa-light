module Helpers
  include Rack::Utils
  alias_method :h, :escape_html

  def album_title(album)
    title = h album[:summary]
    title += "@#{h album[:location]}" unless album[:location].empty?
  end

  def album_path(username, album)
    "#{user_url(username)}/#{album[:id]}/#{album[:uri]}"
  end

  def album_url(username, album)
    "http://#{request.host_with_port}#{album_path(username, album)}"
  end

  def embed_code(username, album, photo, dimension = 400)
    size = PicasaAPI::photo_size(photo, dimension)
    embed = %(<a href="#{album_url(params[:username], @album)}##{photo[:id]}">
        <img src="#{PicasaAPI::url_for_dimension(photo[:src], dimension)}" width="#{size[:width]}" height="#{size[:height]}"/>
      </a>)
    embed += %(<p>#{auto_link_urls(photo[:description])}</p>) unless photo[:description].empty?
    embed.gsub(/'/, "\\\\'").gsub(/"/, '\\\\"')
  end

  def user_url(username)
    "/#{URI.escape(username)}"
  end

  # Thank you Rails!
  AUTO_LINK_RE = %r{
      ( https?:// | www\. )
      [^\s<]+
    }x unless const_defined?(:AUTO_LINK_RE)

  BRACKETS = { ']' => '[', ')' => '(', '}' => '{' }

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
