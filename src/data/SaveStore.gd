extends Node

const SAVE_PATH := "user://lumarush_save.json"

var data := {
	"high_score": 0,
	"last_play_date": "",
	"streak_days": 0,
	"streak_at_risk": 0,
	"games_played": 0,
	"selected_track_id": "glassgrid",
}

func _ready() -> void:
	load_save()

func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		save()
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var txt := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) == TYPE_DICTIONARY:
		for k in data.keys():
			if parsed.has(k):
				data[k] = parsed[k]

func save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data))
	f.close()

func set_high_score(score: int) -> void:
	if score > int(data["high_score"]):
		data["high_score"] = score
		save()

func clear_high_score() -> void:
	data["high_score"] = 0
	save()

func set_selected_track_id(track_id: String) -> void:
	data["selected_track_id"] = track_id
	save()

func increment_games_played() -> void:
	data["games_played"] = int(data["games_played"]) + 1
	save()

func set_streak_days(days: int) -> void:
	data["streak_days"] = days
	save()

func set_streak_at_risk(days: int) -> void:
	data["streak_at_risk"] = days
	save()

func set_last_play_date(date_key: String) -> void:
	data["last_play_date"] = date_key
	save()
