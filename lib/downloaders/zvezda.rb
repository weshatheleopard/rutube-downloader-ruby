class ZvezdaDownloader < VideoDownloader
  def self.can_download?(url)
    url =~ /tvzvezda\.ru/i
  end

  def download_video(url, combine: false)
    segments = []

    @agent = Mechanize.new { |agent|
      agent.user_agent_alias = 'Windows IE 10' #'
      agent.read_timeout = 5
    }

    prefix, urls = get_track_list(url)

    print "Downloading... \033[s"

    urls.each { |url|
      print "\033[u#{url}"
      segments << get_segment(url, prefix)
    }
    puts "\033[udone."

    if combine then
      upload combine(segments, prefix), prefix, url
    else
      upload segments, prefix, url
    end

    true
  end

  def get_segment(url, prefix)
    begin
      newfile = @agent.get(url)
    rescue Net::ReadTimeout
      retry
    rescue Mechanize::ResponseCodeError => e
      case e.response_code
      when '403', '404' then return false
      else retry
      end
    end

    full_path = in_tmp_dir(newfile.filename)
    newfile.save_as(full_path)
    return full_path
  end

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
