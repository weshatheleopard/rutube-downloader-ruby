require 'yaml'
require 'net/sftp'
require 'mechanize'

# Subclasses should definitely overload:
# * +segment_regexp+
#   - Regexp that matches the source URL, returning 1st capture section that contains the video identifier,
#     (used, in particular, to name the download directory), and 2nd capture section that contains the
#     name of the specific segment
#     TODO: make these parameters named instead of numbered.
# * +segment_name(n)+ - String, containing the exact name of segment number `n`.

class VideoDownloader
  def find_last(re, url)
    mid = nil
    end_number = start_number = 1

    print "Detecting length... \033[s"

    # Perform binary search up to find a number betond the end of the stream

    100.times do
      end_number = end_number * 2

      print "\033[u#{end_number}"

      break if !test_number(re, url, end_number)
    end

    # Perform binary search down up to the actual end of the stream

    100.times do
      mid = (start_number + end_number) / 2

      print "\033[u#{mid}"

      if test_number(re, url, mid) then
        start_number = mid
      else
        end_number = mid
      end

      break if start_number + 1 == end_number
    end

    puts "\033[u#{start_number}"
    return start_number
  end

  def test_number(re, url, n)
    begin

      test_url = url.gsub(re, segment_name(n))
      @agent.read_timeout = 5
      @agent.head(test_url)
      return true
    rescue Net::ReadTimeout
      return false
    rescue Mechanize::ResponseCodeError => e
      case e.response_code
      when '403', '404' then return false
      else retry
      end
    end
  end

  def download_video(url, start: 1, endno: nil)
    @agent = Mechanize.new { |agent|
      agent.user_agent_alias = 'Windows IE 10' #'
    }

    Net::SFTP.start(config('SFTP_SITE'), config('SFTP_USER'),
                     { :port => config('SFTP_PORT'), :password => config('SFTP_PASSWORD'),
                       :non_interactive => true }) { |sftp|
      url =~ segment_regexp
      re = Regexp.new(segment_name($2))
      prefix = $1

      sftp.mkdir prefix
      endno ||= find_last(re, url)

      arr = []

      print "\033[s"

      start.upto(endno) do |i|
        newurl = url.gsub(re, segment_name(i))
        begin
          p = @agent.get(newurl)
        rescue Mechanize::ResponseReadError
          retry
        rescue Mechanize::ResponseCodeError => e
          case e.response_code
          when '503','504' then
            print "!"
            retry
          else
            raise
          end
        end

        print "\033[u#{i}/#{endno}\033[0K"

        fn = "%s-%04d.ts" % [ prefix[-3..-1], i ]
        p.save_as(fn)
        sftp.upload!(fn, "#{prefix}/#{fn}")
        File.delete(fn)

        arr << fn
      end
      puts

      gen_bat(arr, url) { |filepath| sftp.upload!(filepath, "#{prefix}/_#{prefix}.bat" ) }
    }
  end

  def gen_bat(arr, url)
    cmd = "#{config('FFMPEG_PATH')} -i \"concat:#{arr.join('|')}\" -c copy !out.mp4"

    Tempfile.create { |f|
      f.puts cmd ; f.puts "rem #{url}"
      f.flush
      f.rewind
      yield(f.path)
    }
  end

  def config(k)
    @config ||= YAML.load(File.read("config.yml"))
    @config[k]
  end
end
