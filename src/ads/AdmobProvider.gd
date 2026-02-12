extends Node
class_name AdmobProvider

signal interstitial_loaded
signal interstitial_closed
signal rewarded_loaded
signal rewarded_earned
signal rewarded_closed

var admob: Node
var _interstitial_id: String = ""
var _rewarded_id: String = ""
var _last_interstitial_ad_id: String = ""
var _last_rewarded_ad_id: String = ""

func configure(app_id: String, interstitial_id: String, rewarded_id: String) -> void:
	_interstitial_id = interstitial_id
	_rewarded_id = rewarded_id
	var admob_script := load("res://addons/godot-admob/addon/src/Admob.gd")
	if admob_script == null:
		return
	admob = admob_script.new()
	var force_real: bool = bool(ProjectSettings.get_setting("lumarush/ads_force_real", false))
	admob.is_real = force_real or (not OS.is_debug_build())
	admob.android_real_application_id = app_id
	admob.ios_real_application_id = app_id
	admob.android_real_interstitial_id = interstitial_id
	admob.ios_real_interstitial_id = interstitial_id
	admob.android_real_rewarded_id = rewarded_id
	admob.ios_real_rewarded_id = rewarded_id
	add_child(admob)
	admob.connect("interstitial_ad_loaded", Callable(self, "_on_interstitial_loaded"))
	admob.connect("interstitial_ad_failed_to_load", Callable(self, "_on_interstitial_failed_to_load"))
	admob.connect("interstitial_ad_dismissed_full_screen_content", Callable(self, "_on_interstitial_closed"))
	admob.connect("rewarded_ad_loaded", Callable(self, "_on_rewarded_loaded"))
	admob.connect("rewarded_ad_failed_to_load", Callable(self, "_on_rewarded_failed_to_load"))
	admob.connect("rewarded_ad_user_earned_reward", Callable(self, "_on_rewarded_earned"))
	admob.connect("rewarded_ad_dismissed_full_screen_content", Callable(self, "_on_rewarded_closed"))
	admob.initialize()

func initialize(app_id: String) -> void:
	# No-op; configure() should be used.
	pass

func load_interstitial(ad_unit_id: String) -> void:
	if admob:
		admob.load_interstitial_ad()

func load_rewarded(ad_unit_id: String) -> void:
	if admob:
		admob.load_rewarded_ad()

func show_interstitial(ad_unit_id: String) -> bool:
	if admob == null:
		return false
	if _last_interstitial_ad_id == "":
		return false
	admob.show_interstitial_ad(_last_interstitial_ad_id)
	return true

func show_rewarded(ad_unit_id: String) -> bool:
	if admob == null:
		return false
	if _last_rewarded_ad_id == "":
		return false
	admob.show_rewarded_ad(_last_rewarded_ad_id)
	return true

func is_interstitial_ready() -> bool:
	return _last_interstitial_ad_id != ""

func is_rewarded_ready() -> bool:
	return _last_rewarded_ad_id != ""

func _on_interstitial_loaded(ad_info, _response_info) -> void:
	_last_interstitial_ad_id = ad_info.get_ad_id()
	emit_signal("interstitial_loaded")

func _on_interstitial_failed_to_load(_ad_info, _error_data) -> void:
	_last_interstitial_ad_id = ""
	push_warning("AdmobProvider: interstitial failed to load.")

func _on_interstitial_closed(_ad_info) -> void:
	emit_signal("interstitial_closed")
	_last_interstitial_ad_id = ""
	admob.load_interstitial_ad()

func _on_rewarded_loaded(ad_info, _response_info) -> void:
	_last_rewarded_ad_id = ad_info.get_ad_id()
	emit_signal("rewarded_loaded")

func _on_rewarded_failed_to_load(_ad_info, _error_data) -> void:
	_last_rewarded_ad_id = ""
	push_warning("AdmobProvider: rewarded failed to load.")

func _on_rewarded_earned(_ad_info, _reward_data) -> void:
	emit_signal("rewarded_earned")

func _on_rewarded_closed(_ad_info) -> void:
	emit_signal("rewarded_closed")
	_last_rewarded_ad_id = ""
	admob.load_rewarded_ad()
