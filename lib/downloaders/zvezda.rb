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
    page.content =~ /id="media_video">([^<]+)</x
    base_url = $1

    res_selection_url = "#{base_url}/index.m3u8"
    res_selection_list = @agent.get(res_selection_url).content

    # Pick the best resolution from the list. In this particular downloader, it is always the same, no need to search
    selection = 'tracks-v1a1'

    track_list_url = "#{base_url}/#{selection}/mono.m3u8"
    track_list = @agent.get(track_list_url).content

    matches = track_list.scan(/^(.+.ts)$/x)

    [ base_url[-10..-1], matches.map { |track| "#{base_url}/#{selection}/#{track[0]}" } ]
  end
end
