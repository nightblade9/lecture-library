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
	
	for item in json:
		var button = Button.new()
		button.text = item.title + " (" + str(item.duration_minutes) + " minutes)"
		button.connect("button_down", self, "_button_clicked", [item])
		add_child(button)

func _button_clicked(item):
	var player = AudioPlayer.instance()
	player.item = item
	add_child(player)
	player.popup_centered()