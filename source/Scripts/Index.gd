extends Node2D

const AudioPlayer = preload("res://AudioPlayer.tscn")
const _INDEX_FILE_URL = "https://raw.githubusercontent.com/nightblade9/islamic-lectures-app/master/metadata.json"

func _ready():
	var request = HTTPRequest.new()
	add_child(request)
	request.connect("request_completed", self, "_on_download_completed")
	request.request(_INDEX_FILE_URL)

func _on_download_completed(result, response_code, headers, body):
	$Label.text = ""
	var json = JSON.parse(body.get_string_from_utf8()).result
	var i = 0
	
	for item in json:
		var button = Button.new()
		button.text = item.title + " (" + str(item.duration_minutes) + " minutes)"
		button.connect("button_down", self, "_button_clicked", [item])
		button.add_font_override("font", load("res://DefaultFont.tres"))
		
		button.margin_left = 16
		button.margin_top += 16 + (i * 32)
		button.margin_bottom += 16 + (i * 16)
		
		add_child(button)
		i += 1

func _button_clicked(item):
	var player = AudioPlayer.instance()
	player.item = item
	add_child(player)
	player.popup_exclusive = true
	player.popup_centered()
	