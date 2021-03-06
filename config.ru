require './index.rb'

if development?
  require 'sham_rack'
  ShamRack.at("picasaweb.google.com").sinatra do
    get %r(/data/feed/api/user/[^/]*$) do
      File.read(File.dirname(__FILE__) + "/test/fixtures/user.json")
    end
    get %r(/data/feed/api/user/[^/]*/albumid/.*) do
      File.read(File.dirname(__FILE__) + "/test/fixtures/album.json")
    end
  end
end

class NilClass
  def empty?
    true
  end
end

unless development?
  # logging
  FileUtils.mkdir_p('./log')
  log = File.new("./log/sinatra.log", "a+")
  STDOUT.reopen(log)
  STDERR.reopen(log)
end

run LightPicasa
