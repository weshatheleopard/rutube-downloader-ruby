class DzenDownloader < VideoDownloader
  def self.can_download?(url)
    return :page if url =~ /(^.+dzen\.ru\/video\/watch\/([a-f0-9]+))/
    false
  end

  AGENT_ALIAS = 'Windows IE 10' #'

  def get_track_list(url)
    agent.cookie_jar.add(Mechanize::Cookie.new('zen_sso_checked', '1', :domain => '.dzen.ru', :path => '/'))
    agent.cookie_jar.add(Mechanize::Cookie.new('zen_vk_sso_checked', '1', :domain => '.dzen.ru', :path => '/'))

    page = agent.get(url)
    match_data = page.content.match(/\(\((?<json>{"data":{"MICRO_APP_SSR_DATA"(.+))\)\)/)
    json = JSON::parse match_data['json']

    data1 = json.dig('data', 'MICRO_APP_SSR_DATA', 'settings', 'exportData', 'video')

    video_id = data1['publicationObjectId']
    created_at = Time.at(data1['publicationDate'].to_i).to_date.strftime('%F')

    data = data1.dig('rawStreams', 'SingleStream', 0)
 
    title = data['Title']

    data2 = data.dig('StreamInfo').find { |h| h['StreamType'] == 'ST_HLS' }
    res_selection_url = data2['OutputStream']

    m3u_data = M3UParser.new(agent.get(res_selection_url).content).parse

    max_res_entry = m3u_data[:entries].max_by{ |entry| entry && entry['RESOLUTION'].to_i }
    # URI.path doesn't accept HTML parameters, so strip them off for now, looks like it works fine without.
    max_res_playlist_name = max_res_entry[:filename].split('?').first

    max_res_playlist_url = URI(res_selection_url)
    max_res_playlist_url.path = max_res_playlist_url.path.gsub(/([^\/]+?)$/, max_res_playlist_name)

    track_list = M3UParser.new(agent.get(max_res_playlist_url).content).extract_tracklist(max_res_playlist_url)
    track_list.map! { |itm| itm.split('?').first }

    { id: video_id, track_list: track_list, title: title, created: created_at }
  end
end
