class Tv1Downloader < VideoDownloader
  def self.can_download?(url)
    return :page if url =~ %r{1tv\.ru/(.+)}i
    false
  end

  # For automatic dowloading by video page URL

  AGENT_ALIAS = 'Windows IE 10' #'

  def get_track_list(url)
    page = agent.get(url)
    md = page.content.match(/data-playlist-url="(?<path>[^"]+)"/)
    json = JSON.parse(agent.get(md[:path]).content)
    hsh = json[0]
    video_id = hsh['id']

    # Option to obtain the URL of the complete video
    # file_hash = hsh['sources'].find { |sub_hsh| sub_hsh["type"] == "video/mp4" }
    # full_video_url = file_hash['src']

    segment_list_url = hsh['sources'].find { |sub_hsh| sub_hsh['type'] == 'application/x-mpegURL' }['src']

    segment_list_page = agent.get(segment_list_url)
    m3u_data = M3UParser.new(segment_list_page.content).parse
    max_res_playlist_name = m3u_data[:entries].max_by{ |entry| entry && entry['RESOLUTION'].to_i }[:filename]

    max_res_playlist_url = segment_list_page.uri
    max_res_playlist_url.path = max_res_playlist_url.path.gsub(%r{([^/]+?)$}, max_res_playlist_name)

    track_list = M3UParser.new(agent.get(max_res_playlist_url).content).extract_tracklist(max_res_playlist_url)

    { id: video_id.to_s, track_list: track_list }
  end
end
