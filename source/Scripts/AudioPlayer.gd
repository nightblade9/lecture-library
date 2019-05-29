extends WindowDialog

# We can't play audio until we streamed enough of the file. This value
# (how many bytes needed) is experimentally derived.
const _BYTES_NEEDED_TO_PLAY_FILE = 8192 # 8kb
var item:Dictionary
var thread:Thread
var _is_playing = false

func _ready():
	thread = Thread.new()
	
	#if not thread.is_active():
	#thread.start(self, "_start_streaming")
	self._start_streaming([])

func _start_streaming(params):
	var start = item.url.find("://") + 3
	var stop = item.url.find("/", start)
	var host = item.url.substr(start, stop - start)
	var use_ssl = item.url.find("https://") > -1
	
	var url = item.url.substr(stop, len(item.url))
	
	# Stream the file
	var http = HTTPClient.new()
	var error = http.connect_to_host(host, -1, use_ssl)
	
	var ogg_stream = AudioStreamOGGVorbis.new()
	var buffer = PoolByteArray()
	
	############################################################
	# http://codetuto.com/2015/05/using-httpclient-in-godot/
	
	while(http.get_status() != HTTPClient.STATUS_CONNECTED):
		http.poll()
		OS.delay_msec(100)

	var headers = [
		"User-Agent: Pirulo/1.0 (Godot)",
		"Accept: */*"
	]

	var status = http.get_status()
	var expected = HTTPClient.STATUS_CONNECTED

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
				
				ogg_stream.data = buffer
				$AudioStreamPlayer.stream = ogg_stream
				
				$StatusLabel.text = "Streamed: " + str(len(buffer) / 1024 / 1024.0) + " mb"
				if len(buffer) >= _BYTES_NEEDED_TO_PLAY_FILE and not _is_playing:
					_is_playing = true
					$AudioStreamPlayer.play()
					print("PLAYER")
					yield()
					#yield(get_tree().create_timer(1), 'timeout')
				
				#call_deferred("_send_loading_signal",rb.size(),http.get_response_body_length())
	