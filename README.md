yt.lua
======

Usage
-----

A neat commandline tool to download videos off youtube
Usage: ./yt.lua ID [AF [VF]]

where:
* ID is either the id of video or a link to it
* AF is the format of audio
* VF is the format of video
Format can be a number, 1 for first, 2 for second, -1 for last, etc; + for the best; or - for the worst. A special case is 0, when a component is not downloaded at all.
If any of formats is omitted, or is an empty string, you'll be given an interactive choice.
If you are downloading both components the script will attempt to merge them using ffmpeg or avconv

Dependencies
------------

* A computer
* An Internet connection
* lua 5.x
* wget
* bash/zsh/dash/sh/whatever
* Optional: ffmpeg or avconv

Examples
--------

    ./yt.lua http://www.youtube.com/watch?v=dQw4w9WgXcQ
	./yt.lua dQw4w9WgXcQ
	./yt.lua dQw4w9WgXcQ + +
	# automatically pick the best quality
	./yt.lua dQw4w9WgXcQ - -
	# automatically pick the worst quality (for fast download)
	./yt.lua dQw4w9WgXcQ "" 1
	# interactively choose audio format, but select first video format automatically

