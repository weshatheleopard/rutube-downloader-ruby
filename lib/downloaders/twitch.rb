class TwitchDownloader < VideoDownloader
  def self.can_download?(url)
    return :stream if url =~ /cloudfront/i
    return :page if url =~ %r{\.twitch\.tv/videos}i
    false
  end

  def segment_name(n)
    "#{n}.ts"
  end

  def segment_regexp
    %r{/(?<prefix>[0-9a-z_]+)/chunked/(?<number>\d+).ts$}
  end

  AGENT_ALIAS = 'Windows IE 10' #'
  CLIENT_ID = 'kimne78kx3ncx6brgo4mv6wki5h1ko'

  def get_track_list(url)
    md = url.match(%r{\.twitch\.tv/videos/(?<video_id>\d+)}i)
    video_id = md[:video_id]
    params = {operationName: 'PlaybackAccessToken_Template', query: 'query PlaybackAccessToken_Template($login: String!, $isLive: Boolean!, $vodID: ID!, $isVod: Boolean!, $playerType: String!) {  streamPlaybackAccessToken(channelName: $login, params: {platform: "web", playerBackend: "mediaplayer", playerType: $playerType}) @include(if: $isLive) {    value    signature   authorization { isForbidden forbiddenReasonCode }   __typename  }  videoPlaybackAccessToken(id: $vodID, params: {platform: "web", playerBackend: "mediaplayer", playerType: $playerType}) @include(if: $isVod) {    value    signature   __typename  }}',
              variables: { isLive: false, login: '', isVod: true, vodID: video_id, playerType: 'site'}}

    json_page = agent.post('https://gql.twitch.tv/gql', params.to_json,
      { 'Content-Type' => 'text/plain;charset=UTF-8', 'Client-ID' => CLIENT_ID })

    json = JSON(json_page.content)
    signature = json.dig('data', 'videoPlaybackAccessToken', 'signature')
    token = json.dig('data', 'videoPlaybackAccessToken', 'value')

    m3u_data = M3UParser.new(agent.get("https://usher.ttvnw.net/vod/#{video_id}.m3u8",
                                          { sig: signature, token: token, allow_source: true }).content).parse

    max_res_playlist_url = m3u_data[:entries].max_by{ |entry| entry && entry['BANDWIDTH'].to_i }[:url]

    track_list = M3UParser.new(agent.get(max_res_playlist_url).content).extract_tracklist(max_res_playlist_url)

    { id: video_id, track_list: track_list }
  end
end
