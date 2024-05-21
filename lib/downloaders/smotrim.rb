require 'json'
require_relative '../m3u_parser'

class SmotrimDownloader < VideoDownloader
  def self.can_download?(url)
    return :page if url =~ /smotrim\.ru\/video\/\d+/i
    false
  end

  # For automatic dowloading by video page URL

  AGENT_ALIAS = 'Windows Firefox' #'

  def get_track_list(url)
    md = url.match(/video\/(?<video_id>\d+)/i)
    video_id = md[:video_id]

    page = agent.get("https://player.smotrim.ru/iframe/datavideo/id/#{video_id}/sid/smotrim", [], url)
    json = JSON.parse(page.content)

    created_at = json['time'] # Looks like creation time but not sure
    data = json.dig('data', 'playlist', 'medialist', 0)
    title = data['title']
    m3u_data_page = agent.get(data.dig('sources', 'm3u8', 'auto'))
    m3u_data = M3UParser.new(m3u_data_page.content).parse
    max_res_entry = m3u_data[:entries].max_by{ |entry| entry["BANDWIDTH"].to_i }

    max_res_playlist_url = m3u_data_page.uri
    max_res_playlist_url.path = max_res_playlist_url.path.gsub(/([^\/]+?)$/, max_res_entry[:filename])
    max_res_playlist_url.query = nil

    track_list = M3UParser.new(agent.get(max_res_playlist_url).content).extract_tracklist(max_res_playlist_url)

    { id: video_id, track_list: track_list, title: title, created: created_at }
  end
end
