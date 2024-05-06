class RamblerDownloader < VideoDownloader
  def self.can_download?(url)
    return :page if url =~ /(^.+rambler\.ru\/[^\/]+\/(\d+)-)/
    return :stream if url =~ /rambler/i
    false
  end

  def segment_name(n)
    "seg-#{n}-"
  end

  def segment_regexp
    /\/(?<prefix>[a-zA-Z0-9]+)\.mp4\/seg-(?<number>\d+)-/
  end

  # For automatic dowloading by video page URL

  AGENT_ALIAS = 'Windows IE 10' #'

  def get_track_list(url)
    uri = URI(url)
    uri.query = nil
    page = agent.get(uri)

    json_str = page.content.match(/<script>window.__PRELOADED_STATE__=(.+?)<\/script>/)[1]
    json = JSON.parse(json_str.gsub(/new Date\("[^"]+"\)/, '""'))
    entries = json.dig('commonData', 'entries', 'entities')
    video_id = entries.collect { |e| e.dig(1, 'video', 'recordId') }.delete_if(&:empty?).first

    page = agent.get('https://api.vp.rambler.ru/api/v3/records/getPlayerData', params: { id: video_id }.to_json )
    json = JSON.parse(page.content)

    res_selection_url = json.dig('result', 'playList', 'source')

    # Pick the best resolution from the list. In this particular downloader, looks like best is the first one
    m3u_data = M3UParser.new(agent.get(res_selection_url).content).parse
    max_res_playlist = m3u_data[:entries].max_by{ |entry| entry && entry["RESOLUTION"].to_i }
    max_res_playlist_url = max_res_playlist[:url]

    track_list = M3UParser.new(agent.get(max_res_playlist_url).content).extract_tracklist(max_res_playlist_url)

    { id: video_id, track_list: track_list }
  end
end
