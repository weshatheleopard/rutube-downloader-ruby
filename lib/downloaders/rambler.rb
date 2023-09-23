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
    page = @agent.get(uri)

    json_str = page.content.match(/<script>window.__PRELOADED_STATE__=(.+?)<\/script>/)[1]
    json = JSON.parse(json_str.gsub(/new Date\("[^"]+"\)/, '""'))
    entries = json.dig('commonData','entries','entities')
    video_id = entries.collect { |e| e.dig(1, 'video', 'recordId') }.delete_if(&:empty?).first

    page = @agent.get('https://api.vp.rambler.ru/api/v3/records/getPlayerData', params: { id: video_id }.to_json )
    json = JSON.parse(page.content)

    res_selection_url = json['result']['playList']['source']
    res_selection_list = @agent.get(res_selection_url).content

    md = res_selection_list.scan(/(\#EXT-X-STREAM-INF:(?<inf>[^\n]+)\n(?<url>[^\n]+))/ix)

    # Pick the best resolution from the list. In this particular downloader, looks like best is the first one
    track_list_url = md[0][1]
    track_list = @agent.get(track_list_url).content

    matches = track_list.scan(/(\#EXTINF:(?<inf>[^\n]+)\n(?<url>[^\n]+))/ix)

    [ video_id, matches.map { |track| URI(track_list_url).merge(track.last).to_s } ]
  end
end
