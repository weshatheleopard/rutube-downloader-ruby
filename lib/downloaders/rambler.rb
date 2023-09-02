class RamblerDownloader < VideoDownloader
  def self.can_download?(url)
    url =~ /rambler/i
  end

  def segment_name(n)
    "seg-#{n}-"
  end

  def segment_regexp
    /\/(?<prefix>[a-zA-Z0-9]+)\.mp4\/seg-(?<number>\d+)-/
  end
end
