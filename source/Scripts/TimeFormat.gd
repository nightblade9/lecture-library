extends Node

static func seconds_to_time(total_seconds:int):
	var seconds:int = total_seconds % 60
	var minutes:int = total_seconds / 60
	var hours:int = minutes / 60
	
	var display_seconds = str(seconds)
	if seconds < 10: display_seconds = "0" + str(seconds)
	var display_minutes = str(minutes)
	if minutes < 10: display_minutes = "0" + str(minutes)
	
	
	if minutes < 60:
		return str(minutes) + ":" + display_seconds
	else:
		return str(hours) + ":" + display_minutes + ":" + display_seconds
