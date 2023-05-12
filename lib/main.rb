Dir['lib/*_downloader.rb'].each { |fn| require(File.expand_path(fn)) }

def dl(*args)
  n =
    case args[0]
    when /rutube\.ru/   then RutubeDownloader
    when /tvzvezda\.ru/ then ZvezdaDownloader
    when /cloudfront/   then TwitchDownloader
    when /foxnews/      then FoxnewsDownloader
    end

  n.new.download_video(*args)
end
