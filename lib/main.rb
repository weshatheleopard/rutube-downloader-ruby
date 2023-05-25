Dir['lib/*_downloader.rb'].each { |fn| require(File.expand_path(fn)) }

def dl(*args)
  ObjectSpace.each_object(VideoDownloader::singleton_class) do |klass|
    if klass.can_download?(args[0]) then
      klass.new.download_video(*args)
      exit
    end
  end

  puts "#{args[0]} did not match any known downloaders"
end
