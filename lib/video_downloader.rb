require 'yaml'
require 'net/sftp'
require 'mechanize'

# Subclasses should definitely overload:
# * +segment_regexp+
#   - Regexp that matches the source URL, returning 1st capture section that contains the video identifier,
#     (used, in particular, to name the download directory), and 2nd capture section that contains the
#     name of the specific segment
# * +segment_name(n)+ - String, containing the exact name of segment number `n`.
# * +can_download(url)+ - Boolean, true if the subclass claims that it can properly download +url+.

class VideoDownloader
  def self.can_download?(url)
    false
  end

  def download_video(url, start: 1, endno: nil)
    @agent = Mechanize.new { |agent|
      agent.user_agent_alias = 'Windows IE 10' #'
      agent.read_timeout = 5
    }

    segment_numbner = start
    segments = []

    match_data = url.match(segment_regexp)
    prefix = match_data[:prefix]
    re = Regexp.new(segment_name(match_data[:number]))

    print "Downloading... \033[s"

    loop do
      fn = get_segment(url, re, segment_numbner, prefix)

      if fn then
        print "\033[u#{segment_numbner}"
        segments << fn
        segment_numbner += 1
        break if endno && segment_numbner > endno
      else
        break
      end
    end
    puts "\033[udone.    "

    upload segments, prefix, url

    true
  end

  # RETURNS: `true` if there are further segments
  def get_segment(url, re, n, prefix)
    begin
      newfile = @agent.get(url.gsub(re, segment_name(n)))

      return false unless newfile.instance_of?(Mechanize::File)
    rescue Net::ReadTimeout
      return false
    rescue Mechanize::ResponseCodeError => e
      case e.response_code
      when '403', '404' then return false
      else retry
      end
    end

    fn = "%s-%04d.ts" % [ prefix[-3..-1], n ]
    newfile.save_as(fn)

    return fn
  end

  def upload(files, prefix, source_url)
    Net::SFTP.start(config('SFTP_SITE'), config('SFTP_USER'),
                     { :port => config('SFTP_PORT'), :password => config('SFTP_PASSWORD'),
                       :non_interactive => true }) { |sftp|
      sftp.mkdir prefix

      print "Uploading... \033[s"

      files.each do |fn|
        sftp.upload!(fn, "#{prefix}/#{fn}")
        File.delete(fn)
        print "\033[u#{fn}"
      end

      puts "\033[udone.           "

      generate_segment_list(files, source_url) { |filepath| sftp.upload!(filepath, "#{prefix}/_list.txt" ) }
      generate_batch_file(files, source_url) { |filepath| sftp.upload!(filepath, "#{prefix}/_#{prefix}.bat" ) }
    }
  end

  def generate_segment_list(arr, source_url)
    Tempfile.create { |f|
      f.puts "# Segment list from #{source_url}"
      arr.each { |fn| f.puts "file '#{fn}'" }
      f.flush
      f.rewind
      yield(f.path)
    }
  end

  def generate_batch_file(arr, source_url)
    cmd = "#{config('FFMPEG_PATH')} -f concat -safe 0 -i _list.txt -c copy !out.mp4"
    Tempfile.create { |f|
      f.puts "rem #{source_url}"
      f.puts cmd
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
