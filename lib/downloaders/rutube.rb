require 'json'
require_relative '../m3u_parser.rb'

class RutubeDownloader < VideoDownloader
  def self.can_download?(url)
    return :stream if url =~ /rutube\.ru\/.+\.ts/i
    return :page if url =~ /rutube\.ru\/video\//i
    false
  end

  # For downloading by video URL

  def segment_name(n)
    "segment-#{n}-"
  end

  def segment_regexp
    /\/(?<prefix>[a-z0-9]+)\.mp4\/segment-(?<number>\d+)-/
  end

  # For automatic dowloading by video page URL

  AGENT_ALIAS = 'Windows Firefox' #'

  def get_track_list(url)
    md = url.match(/video\/(?<video_id>[0-9a-f]+)/i)
    video_id = md[:video_id]

    page = @agent.get "https://rutube.ru/api/play/options/#{video_id}", [], url
    json = JSON.parse(page.content)

    m3u_data = M3UParser.new(@agent.get(json['video_balancer']['m3u8']).content).parse
    max_res_playlist_url = m3u_data[:entries].max_by{ |entry| entry['RESOLUTION'].to_i }[:url]

    track_list = M3UParser.new(@agent.get(max_res_playlist_url).content).extract_tracklist(max_res_playlist_url)

    [ video_id, track_list ]
  end
end
