require 'video_downloader'

class ZvezdaDownloader < VideoDownloader
  def segment_name(n)
    "segment#{n}"
  end

  def segment_regexp
    /\/([a-z0-9]+)\.mp4\/.+\/segment(\d+)/
  end

  def max_num
    1000
  end
end
