extends Node2D

const TimeFormat = preload("res://Scripts/TimeFormat.gd")

const _INDEX_FILE_URL = "https://raw.githubusercontent.com/nightblade9/islamic-lectures-app/master/metadata.json"

var _items:Array

func _ready():
	var request = HTTPRequest.new()
	add_child(request)
	request.connect("request_completed", self, "_on_download_completed")
	request.request(_INDEX_FILE_URL)

func _on_download_completed(result, response_code, headers, body):
	$Panel/StatusLabel.text = ""
	var json = JSON.parse(body.get_string_from_utf8()).result
	_items = json
	
	for item in json:
		$LeftPanel/ItemList.add_item(item.title)

func _on_ItemList_item_selected(index):
	var item = _items[index]
	$Panel/AudioPlayer.item = item
	$Panel/AudioPlayer.show()
	$Panel/StatusLabel.text = _display_for(item)

func _on_ItemList_nothing_selected():
	$Panel/StatusLabel.text = ""
	$Panel/AudioPlayer.hide()

func _display_for(item):
	return "Title: " + item.title + \
	"\nDuration: " + TimeFormat.seconds_to_time(item.duration_minutes * 60 + item.duration_seconds) + \
	"\nAdded on: " + item.added_on