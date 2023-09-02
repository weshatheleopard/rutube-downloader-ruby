class RutubeDownloader < VideoDownloader
  def self.can_download?(url)
    url =~ /rutube\.ru/i
  end

  def segment_name(n)
    "segment-#{n}-"
  end

  def segment_regexp
    /\/(?<prefix>[a-z0-9]+)\.mp4\/segment-(?<number>\d+)-/
  end
end
