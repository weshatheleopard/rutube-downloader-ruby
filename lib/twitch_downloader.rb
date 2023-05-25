require_relative 'video_downloader'

class TwitchDownloader < VideoDownloader
  def self.can_download?(url)
    url =~ /cloudfront/i
  end

  def segment_name(n)
    "#{n}.ts"
  end

  def segment_regexp
    /\/([0-9a-z_]+)\/chunked\/(\d+).ts$/
  end
end
