def dl(*args)
  n =
    case args[0]
    when /rutube\.ru/ then
      RutubeDownloader
    when /tvzvezda\.ru/ then
      ZvezdaDownloader
    end

  n.new.download_video(*args)
end
