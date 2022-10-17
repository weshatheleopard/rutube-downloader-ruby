require 'video_downloader'

class TwitchDownloader < VideoDownloader
  def segment_name(n)
    "#{n}.ts"
  end

  def segment_regexp
    /\/([0-9a-z_]+)\/chunked\/(\d+).ts$/
  end

  def max_num
    5000
  end
end

#https://d1ymi26ma8va5x.cloudfront.net/713e582a913fe4e7f0b8_starcitizen_46154472668_1665239111/chunked/2092.ts
