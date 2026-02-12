extends Node

const DAY_SECONDS := 86400

func _today_key() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d.year, d.month, d.day]

func _parse_date_key(key: String) -> int:
	var parts := key.split("-")
	if parts.size() != 3:
		return 0
	return int(parts[0]) * 10000 + int(parts[1]) * 100 + int(parts[2])

func _days_between(a: String, b: String) -> int:
	# Approx using Julian day from system for accuracy
	var da := Time.get_datetime_dict_from_system()
	var db := Time.get_datetime_dict_from_system()
	if a != "":
		var pa := a.split("-")
		if pa.size() == 3:
			da.year = int(pa[0])
			da.month = int(pa[1])
			da.day = int(pa[2])
	if b != "":
		var pb := b.split("-")
		if pb.size() == 3:
			db.year = int(pb[0])
			db.month = int(pb[1])
			db.day = int(pb[2])
	var ja := Time.get_unix_time_from_datetime_dict(da) / DAY_SECONDS
	var jb := Time.get_unix_time_from_datetime_dict(db) / DAY_SECONDS
	return int(jb - ja)

func get_streak_days() -> int:
	return int(SaveStore.data["streak_days"])

func is_streak_at_risk() -> bool:
	return int(SaveStore.data["streak_at_risk"]) > 0

func get_streak_at_risk_days() -> int:
	return int(SaveStore.data["streak_at_risk"])

func record_game_play(date_key: String = "") -> void:
	if date_key == "":
		date_key = _today_key()
	var last := String(SaveStore.data["last_play_date"])
	if last == "":
		SaveStore.set_streak_days(1)
		SaveStore.set_last_play_date(date_key)
		SaveStore.set_streak_at_risk(0)
		return
	if last == date_key:
		return
	var delta_days := _days_between(last, date_key)
	if delta_days == 1:
		SaveStore.set_streak_days(get_streak_days() + 1)
		SaveStore.set_last_play_date(date_key)
		SaveStore.set_streak_at_risk(0)
		return
	if delta_days > 1:
		SaveStore.set_streak_at_risk(get_streak_days())
		SaveStore.set_streak_days(0)
		SaveStore.set_last_play_date(date_key)

func apply_rewarded_save(date_key: String = "") -> void:
	if not is_streak_at_risk():
		return
	if date_key == "":
		date_key = _today_key()
	SaveStore.set_streak_days(get_streak_at_risk_days())
	SaveStore.set_streak_at_risk(0)
	SaveStore.set_last_play_date(date_key)
