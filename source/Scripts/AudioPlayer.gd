extends WindowDialog

var item:Dictionary
var thread:Thread

func _ready():
	thread = Thread.new()
	$PlayButton.disabled = true
	$PlayButton.text = "Loading ..."
	
	#if not thread.is_active():
	thread.start(self, "_start_streaming")

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
	var rb = PoolByteArray()
	
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
				rb = rb + chunk
				
				# Updated every chunk, meh.
				$PlayButton.disabled = false
				$PlayButton.text = "Play"
				
				# constantly re-assign
				ogg_stream.data = rb
				$AudioStreamPlayer.stream = ogg_stream
				#call_deferred("_send_loading_signal",rb.size(),http.get_response_body_length())
	
	############################################################

func _on_PlayButton_pressed():
	$AudioStreamPlayer.play()
