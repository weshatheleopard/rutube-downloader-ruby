class FoxnewsDownloader < VideoDownloader
  def self.can_download?(url)
    url =~ /foxnews/i
  end

  def segment_name(n)
    "segment#{n}\.ts"
  end

  def segment_regexp
    /\/clear\/(?<prefix>\d+)\/.+\/segment(?<number>\d+)\.ts/
  end
end
