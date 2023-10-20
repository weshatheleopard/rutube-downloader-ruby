class ZvezdaDownloader < VideoDownloader
  def self.can_download?(url)
    return :stream if url =~ /cdn\.tvzvezda\.ru\/storage.+\.ts/i
    return :page if url =~ /tvzvezda\.ru\/(.+)\.html/i
    false
  end

  # For downloading by video URL

  def segment_name(n)
    "segment#{n}"
  end

  def segment_regexp
    /\/(?<prefix>[A-Za-z0-9_]+)\.mp4\/.+\/segment(?<number>\d+)/
  end

  # For automatic dowloading by video page URL

  AGENT_ALIAS = 'Windows IE 10' #'

  def get_track_list(url)
    page = @agent.get(url)
    md = page.content.match(/flashvars\s=\s(?<json>\{[^}]+})/i)
    json = JSON.parse(md[:json])
    base_url = json['file']

    m3u_data = M3UParser.new(@agent.get("#{base_url}/index.m3u8").content).parse
    max_res_playlist = m3u_data[:entries].max_by{ |entry| entry && entry["RESOLUTION"].to_i }[:filename]

    m3u_data = M3UParser.new(@agent.get("#{base_url}/#{max_res_playlist}").content).parse

    [ base_url[-20...-4], m3u_data[:entries].map { |entry| "#{base_url}/#{File.dirname(max_res_playlist)}/#{entry[:filename]}" } ]
  end
end
