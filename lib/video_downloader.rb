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
  TMPDIR = '/tmp'

  def self.can_download?(url)
    false
  end

  def download_video(url, start: 1, endno: nil, combine: false)
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
    puts "\033[udone."

    if combine then
      upload combine(segments, prefix), prefix, url
    else
      upload segments, prefix, url
    end

    true
  end

  def in_tmp_dir(file_name)
    Pathname.new(TMPDIR).join(file_name).to_s
  end

  def combine(segments, prefix)
    ffmpeg = `which ffmpeg`
    raise "FFMPEG binary not found" if ffmpeg.empty?

    outfilename = in_tmp_dir("_#{prefix}.mp4")
    segment_list_file = generate_segment_list(in_tmp_dir('_list.txt'), segments, prefix)
    `ffmpeg -f concat -safe 0 -i #{segment_list_file} -c copy #{outfilename}`
    File.delete(segment_list_file)

    [ outfilename ]
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

    full_path = in_tmp_dir("%s-%04d.ts" % [ prefix[-3..-1], n ])
    newfile.save_as(full_path)
    return full_path
  end

  def upload(files, prefix, source_url)
    Net::SFTP.start(config('SFTP_SITE'), config('SFTP_USER'),
                     { :port => config('SFTP_PORT'), :password => config('SFTP_PASSWORD'),
                       :non_interactive => true }) { |sftp|
      sftp.mkdir prefix

      if files.size > 1 then
        files << generate_segment_list(in_tmp_dir('_list.txt'), files, source_url)
        files << generate_batch_file(in_tmp_dir("_#{prefix}.bat"), files, source_url, prefix)
      end

      print "Uploading... \033[s"

      files.each do |fn|
        sftp.upload!(fn, "#{prefix}/#{File.basename(fn)}")
        File.delete(fn)
        print "\033[u#{fn}"
      end

      puts "\033[udone.\033[K"
    }
  end

  def generate_segment_list(list_path, arr, source_url)
    File.open(list_path, "w") { |f|
      f.puts "# Segment list from #{source_url}"
      arr.each { |fn| f.puts "file '#{File.basename(fn)}'" }
    }

    list_path
  end

  def generate_batch_file(bat_path, arr, source_url, prefix)
    File.open(bat_path, "w") { |f|
      f.puts "rem #{source_url}"
      f.puts "#{config('FFMPEG_PATH')} -f concat -safe 0 -i _list.txt -c copy _#{prefix}.mp4"
    }

    bat_path
  end

  def config(k)
    @config ||= YAML.load(File.read("config.yml"))
    @config[k]
  end

  def get_segment_by_url(url, prefix)
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

  def download_video_by_url(url, combine: false)
    segments = []

    @agent = Mechanize.new { |agent|
      agent.user_agent_alias = self.class.const_get(:AGENT_ALIAS)
      agent.read_timeout = 5
    }

    prefix, urls = get_track_list(url)

    print "Downloading... \033[s"

    urls.each { |url|
      print "\033[u#{url}"
      segments << get_segment_by_url(url, prefix)
    }
    puts "\033[udone."

    if combine then
      upload combine(segments, prefix), prefix, url
    else
      upload segments, prefix, url
    end

    true
  end

end
