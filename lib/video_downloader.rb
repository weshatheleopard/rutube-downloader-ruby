require 'yaml'
require 'net/sftp'
require 'mechanize'
require 'terminfo'

require 'term/ansicolor'
include Term::ANSIColor

# Subclasses should definitely overload:
# * +segment_regexp+
#   - Regexp that matches the source URL, returning 1st capture section that contains the video identifier,
#     (used, in particular, to name the download directory), and 2nd capture section that contains the
#     name of the specific segment
# * +segment_name(n)+ - String, containing the exact name of segment number `n`.
# * +can_download(url)+ - Boolean, true if the subclass claims that it can properly download +url+.

class VideoDownloader
  def initialize
    terminfo = TermInfo.new
    @save_pos = terminfo.tigetstr("sc")
    @restore_pos = terminfo.tigetstr("rc")
    @erase_to_eol = terminfo.tigetstr("el")
  end

  def self.can_download?(url)
    false
  end

  def download_video(source_url, start: 1, endno: nil, combine: false)
    @agent = Mechanize.new { |agent|
      agent.user_agent_alias = 'Windows IE 10' #'
      agent.read_timeout = 5
    }

    segment_number = start
    segments = []

    match_data = source_url.match(segment_regexp)
    prefix = match_data[:prefix]
    re = Regexp.new(segment_name(match_data[:number]))

    print "Downloading... #{@save_pos}"

    loop do
      fn = get_segment(source_url, re, segment_number, prefix)

      if fn then
        print "#{@restore_pos}#{@erase_to_eol}#{segment_number.yellow}"
        segments << fn
        segment_number += 1
        break if endno && segment_number > endno
      else
        break
      end
    end
    puts "#{@restore_pos}#{@erase_to_eol}#{'done.'.white.bold}"

    if combine then
      upload combine(segments, prefix), prefix, source_url
    else
      upload segments, prefix, source_url
    end

    true
  end

  def in_tmp_dir(file_name, prefix)
    tmp_dir_name(prefix).join(file_name).to_s
  end

  def tmp_dir_name(prefix)
    Pathname.new(config('TMPDIR', '/tmp')).join(prefix)
  end

  def combine(segments, prefix)
    ffmpeg = `which ffmpeg`
    raise "FFMPEG binary not found" if ffmpeg.empty?

    outfilename = in_tmp_dir("_#{prefix}.mp4", prefix)
    segment_list_file = generate_segment_list(in_tmp_dir('_list.txt', prefix), segments, prefix)
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

    full_path = in_tmp_dir("%s-%04d.ts" % [ prefix[-3..-1], n ], prefix)
    newfile.save_as(full_path)
    return full_path
  end

  def upload(files, prefix, source_url, extra_params = {})
    Net::SFTP.start(config('SFTP_SITE'), config('SFTP_USER'),
                     { :port => config('SFTP_PORT'), :password => config('SFTP_PASSWORD'),
                       :non_interactive => true }) { |sftp|
      sftp.mkdir prefix

      if files.size > 1 then
        files << generate_segment_list(in_tmp_dir('_list.txt', prefix), files, source_url, extra_params)
        files << generate_batch_file(in_tmp_dir("_#{prefix}.bat", prefix), files, source_url, prefix)
      end

      print "Uploading... #{@save_pos}"

      files.each_with_index do |fn, idx|
        sftp.upload!(fn, "#{prefix}/#{File.basename(fn)}")
        File.delete(fn)
        print "#{@restore_pos}#{@erase_to_eol} #{File.basename(fn).white.bold} (#{(idx + 1).to_s.yellow}/#{(files.count).to_s.yellow})"
      end

      FileUtils.rmdir(tmp_dir_name(prefix))

      puts "#{@restore_pos}#{@erase_to_eol}#{'done.'.white.bold}"
    }
  end

  def generate_segment_list(list_path, arr, source_url, extra_params = {})
    File.open(list_path, "w") { |f|
      f.puts "# Segment list for #{source_url}"

      { title: 'Title', created: 'Created', resolution: 'Resolution' }.each_pair { |k,v|
        f.puts "# #{v}: #{extra_params[k]}" if extra_params&.has_key?(k)
      }

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

  def config(k, default_value = nil)
    @config ||= YAML.load(File.read("config.yml"))
    @config[k] || default_value
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

    full_path = in_tmp_dir(newfile.filename, prefix)
    newfile.save_as(full_path)
    return full_path
  end

  def download_video_by_url(source_url, combine: false)
    segments = []

    @agent = Mechanize.new { |agent|
      agent.user_agent_alias = self.class.const_get(:AGENT_ALIAS)
      agent.read_timeout = 5
    }

    puts "Obtaining track list from #{source_url.white.bold}"

    data = get_track_list(source_url)

    prefix = data[:id]
    urls = data[:track_list]
    title = data[:title]
    created = data[:created]

    puts "Video title: #{title.white.bold}" if title
    puts "Video created: #{created.white.bold}" if created

    print "Downloading segments... #{@save_pos}"

    urls.each_with_index { |url, idx|
      print "#{@restore_pos}#{@erase_to_eol}#{File.basename(url).white.bold} (#{(idx + 1).to_s.yellow}/#{(urls.count).to_s.yellow})"
      segments << get_segment_by_url(url, prefix)
    }
    puts "#{@restore_pos}#{@erase_to_eol}#{'done'.white.bold}."

    if combine then
      upload combine(segments, prefix), prefix, source_url, data
    else
      upload segments, prefix, source_url, data
    end

    true
  end

end
