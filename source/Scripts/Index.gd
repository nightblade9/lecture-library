extends Node2D

const AudioPlayer = preload("res://AudioPlayer.tscn")
const _INDEX_FILE_URL = "https://raw.githubusercontent.com/nightblade9/islamic-lectures-app/master/metadata.json"

var _items:Array

func _ready():
	var request = HTTPRequest.new()
	add_child(request)
	request.connect("request_completed", self, "_on_download_completed")
	request.request(_INDEX_FILE_URL)

func _on_download_completed(result, response_code, headers, body):
	$PanelContainer/StatusLabel.text = ""
	var json = JSON.parse(body.get_string_from_utf8()).result
	_items = json
	
	for item in json:
		$LeftPanel/ItemList.add_item(item.title)

func _on_ItemList_item_selected(index):
	var item = _items[index]
	$PanelContainer/AudioPlayer.item = item
	$PanelContainer/AudioPlayer.show()

func _on_ItemList_nothing_selected():
	$PanelContainer/AudioPlayer.hide()
