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

    res_selection_url = "#{base_url}/index.m3u8"
    res_selection_list = @agent.get(res_selection_url).content

    max_res_playlist = res_selection_list.split("#EXT-X-").
      map{ |entry| entry.match /RESOLUTION=(?<resolution>\d+x\d+).+\n(?<url>.+)\n/m }.
      max_by{ |entry| (entry && entry[:resolution]).to_i }[:url]

    track_list_url = "#{base_url}/#{max_res_playlist}"
    track_list = @agent.get(track_list_url).content

    matches = track_list.scan(/^(.+.ts)$/)

    [ base_url[-20...-4], matches.map { |track| "#{base_url}/#{File.dirname(max_res_playlist)}/#{track[0]}" } ]
  end
end
