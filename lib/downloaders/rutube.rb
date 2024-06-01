require 'json'
require_relative '../m3u_parser'

class RutubeDownloader < VideoDownloader
  def self.can_download?(url)
    return :stream if url =~ %r{rutube\.ru/.+\.ts}i
    return :page if url =~ %r{rutube\.ru/video/}i
    false
  end

  # For downloading by video URL

  def segment_name(n)
    "segment-#{n}-"
  end

  def segment_regexp
    %r{/(?<prefix>[a-z0-9]+)\.mp4/segment-(?<number>\d+)-}
  end

  # For automatic dowloading by video page URL

  AGENT_ALIAS = 'Windows Firefox' #'

  def get_track_list(url)
    md = url.match(%r{video/(?<video_id>[0-9a-f]+)}i)
    video_id = md[:video_id]

    created_at =
      begin # Attempt to retrieve creation date
        video_page = agent.get(url)
        metadata = JSON.parse(video_page.content.match(/reduxState\s*=\s*(?<json>{(.+)});/)[:json])
        metadata['video']['entities'][video_id]['video']['created_ts']
      rescue
        nil
      end

    page = agent.get("https://rutube.ru/api/play/options/#{video_id}", [], url)
    json = JSON.parse(page.content)
    title = json['title']

    m3u_data = M3UParser.new(agent.get(json.dig('video_balancer', 'm3u8')).content).parse
    mex_res_entry = m3u_data[:entries].max_by{ |entry| entry['RESOLUTION'].to_i }
    max_res_playlist_url = mex_res_entry[:url]

    track_list = M3UParser.new(agent.get(max_res_playlist_url).content).extract_tracklist(max_res_playlist_url)

    { id: video_id, track_list: track_list, title: title, created: created_at, resolution: mex_res_entry['RESOLUTION'] }
  end
end
