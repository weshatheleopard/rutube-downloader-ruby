class FoxnewsDownloader < VideoDownloader
  def self.can_download?(url)
    return :stream if url =~ /foxnews/i
    false
  end

  def segment_name(n)
    "segment#{n}\.ts"
  end

  def segment_regexp
    /\/clear\/(?<prefix>\d+)\/.+\/segment(?<number>\d+)\.ts/
  end
end
