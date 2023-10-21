class M3UParser
  def initialize(str)
    @str = str
    @m3u = nil
  end

  def unknown(str, state)
     puts "=> Unknown line: [#{str}] in #{state}"
  end

  def push_playlist(pl)
    return if pl.nil? || pl.empty?
    @m3u ||= {}
    @m3u[:entries] ||= []
    @m3u[:entries] << pl
  end

  def parse
    state = :bof
    params_hash = nil
    lines = @str.lines


    loop do
      line = lines.shift&.strip

      if line.nil?
        push_playlist(params_hash)
        break
      end

      case state
      when :bof then
        case line
        when '#EXTM3U' then
          @m3u = {}
          @params_hash = {}
          state = :start
        else
          unknown(line, state)
        end
      when :start then
        case line
        when /^#EXT-X-STREAM-INF:/ then
          md = line.match(/^#EXT-X-STREAM-INF:(?<params>.+)$/)
          if md then
            push_playlist(params_hash)
            params_hash = md[:params].scan(/([A-Z0-9-]+)=(?:([A-Za-z0-9-]+)|\"([^"]+)\")/).map(&:compact).to_h
          end
        when /^#EXTINF:/ then
          md = line.match(/^#EXTINF:(?<params>.+)$/)
          if md then
            push_playlist(params_hash)
            params_hash = { info: md[:params] }
          end
        when /^#EXT-X-TARGETDURATION:/ then
          md = line.match(/^#EXT-X-TARGETDURATION:(?<params>.+)$/)
          if md then
            @m3u['TARGETDURATION'] = md[:params]
          end
        when /^#EXT-X-ALLOW-CACHE:/ then
          md = line.match(/^#EXT-X-ALLOW-CACHE:(?<params>.+)$/)
          if md then
            @m3u['ALLOW-CACHE'] = md[:params]
          end
        when /^#EXT-X-PLAYLIST-TYPE:/ then
          md = line.match(/^#EXT-X-PLAYLIST-TYPE:(?<params>.+)$/)
          if md then
            @m3u['PLAYLIST-TYPE'] = md[:params]
          end
        when /^#EXT-X-VERSION:/ then
          md = line.match(/^#EXT-X-VERSION:(?<params>.+)$/)
          if md then
            @m3u['VERSION'] = md[:params]
          end
        when /^#EXT-X-MEDIA-SEQUENCE:/ then
          md = line.match(/^#EXT-X-MEDIA-SEQUENCE:(?<params>.+)$/)
          if md then
            @m3u['MEDIA-SEQUENCE'] = md[:params]
          end
        when /^#EXT-X-ENDLIST/, '' then
          push_playlist(params_hash)
          break
        when /^(?!#)http.+/ then
          params_hash[:url] = line
        when /^(?!#).+/ then
          params_hash[:filename] = line
        else
          unknown(line, state)
        end
      end
    end

    @m3u
  end

  def extract_tracklist(base_url = '')
    self.parse[:entries].map { |entry|
      if entry.has_key?(:url) then
        entry[:url]
      else
        URI(base_url).merge(entry[:filename]).to_s
      end
    }
  end
end
