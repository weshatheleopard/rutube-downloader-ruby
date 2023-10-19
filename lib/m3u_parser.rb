class M3uParser
  def initialize(str)
    @str = str
  end

  def parse
    general_hash = { playlists: [] }
    state = params_hash = nil

    @str.each_line { |line|
      if line == '#EXTM3U' then
        next
      end

      md = line.match(/^#EXT-X-STREAM-INF:(?<params>.+)$/)
      if md then
        params_hash = md[:params].scan(/([A-Z0-9-]+)=(?:([A-Za-z0-9-]+)|\"([^"]+)\")/).map(&:compact).to_h
      end

      md = line.match(/^(?<url>http(?:s?):\/\/.+)$/)
      if md then
        params_hash[:url] = md[0] 
        general_hash[:playlists] << params_hash
        params_hash = nil
      end
    }

    general_hash
  end
end