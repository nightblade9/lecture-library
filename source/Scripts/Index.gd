extends Node2D

const TimeFormat = preload("res://Scripts/TimeFormat.gd")

const _INDEX_FILE_URL = "https://raw.githubusercontent.com/nightblade9/lecture-library/master/metadata.json"

var _items:Array

func _ready():
	$Panel/AudioPlayer.hide()
	var request = HTTPRequest.new()
	add_child(request)
	request.connect("request_completed", Callable(self, "_on_download_completed"))
	request.request(_INDEX_FILE_URL)

func _on_download_completed(result:int, response_code:int, headers:PackedStringArray, body:PackedByteArray):
	if result != 0: # RESULT_SUCCESS
		$Panel/StatusLabel.text = "Something went wrong when getting the list of lectures from the server.  Please try again later.\nResult: " + str(result) + ". Response Code: " + str(response_code)
	else:
		$Panel/StatusLabel.text = ""
		var test_json_conv = JSON.new()
		var actual_body = body.get_string_from_utf8()
		var error = test_json_conv.parse(actual_body)
		var json = test_json_conv.data
		#test_json_conv.parse(body.get_string_from_utf8()).result
		#var json = test_json_conv.get_data()
		_items = json
		
		for item in json:
			$LeftPanel/ItemList.add_item(item.title)

func _on_ItemList_item_selected(index):
	var item = _items[index]
	$Panel/AudioPlayer.item = item
	$Panel/AudioPlayer.show()
	$Panel/AudioPlayer.stop()
	$Panel/StatusLabel.text = _display_for(item)

func _on_ItemList_nothing_selected():
	$Panel/StatusLabel.text = ""
	$Panel/AudioPlayer.hide()

func _display_for(item):
	return "Title: " + item.title + \
	"\nDuration: " + TimeFormat.seconds_to_time(item.duration_minutes * 60 + item.duration_seconds) + \
	"\nAdded on: " + item.added_on
