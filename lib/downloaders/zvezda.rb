class ZvezdaDownloader < VideoDownloader
  def self.can_download?(url)
    return :stream if url =~ /cdn\.tvzvezda\.ru\/storage.+\.ts/i
    return :page if url =~ /tvzvezda\.ru\/(.+)\.html?/i
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
    page = agent.get(url)
    md = page.content.match(/(<script[^>]+NEXT_DATA[^>]+>)(?<json>.+?)<\/script>/i)
    if md.nil? then # Older player
      md = page.content.match(/<script>self.__next_f.push\((?<json>\[1,"12:(.+?)\\n"\])\)<\/script>/)
      js1 = JSON.parse(md[:json])
      hsh = JSON::parse(js1.last[3...-1]).dig(0, 0, 3, 'children', 0, 0, 3, 'data', 'items', 0)
      m3u_url = hsh.dig('media', 'video', 'url')
      title = hsh['title']
      created = hsh['dateCreate']
      video_id = m3u_url.match(/\/(?<video_id>[0-9A-Z]+)\.mp4/i)[:video_id]
    else # New player
      json = JSON.parse(md[:json])
      video_id = json.dig('props', 'pageProps', 'news', 'key' )[0...-5]
      m3u_url = json.dig('props', 'pageProps', 'news', 'media', 'video')
      title = json.dig('props', 'pageProps', 'news', 'title' )
      created = json.dig('props', 'pageProps', 'news', 'dateCreate' )
    end

    m3u_data_page = agent.get(m3u_url)
    m3u_data = M3UParser.new(m3u_data_page.content).parse

    max_res_entry = m3u_data[:entries].max_by{ |entry| entry && entry['RESOLUTION'].to_i }

    # URI.path doesn't accept HTML parameters, so strip them off for now, looks like it works fine without.
    max_res_playlist_name = max_res_entry[:filename].split('?').first

    max_res_playlist_url = m3u_data_page.uri
    max_res_playlist_url.path = max_res_playlist_url.path.gsub(/([^\/]+?)$/, max_res_playlist_name)

    track_list = M3UParser.new(agent.get(max_res_playlist_url).content).extract_tracklist(max_res_playlist_url)

    { id: video_id, track_list: track_list, title: title, created: created, resolution: max_res_entry['RESOLUTION'] }
  end
end
