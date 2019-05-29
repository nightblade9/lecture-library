extends Node2D

const _INDEX_FILE_URL = "https://raw.githubusercontent.com/nightblade9/islamic-lectures-app/master/metadata.json"

func _ready():
	var request = HTTPRequest.new()
	add_child(request)
	request.connect("request_completed", self, "_on_download_completed")
	request.request(_INDEX_FILE_URL)

func _on_download_completed(result, response_code, headers, body):
	var json = JSON.parse(body.get_string_from_utf8())
	$Label.text = str(json.result)