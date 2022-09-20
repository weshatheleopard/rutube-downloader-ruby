require 'video_downloader'

class ZvezdaDownloader < VideoDownloader
  def segment_name(n)
    "segment#{n}"
  end

  def segment_regexp
    /\/([a-z0-9]+)\.mp4\/.+\/segment(\d+)/
  end
end

def dlz(*args)
  n = ZvezdaDownloader.new
  n.download_video(*args)
end

