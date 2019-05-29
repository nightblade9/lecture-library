extends WindowDialog

var item:Dictionary

func _ready():
	$PlayButton.disabled = true
	$PlayButton.text = "Loading ..."
	# TODO: doesn't seem possible to stream, just to get the whole file
	var request = HTTPRequest.new()
	add_child(request)
	request.connect("request_completed", self, "_on_audio_ready")
	request.request(item.url)

func _on_audio_ready(result, response_code, headers, body):
	$PlayButton.disabled = false
	$PlayButton.text = "Play"
	
	var ogg = AudioStreamOGGVorbis.new()
	ogg.data = body
	$AudioStreamPlayer.stream = ogg
	$AudioStreamPlayer.play()