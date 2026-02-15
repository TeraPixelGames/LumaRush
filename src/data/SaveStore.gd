extends Node

const SAVE_PATH := "user://lumarush_save.json"
const WEB_STORAGE_KEY := "lumarush_save_v1"

var data := {
	"high_score": 0,
	"last_play_date": "",
	"streak_days": 0,
	"streak_at_risk": 0,
	"games_played": 0,
	"selected_track_id": "glassgrid",
	"nakama_device_id": "",
	"nakama_user_id": "",
	"terapixel_user_id": "",
	"terapixel_display_name": "",
}

func _ready() -> void:
	load_save()

func load_save() -> void:
	if _load_from_web_storage():
		return
	if _load_from_file():
		return
	save()

func save() -> void:
	var payload: String = JSON.stringify(data)
	if _is_web_storage_supported():
		_save_to_web_storage(payload)
	_save_to_file(payload)

func _load_from_file() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var txt := f.get_as_text()
	f.close()
	return _apply_serialized_payload(txt)

func _save_to_file(payload: String) -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(payload)
	f.close()

func _apply_serialized_payload(payload: String) -> bool:
	var parsed: Variant = JSON.parse_string(payload)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	for k in data.keys():
		if parsed.has(k):
			data[k] = parsed[k]
	return true

func _is_web_storage_supported() -> bool:
	return OS.has_feature("web") and ClassDB.class_exists("JavaScriptBridge")

func _load_from_web_storage() -> bool:
	if not _is_web_storage_supported():
		return false
	var key_literal: String = JSON.stringify(WEB_STORAGE_KEY)
	var js: String = "window.localStorage.getItem(%s);" % key_literal
	var stored: Variant = JavaScriptBridge.eval(js, true)
	if typeof(stored) != TYPE_STRING:
		return false
	var payload: String = str(stored)
	if payload.is_empty():
		return false
	return _apply_serialized_payload(payload)

func _save_to_web_storage(payload: String) -> void:
	if not _is_web_storage_supported():
		return
	var key_literal: String = JSON.stringify(WEB_STORAGE_KEY)
	var payload_literal: String = JSON.stringify(payload)
	var js: String = "window.localStorage.setItem(%s, %s);" % [key_literal, payload_literal]
	JavaScriptBridge.eval(js, true)

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

func get_or_create_nakama_device_id() -> String:
	var current: String = str(data.get("nakama_device_id", ""))
	if not current.is_empty():
		return current
	var bytes: PackedByteArray = Crypto.new().generate_random_bytes(16)
	current = "lr-%s" % bytes.hex_encode()
	data["nakama_device_id"] = current
	save()
	return current

func set_nakama_user_id(user_id: String) -> void:
	data["nakama_user_id"] = user_id
	save()

func set_terapixel_identity(user_id: String, display_name: String = "") -> void:
	data["terapixel_user_id"] = user_id
	if not display_name.is_empty():
		data["terapixel_display_name"] = display_name
	save()

func get_terapixel_user_id() -> String:
	return str(data.get("terapixel_user_id", ""))

func get_terapixel_display_name() -> String:
	return str(data.get("terapixel_display_name", ""))
