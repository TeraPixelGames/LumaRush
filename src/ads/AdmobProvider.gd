extends Node
class_name AdmobProvider

signal interstitial_loaded
signal interstitial_closed
signal rewarded_loaded
signal rewarded_earned
signal rewarded_closed

const ANDROID_DEBUG_APP_ID: String = "ca-app-pub-3940256099942544~3347511713"
const ANDROID_DEBUG_INTERSTITIAL_ID: String = "ca-app-pub-3940256099942544/1033173712"
const ANDROID_DEBUG_REWARDED_ID: String = "ca-app-pub-3940256099942544/5224354917"
const IOS_DEBUG_APP_ID: String = "ca-app-pub-3940256099942544~1458002511"
const IOS_DEBUG_INTERSTITIAL_ID: String = "ca-app-pub-3940256099942544/4411468910"
const IOS_DEBUG_REWARDED_ID: String = "ca-app-pub-3940256099942544/1712485313"

var admob: Node
var _interstitial_id: String = ""
var _rewarded_id: String = ""
var _last_interstitial_ad_id: String = ""
var _last_rewarded_ad_id: String = ""
var _interstitial_failed_attempts: int = 0
var _rewarded_failed_attempts: int = 0
var _interstitial_retry_scheduled: bool = false
var _rewarded_retry_scheduled: bool = false
var _initialized: bool = false
var _pending_interstitial_load: bool = false
var _pending_rewarded_load: bool = false

func configure(app_id: String, interstitial_id: String, rewarded_id: String) -> void:
	_interstitial_id = interstitial_id
	_rewarded_id = rewarded_id
	var admob_script: Script = load("res://addons/AdmobPlugin/Admob.gd") as Script
	if admob_script == null:
		admob_script = load("res://addons/godot-admob/addon/src/Admob.gd") as Script
	if admob_script == null:
		push_error("AdmobProvider: failed to load Admob.gd from known addon paths.")
		return
	admob = admob_script.new()
	var force_real: bool = bool(ProjectSettings.get_setting("lumarush/ads_force_real", false))
	_set_if_exists(admob, "is_real", force_real or (not OS.is_debug_build()))
	_set_if_exists(admob, "android_real_application_id", app_id)
	_set_if_exists(admob, "ios_real_application_id", app_id)
	_set_if_exists(admob, "android_debug_application_id", ANDROID_DEBUG_APP_ID)
	_set_if_exists(admob, "ios_debug_application_id", IOS_DEBUG_APP_ID)
	_set_if_exists(admob, "android_real_interstitial_id", interstitial_id)
	_set_if_exists(admob, "ios_real_interstitial_id", interstitial_id)
	_set_if_exists(admob, "android_debug_interstitial_id", ANDROID_DEBUG_INTERSTITIAL_ID)
	_set_if_exists(admob, "ios_debug_interstitial_id", IOS_DEBUG_INTERSTITIAL_ID)
	_set_if_exists(admob, "android_real_rewarded_id", rewarded_id)
	_set_if_exists(admob, "ios_real_rewarded_id", rewarded_id)
	_set_if_exists(admob, "android_debug_rewarded_id", ANDROID_DEBUG_REWARDED_ID)
	_set_if_exists(admob, "ios_debug_rewarded_id", IOS_DEBUG_REWARDED_ID)
	_set_if_exists(admob, "real_application_id", app_id)
	_set_if_exists(admob, "real_interstitial_id", interstitial_id)
	_set_if_exists(admob, "real_rewarded_id", rewarded_id)
	_set_if_exists(admob, "debug_application_id", ANDROID_DEBUG_APP_ID)
	_set_if_exists(admob, "debug_interstitial_id", ANDROID_DEBUG_INTERSTITIAL_ID)
	_set_if_exists(admob, "debug_rewarded_id", ANDROID_DEBUG_REWARDED_ID)
	add_child(admob)
	push_warning("AdmobProvider: configured Admob node (is_real=%s)." % str(admob.get("is_real")))
	admob.connect("initialization_completed", Callable(self, "_on_initialized"))
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
		if not _initialized:
			_pending_interstitial_load = true
			return
		admob.load_interstitial_ad()

func load_rewarded(ad_unit_id: String) -> void:
	if admob:
		if not _initialized:
			_pending_rewarded_load = true
			return
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

func _on_interstitial_loaded(ad_info, _response_info = null) -> void:
	_last_interstitial_ad_id = _resolve_ad_id(ad_info)
	_interstitial_failed_attempts = 0
	_interstitial_retry_scheduled = false
	emit_signal("interstitial_loaded")

func _on_interstitial_failed_to_load(_ad_info, _error_data) -> void:
	_last_interstitial_ad_id = ""
	var reason: String = "unknown"
	if _error_data is Object:
		if _error_data.has_method("get_code"):
			reason = "code=%s" % str(_error_data.call("get_code"))
		if _error_data.has_method("get_message"):
			reason += " message=%s" % str(_error_data.call("get_message"))
	push_warning("AdmobProvider: interstitial failed to load (%s)." % reason)
	_schedule_interstitial_retry()

func _on_interstitial_closed(_ad_info) -> void:
	emit_signal("interstitial_closed")
	_last_interstitial_ad_id = ""
	_interstitial_failed_attempts = 0
	_interstitial_retry_scheduled = false
	admob.load_interstitial_ad()

func _on_rewarded_loaded(ad_info, _response_info = null) -> void:
	_last_rewarded_ad_id = _resolve_ad_id(ad_info)
	_rewarded_failed_attempts = 0
	_rewarded_retry_scheduled = false
	emit_signal("rewarded_loaded")

func _on_rewarded_failed_to_load(_ad_info, _error_data) -> void:
	_last_rewarded_ad_id = ""
	var reason: String = "unknown"
	if _error_data is Object:
		if _error_data.has_method("get_code"):
			reason = "code=%s" % str(_error_data.call("get_code"))
		if _error_data.has_method("get_message"):
			reason += " message=%s" % str(_error_data.call("get_message"))
	push_warning("AdmobProvider: rewarded failed to load (%s)." % reason)
	_schedule_rewarded_retry()

func _on_rewarded_earned(_ad_info, _reward_data) -> void:
	emit_signal("rewarded_earned")

func _on_rewarded_closed(_ad_info) -> void:
	emit_signal("rewarded_closed")
	_last_rewarded_ad_id = ""
	_rewarded_failed_attempts = 0
	_rewarded_retry_scheduled = false
	admob.load_rewarded_ad()

func _on_initialized(_status_data = null) -> void:
	_initialized = true
	if _pending_interstitial_load:
		_pending_interstitial_load = false
		admob.load_interstitial_ad()
	if _pending_rewarded_load:
		_pending_rewarded_load = false
		admob.load_rewarded_ad()

func _set_if_exists(target: Object, property_name: String, value: Variant) -> void:
	for property_data in target.get_property_list():
		if String(property_data.get("name", "")) == property_name:
			target.set(property_name, value)
			return

func _resolve_ad_id(ad_info: Variant) -> String:
	if ad_info is String:
		return ad_info
	if ad_info is Object and ad_info.has_method("get_ad_id"):
		return String(ad_info.call("get_ad_id"))
	return ""

func _schedule_interstitial_retry() -> void:
	if _interstitial_retry_scheduled:
		return
	var max_attempts: int = FeatureFlags.ad_retry_attempts()
	if _interstitial_failed_attempts >= max_attempts:
		return
	_interstitial_failed_attempts += 1
	_interstitial_retry_scheduled = true
	_retry_interstitial_after_delay()

func _schedule_rewarded_retry() -> void:
	if _rewarded_retry_scheduled:
		return
	var max_attempts: int = FeatureFlags.ad_retry_attempts()
	if _rewarded_failed_attempts >= max_attempts:
		return
	_rewarded_failed_attempts += 1
	_rewarded_retry_scheduled = true
	_retry_rewarded_after_delay()

func _retry_interstitial_after_delay() -> void:
	await get_tree().create_timer(FeatureFlags.ad_retry_interval_seconds()).timeout
	_interstitial_retry_scheduled = false
	if admob != null and _last_interstitial_ad_id == "":
		admob.load_interstitial_ad()

func _retry_rewarded_after_delay() -> void:
	await get_tree().create_timer(FeatureFlags.ad_retry_interval_seconds()).timeout
	_rewarded_retry_scheduled = false
	if admob != null and _last_rewarded_ad_id == "":
		admob.load_rewarded_ad()
