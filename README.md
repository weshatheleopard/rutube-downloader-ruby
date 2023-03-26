# rutube-downloader-ruby

Download video files from the sites that generally don't want you to download videos from.

Currently supported:
  * [Twitch](https://www.twitch.tv/)
  * [RuTube](https://rutube.ru/)
  * [TV Zvezda](https://tvzvezda.ru/)
  * [Fox News](https://www.foxnews.com)
  
Others can be added too through respective subclasses
  
How:
1) Start watching the desired video
2) Using Firefox's Developer Tools (invoked by F12), in the Network tab, set filter to "Media". Watch the .ts files being downloaded.
3) Copy the URL of any of such file
4) Launch the console of this project (`rake console`)
5) Launch the code with the URL obtained at the step above (`dl 'http://......long_video_file_url........'`). The code will automatically detect the total number of segments in the video and download them all. It will also create the Windows BAT file for `ffmpeg` to join all these segments into a single video file.
