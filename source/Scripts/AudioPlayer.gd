extends Panel

const TimeFormat = preload("res://Scripts/TimeFormat.gd")

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
var buffer:PackedByteArray = PackedByteArray() # buffered data

var _terminate = false
var _started = false

func stop():
	$AudioStreamPlayer.stop()
	_terminate = true
	_started = false
	$StatusLabel.text = ""
	$PlayStopButton.icon = ICONS["play"]

func _start():
	_terminate = false
	
	if not _started:
		_started = true
		buffer = PackedByteArray()
		
		thread = Thread.new()
		thread.start(_start_streaming)
		
		###
		# Wait until we have enough data loaded that we can start. Otherwise, no audio.
		###
		while len(buffer) < _BYTES_NEEDED_TO_PLAY_FILE:
			OS.delay_msec(100)
			await get_tree().process_frame
			
		_copy_and_start()
		$AudioStreamPlayer.connect("finished", _on_finished)
		$PositionSlider.max_value = (60 * item.duration_minutes) + item.duration_seconds

func _process(t):
	if $AudioStreamPlayer.playing and $AudioStreamPlayer.get_playback_position() > 1:
		$StatusLabel.text = "Playing " + TimeFormat.seconds_to_time($AudioStreamPlayer.get_playback_position()) + " / " + TimeFormat.seconds_to_time(item.duration_minutes * 60 + item.duration_seconds)
		$StatusLabel.text += "\nStreamed: " + str(len(buffer) / 1024.0 / 1024.0) + " mb"
		$PositionSlider.value = $AudioStreamPlayer.get_playback_position()

func _copy_and_start(position = 0):
	
	if $AudioStreamPlayer.stream == null:
		var ogg_stream = AudioStreamOggVorbis.new()
		var ogg_packet = OggPacketSequence.new()
		ogg_packet.packet_data = buffer
		ogg_stream.packet_sequence = ogg_packet
		$AudioStreamPlayer.stream = ogg_stream
	
	# CRASH $AudioStreamPlayer.stream.data = buffer
	#$AudioStreamPlayer.stream.packet_sequence.resize(0)
	#$AudioStreamPlayer.stream.packet_sequence = buffer
	
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
	
func _start_streaming():
	var start = item.url.find("://") + 3
	var stop = item.url.find("/", start)
	var host = item.url.substr(start, stop - start)
	var use_ssl = item.url.find("https://") > -1
	
	var url = item.url#.substr(stop, len(item.url))
	
	# Stream the file
	var http = HTTPClient.new()
	var error = http.connect_to_host(host, -1)#, use_ssl)
		
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

	if(http.has_response() and not _terminate):
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
		self._start()
		$AudioStreamPlayer.play()
		$PlayStopButton.icon = ICONS["stop"]

func _on_PauseResumeButton_pressed():
	$AudioStreamPlayer.stream_paused = not $AudioStreamPlayer.stream_paused
	if $AudioStreamPlayer.stream_paused:
		$PauseResumeButton.icon = ICONS["play"]
	else:
		$PauseResumeButton.icon = ICONS["pause"]

func _on_PositionSlider_gui_input(event):
	if (event is InputEventMouseButton and event.pressed) or (OS.has_feature("Android") and event is InputEventMouseMotion):
		var click_x = event.position.x
		var span = $PositionSlider.offset_right - $PositionSlider.offset_left
		var click_percent = click_x / span
		var click_time_seconds = click_percent * ((item.duration_minutes * 60) + item.duration_seconds)
		
		var max_seconds_loaded = $AudioStreamPlayer.stream.get_length()
		if click_time_seconds > max_seconds_loaded:
			click_time_seconds = max_seconds_loaded
			
		_copy_and_start(click_time_seconds)
