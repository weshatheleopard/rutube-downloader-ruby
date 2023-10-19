# rutube-downloader-ruby

Download video files from the sites that generally don't want you to download videos from.

Currently supported:
  * [Twitch](https://www.twitch.tv/)
  * [RuTube](https://rutube.ru/)
  * [TV Zvezda](https://tvzvezda.ru/)
  * [Rambler News](https://news.rambler.ru/video/)
  * [Fox News](https://www.foxnews.com) [OLD]
  
Others can be added too through respective subclasses
  
## How to use:
Most downloaders have been moved to support both video file URL and main video page URL, which makes downloading more user-friendly. Old method still works.

### NEW mehod

#### Option 1 (shell):
1. In the system shell, execute `dl` script with the URL of the webpage where video is located (`./dl http://video.site/breaking-news-654321`)

#### Option 2 (Ruby console):
1. Launch the console of this project (`rake console`)
2. Launch the code with the URL of the webpage where video is located (`dl 'http://video.site/breaking-news-654321'`)

### OLD method (still works!)

1. Start watching the desired video
2. Using Firefox's Developer Tools (invoked by F12), in the Network tab, set filter to "Media". Watch the .ts files being downloaded.
3. Copy the URL of any of such file

#### Option 1 (shell):
4. In the system shell, execute `dl` script with the URL obtained at the step above (`./dl http://......long_video_file_url......`)

#### Option 2 (Ruby console):
4. Launch the console of this project (`rake console`)
5. Launch the code with the URL obtained at the step above (`dl 'http://......long_video_file_url........'`)

The code will automatically detect the total number of segments in the video and download them all. It will also create the Windows BAT file for `ffmpeg` to join all these segments into a single video file.

#### Named parameters (console only):
  * `start` - start downloading with this segment number
  * `endno` - finish downloading with this segment number (otherwise perform automatic detection)

## File assembly

Result file can now be assembled from chunks on the system doing the downloading. In that case, `ffmpeg` has to be installed on that system:

  `sudo apt-get install ffmpeg`

In that case, only the final file will be uploaded. This is controlled by the `combine:` named parameter of the call to `dl` in console.

Temporary files are now stored in `/tmp` and deleted upon successful uploading.
