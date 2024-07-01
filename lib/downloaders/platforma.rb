class PlatformaDownloader < VideoDownloader
  def self.can_download?(url)
    return :page if url =~ %r{(^.+plvideo\.ru/watch\?v=([a-z0-9]+))}i
    false
  end

  AGENT_ALIAS = 'Windows IE 10' #'

  def get_track_list(url)
    md = url.match(%r{(^.+plvideo\.ru/watch\?v=(?<video_id>[a-z0-9]+))}i)
    video_id = md[:video_id]

    video_page = agent.get("https://api.g1.plvideo.ru/v1/videos/#{video_id}?Aud=16")
    json = JSON.parse(video_page.content)

    created_at = json.dig('item', 'createdAt')
    title = json.dig('item', 'title')

    max_res_playlist = json.dig('item', 'profiles').max_by { |k, v| k.to_i }

    height = max_res_playlist.first.to_i
    width = (max_res_playlist.dig(1, "aspectRatio").to_f * height).round

    max_res_playlist_url = max_res_playlist.last['hls']
    track_list = M3UParser.new(agent.get(max_res_playlist_url).content).extract_tracklist(max_res_playlist_url)

    { id: video_id, track_list: track_list, title: title, created: created_at,
      resolution: "#{width}x#{height}" }
  end
end
