require_relative 'video_downloader'

class ZvezdaDownloader < VideoDownloader
  def self.can_download?(url)
    url =~ /tvzvezda\.ru/i
  end

  def segment_name(n)
    "segment#{n}"
  end

  def segment_regexp
    /\/([A-Za-z0-9_]+)\.mp4\/.+\/segment(\d+)/
  end
end
