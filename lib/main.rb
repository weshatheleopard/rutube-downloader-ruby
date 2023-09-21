require_relative 'video_downloader.rb'

Dir['lib/downloaders/*.rb'].each { |fn| require(File.expand_path(fn)) }

def dl(*args)
  downloder_class = ObjectSpace.each_object(VideoDownloader::singleton_class).find do |klass|
    klass.can_download?(args[0])
  end

  downloder_class&.new&.download_video(*args) || puts("#{args[0]} did not match any known downloaders")
end

def dl2(*args)
  downloder_class = ObjectSpace.each_object(VideoDownloader::singleton_class).find do |klass|
    klass.can_download?(args[0])
  end

  downloder_class&.new&.download_video_by_url(*args) || puts("#{args[0]} did not match any known downloaders")
end
