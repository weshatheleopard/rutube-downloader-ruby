require 'json'

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

    res_selection_url = json['video_balancer']['m3u8']
    res_selection_list = @agent.get(res_selection_url).content

    max_res_playlist_url = res_selection_list.split("#EXT-X-").
      map{ |entry| entry.match /RESOLUTION=(?<resolution>\d+x\d+).+\n(?<url>.+)\n/m }.
      max_by{ |entry| (entry && entry[:resolution]).to_i }[:url]

    track_list = @agent.get(max_res_playlist_url).content
    matches = track_list.scan(/^(.+\.ts)$/x)

    [ video_id, matches.map { |track| URI(max_res_playlist_url).merge(track.first).to_s } ]
  end
end
