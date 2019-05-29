extends WindowDialog

# We can't play audio until we streamed enough of the file. This value
# (how many bytes needed) is experimentally derived.
const _BYTES_NEEDED_TO_PLAY_FILE = 8192 # 8kb

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

func _copy_and_start(position = 0):
	var ogg_stream = AudioStreamOGGVorbis.new()
	ogg_stream.data = buffer
	$AudioStreamPlayer.stream = ogg_stream
	$AudioStreamPlayer.play(position)

func _on_finished():
	_copy_and_start($AudioStreamPlayer.get_playback_position())
	
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
				#$StatusLabel.text = "Streamed: " + str(len(buffer) / 1024.0 / 1024.0) + " mb"
				
	