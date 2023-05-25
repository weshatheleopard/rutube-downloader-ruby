# rutube-downloader-ruby

Download video files from the sites that generally don't want you to download videos from.

Currently supported:
  * [Twitch](https://www.twitch.tv/)
  * [RuTube](https://rutube.ru/)
  * [TV Zvezda](https://tvzvezda.ru/)
  * [Fox News](https://www.foxnews.com)
  * [Rambler News](https://news.rambler.ru/video/)
  
Others can be added too through respective subclasses
  
How to use:
1) Start watching the desired video
2) Using Firefox's Developer Tools (invoked by F12), in the Network tab, set filter to "Media". Watch the .ts files being downloaded.
3) Copy the URL of any of such file

Option 1 (shell):
4) Use the shell, exectute `dl` with the URL obtained at the step above (`./dl 'http://......long_video_file_url.......'`)

Option 2 (Ruby console):
4) Launch the console of this project (`rake console`)
5) Launch the code with the URL obtained at the step above (`dl 'http://......long_video_file_url........'`)

The code will automatically detect the total number of segments in the video and download them all. It will also create the Windows BAT file for `ffmpeg` to join all these segments into a single video file.

Named parameters (console only):
  * `start` - start downloading with this segment number
  * `endno` - finish downloading with this segment number (otherwise perform automatic detection)

