require_relative 'video_downloader'

Dir['lib/downloaders/*.rb'].each { |fn| require(File.expand_path(fn)) }

def dl(*args)
  download_type = nil

  downloder_class = ObjectSpace.each_object(VideoDownloader::singleton_class).find do |klass|
    download_type = klass.can_download?(args[0])
  end

  puts("#{args[0]} did not match any known downloaders") unless downloder_class

  case download_type
  when :page then
    downloder_class&.new&.download_video_by_url(*args)
  else # stream
    downloder_class&.new&.download_video(*args)
  end

end
