extends Node

signal rewarded_earned
signal rewarded_closed

const APP_ID := "ca-app-pub-8413230766502262~8459082393"
const INTERSTITIAL_ID := "ca-app-pub-8413230766502262/4097057758"
const REWARDED_ID := "ca-app-pub-8413230766502262/8662262377"

var provider: Object

func _ready() -> void:
	_initialize_provider()

func _initialize_provider() -> void:
	var use_mock: bool = bool(ProjectSettings.get_setting("lumarush/use_mock_ads", Engine.is_editor_hint()))
	if not ClassDB.class_exists("Admob"):
		use_mock = true
	if use_mock:
		provider = MockAdProvider.new()
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
	var n := AdCadence.interstitial_every_n_games(StreakManager.get_streak_days())
	if n <= 0:
		return
	if games % n != 0:
		return
	if provider.show_interstitial(INTERSTITIAL_ID):
		MusicManager.set_ads_ducked(true)
		MusicManager.set_ads_paused(true)

func show_rewarded_for_save() -> bool:
	var shown: bool = provider.show_rewarded(REWARDED_ID)
	if shown:
		MusicManager.set_ads_ducked(true)
		MusicManager.set_ads_paused(true)
	return shown

func _on_interstitial_loaded() -> void:
	pass

func _on_interstitial_closed() -> void:
	MusicManager.set_ads_paused(false)
	MusicManager.set_ads_ducked(false)

func _on_rewarded_loaded() -> void:
	pass

func _on_rewarded_earned() -> void:
	StreakManager.apply_rewarded_save()
	emit_signal("rewarded_earned")

func _on_rewarded_closed() -> void:
	MusicManager.set_ads_paused(false)
	MusicManager.set_ads_ducked(false)
	emit_signal("rewarded_closed")
