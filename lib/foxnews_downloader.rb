require_relative 'video_downloader'

class FoxnewsDownloader < VideoDownloader
  def segment_name(n)
    "segment#{n}\.ts"
  end

  def segment_regexp
    /\/clear\/(\d+)\/.+\/segment(\d+)\.ts/
  end

  def max_num
    1000
  end
end
