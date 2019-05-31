extends WindowDialog

# We can't play audio until we streamed enough of the file. This value
# (how many bytes needed) is experimentally derived.
const _BYTES_NEEDED_TO_PLAY_FILE = 8192 # 8kb
const ICONS = {
	"play": preload("res://assets/play-button.png"),
	"stop": preload("res://assets/stop-button.png"),
	"pause": preload("res://assets/pause-button.png"),
}

var item:Dictionary # URL, etc.

var thread:Thread # BG thread that buffers data
var buffer:PoolByteArray = PoolByteArray() # buffered data

func _ready():
	thread = Thread.new()
	thread.start(self, "_start_streaming")
	
	###
	# Wait until we have enough data loaded that we can start. Otherwise, no audio.
	###
	while len(buffer) < _BYTES_NEEDED_TO_PLAY_FILE:
		OS.delay_msec(100)
		
	_copy_and_start()
	$AudioStreamPlayer.connect("finished", self, "_on_finished")

func _process(t):
	if $AudioStreamPlayer.playing and $AudioStreamPlayer.get_playback_position() > 1:
		$StatusLabel.text = "Playing " + _seconds_to_time($AudioStreamPlayer.get_playback_position()) + " / " + _seconds_to_time(item.duration_minutes * 60 + item.duration_seconds)
		$StatusLabel.text += "\nStreamed: " + str(len(buffer) / 1024.0 / 1024.0) + " mb"

func _seconds_to_time(total_seconds:int):
	var seconds:int = total_seconds % 60
	var minutes:int = total_seconds / 60	
	var hours:int = minutes / 60
	
	var display_seconds = str(seconds)
	if seconds < 10: display_seconds = "0" + str(seconds)
	var display_minutes = str(minutes)
	if minutes < 10: display_minutes = "0" + str(minutes)
	
	
	if minutes < 60:
		return str(minutes) + ":" + display_seconds
	else:
		return str(hours) + ":" + display_minutes + ":" + display_seconds

func _copy_and_start(position = 0):
	
	if $AudioStreamPlayer.stream == null:
		var ogg_stream = AudioStreamOGGVorbis.new()
		ogg_stream.data = buffer
		$AudioStreamPlayer.stream = ogg_stream
	
	# CRASH $AudioStreamPlayer.stream.data = buffer
	$AudioStreamPlayer.stream.data.resize(0)
	$AudioStreamPlayer.stream.data = buffer	
	
	$AudioStreamPlayer.play(position)

###
# Not a true finish, could be that we buffered some data and ran out.
# Then, in that case, reload and resume playback.
# OR, could be the audio file finished.
###
func _on_finished():
	# NB: end detection breaks if we truncate buffer. If that becomes
	# an issue, then just keep appending to a separate size variable
	if $AudioStreamPlayer.stream.data.size() < buffer.size():
		_copy_and_start($AudioStreamPlayer.get_playback_position())
	else:
		# Audio file is done
		$StatusLabel.text = "Done"
	
func _start_streaming(params):
	var start = item.url.find("://") + 3
	var stop = item.url.find("/", start)
	var host = item.url.substr(start, stop - start)
	var use_ssl = item.url.find("https://") > -1
	
	var url = item.url.substr(stop, len(item.url))
	
	# Stream the file
	var http = HTTPClient.new()
	var error = http.connect_to_host(host, -1, use_ssl)
		
	############################################################
	# http://codetuto.com/2015/05/using-httpclient-in-godot/
	
	while(http.get_status() != HTTPClient.STATUS_CONNECTED):
		http.poll()
		OS.delay_msec(100)

	var headers = [
		"User-Agent: Pirulo/1.0 (Godot)",
		"Accept: */*"
	]

	# TODO: do everything below in a background thread as we play
	error = http.request(HTTPClient.METHOD_GET, url, headers)

	while (http.get_status() == HTTPClient.STATUS_REQUESTING):
		http.poll()
		OS.delay_msec(100)

	if(http.has_response()):
		headers = http.get_response_headers_as_dictionary()
		while(http.get_status() == HTTPClient.STATUS_BODY):
			http.poll()
			var chunk = http.read_response_body_chunk()
			if(chunk.size() == 0):
				OS.delay_usec(100)
			else:
				buffer.append_array(chunk)

func _on_PlayStopButton_pressed():
	if $AudioStreamPlayer.playing:
		$AudioStreamPlayer.stop()
		$PlayStopButton.icon = ICONS["play"]
		$PauseResumeButton.icon = ICONS["pause"]
	else:
		$AudioStreamPlayer.play()
		$PlayStopButton.icon = ICONS["stop"]

func _on_PauseResumeButton_pressed():
	$AudioStreamPlayer.stream_paused = not $AudioStreamPlayer.stream_paused
	if $AudioStreamPlayer.stream_paused:
		$PauseResumeButton.icon = ICONS["play"]
	else:
		$PauseResumeButton.icon = ICONS["pause"]
