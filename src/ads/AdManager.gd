extends Node

signal rewarded_earned
signal rewarded_closed

const APP_ID := "ca-app-pub-8413230766502262~8459082393"
const INTERSTITIAL_ID := "ca-app-pub-8413230766502262/4097057758"
const REWARDED_ID := "ca-app-pub-8413230766502262/8662262377"

var provider: Object
var _last_interstitial_shown_games_played: int = -1
var _interstitial_retry_active: bool = false
var _interstitial_retry_game_count: int = -1
var _rewarded_retry_active: bool = false

func _ready() -> void:
	_initialize_provider()

func _initialize_provider() -> void:
	var use_mock: bool = bool(ProjectSettings.get_setting("lumarush/use_mock_ads", Engine.is_editor_hint()))
	if not Engine.has_singleton("AdmobPlugin"):
		use_mock = true
	if use_mock:
		provider = MockAdProvider.new()
		push_warning("AdManager: using MockAdProvider (AdmobPlugin singleton unavailable or mock forced).")
	else:
		provider = AdmobProvider.new()
		add_child(provider)
		provider.configure(APP_ID, INTERSTITIAL_ID, REWARDED_ID)
	provider.connect("interstitial_loaded", Callable(self, "_on_interstitial_loaded"))
	provider.connect("interstitial_closed", Callable(self, "_on_interstitial_closed"))
	provider.connect("rewarded_loaded", Callable(self, "_on_rewarded_loaded"))
	provider.connect("rewarded_earned", Callable(self, "_on_rewarded_earned"))
	provider.connect("rewarded_closed", Callable(self, "_on_rewarded_closed"))
	provider.load_interstitial(INTERSTITIAL_ID)
	provider.load_rewarded(REWARDED_ID)

func on_game_finished() -> void:
	SaveStore.increment_games_played()
	maybe_show_interstitial()

func maybe_show_interstitial() -> void:
	var games := int(SaveStore.data["games_played"])
	if _last_interstitial_shown_games_played == games:
		return
	var n := AdCadence.interstitial_every_n_games(StreakManager.get_streak_days())
	if n <= 0:
		return
	if games % n != 0:
		return
	if _show_interstitial_now(games):
		return
	_start_interstitial_retry(games)

func show_rewarded_for_save() -> bool:
	if _show_rewarded_now():
		return true
	return _start_rewarded_retry()

func _on_interstitial_loaded() -> void:
	if _interstitial_retry_active:
		_show_interstitial_now(_interstitial_retry_game_count)

func _on_interstitial_closed() -> void:
	MusicManager.set_ads_paused(false)
	MusicManager.set_ads_ducked(false)
	_interstitial_retry_active = false
	_interstitial_retry_game_count = -1

func _on_rewarded_loaded() -> void:
	if _rewarded_retry_active:
		_show_rewarded_now()

func _on_rewarded_earned() -> void:
	StreakManager.apply_rewarded_save()
	emit_signal("rewarded_earned")

func _on_rewarded_closed() -> void:
	MusicManager.set_ads_paused(false)
	MusicManager.set_ads_ducked(false)
	_rewarded_retry_active = false
	emit_signal("rewarded_closed")

func _show_interstitial_now(games: int) -> bool:
	if provider.show_interstitial(INTERSTITIAL_ID):
		_last_interstitial_shown_games_played = games
		_interstitial_retry_active = false
		_interstitial_retry_game_count = -1
		MusicManager.set_ads_ducked(true)
		MusicManager.set_ads_paused(true)
		return true
	return false

func _show_rewarded_now() -> bool:
	var shown: bool = provider.show_rewarded(REWARDED_ID)
	if shown:
		_rewarded_retry_active = false
		MusicManager.set_ads_ducked(true)
		MusicManager.set_ads_paused(true)
	return shown

func _start_interstitial_retry(games: int) -> void:
	if _interstitial_retry_active:
		return
	var retries: int = FeatureFlags.ad_retry_attempts()
	if retries <= 0:
		push_warning("AdManager: interstitial opportunity missed (ad not ready).")
		return
	_interstitial_retry_active = true
	_interstitial_retry_game_count = games
	_retry_interstitial_async(games, retries)

func _start_rewarded_retry() -> bool:
	if _rewarded_retry_active:
		return true
	var retries: int = FeatureFlags.ad_retry_attempts()
	if retries <= 0:
		return false
	_rewarded_retry_active = true
	_retry_rewarded_async(retries)
	return true

func _retry_interstitial_async(games: int, retries_left: int) -> void:
	while _interstitial_retry_active and retries_left > 0 and _last_interstitial_shown_games_played != games:
		provider.load_interstitial(INTERSTITIAL_ID)
		await get_tree().create_timer(FeatureFlags.ad_retry_interval_seconds()).timeout
		if _show_interstitial_now(games):
			return
		retries_left -= 1
	if _interstitial_retry_active and _last_interstitial_shown_games_played != games:
		push_warning("AdManager: interstitial retries exhausted.")
	_interstitial_retry_active = false
	_interstitial_retry_game_count = -1

func _retry_rewarded_async(retries_left: int) -> void:
	while _rewarded_retry_active and retries_left > 0:
		provider.load_rewarded(REWARDED_ID)
		await get_tree().create_timer(FeatureFlags.ad_retry_interval_seconds()).timeout
		if _show_rewarded_now():
			return
		retries_left -= 1
	_rewarded_retry_active = false
