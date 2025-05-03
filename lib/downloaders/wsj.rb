class WsjhDownloader < VideoDownloader
  def self.can_download?(url)
    return :stream if url =~ %r{^https://m\.wsj\.net/video/.+/.+\.ts$}i
    false
  end

  def segment_name(n)
    '%05d.ts' % n
  end

  def segment_regexp
    %r{.+/(?<prefix>\d+)/.+-(?<number>\d+).ts$}
  end

  AGENT_ALIAS = 'Windows Firefox' #'
end
