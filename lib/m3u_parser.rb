require 'uri'

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
        when /^#EXTINF:/ then
          md = line.match(/^#EXTINF:(?<params>.+)$/)
          if md then
            push_playlist(params_hash)
            params_hash = { info: md[:params] }
          end
        when /^#EXT-X-STREAM-INF:/ then
          md = line.match(/^#EXT-X-STREAM-INF:(?<params>.+)$/)
          if md then
            push_playlist(params_hash)
            params_hash = md[:params].scan(/([A-Z0-9-]+)=(?:([A-Za-z0-9-]+)|"([^"]+)")/).map(&:compact).to_h
          end
        when /^#EXT-X-ENDLIST/, '' then
          push_playlist(params_hash)
          break
        when /^#EXT-X-[A-Z0-9-]+:/ then
          md = line.match(/^#EXT-X-(?<tag>[A-Z0-9-]+):(?<params>.+)$/)
          @m3u[md[:tag]] = md[:params] if md
        when /^#ID3-EQUIV-TDTG:/ then
          md = line.match(/^#ID3-EQUIV-TDTG:(?<params>.+)$/)
          @m3u['ID3-EQUIV-TDTG'] = md[:params] if md
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
