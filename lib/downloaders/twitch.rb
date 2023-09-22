class TwitchDownloader < VideoDownloader
  def self.can_download?(url)
    return :stream if url =~ /cloudfront/i
    false
  end

  def segment_name(n)
    "#{n}.ts"
  end

  def segment_regexp
    /\/(?<prefix>[0-9a-z_]+)\/chunked\/(?<number>\d+).ts$/
  end
end
