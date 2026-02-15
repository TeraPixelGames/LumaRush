extends Node

const BOOT_SCENE := "res://src/scenes/Boot.tscn"
const MENU_SCENE := "res://src/scenes/MainMenu.tscn"
const GAME_SCENE := "res://src/scenes/Game.tscn"
const RESULTS_SCENE := "res://src/scenes/Results.tscn"

var last_score := 0

func goto_menu() -> void:
	get_tree().change_scene_to_file(MENU_SCENE)

func start_game() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)

func end_game(score: int) -> void:
	last_score = score
	SaveStore.set_high_score(score)
	NakamaService.submit_score_background(score, {
		"mode": "classic",
		"streak_days": StreakManager.get_streak_days(),
		"games_played": int(SaveStore.data.get("games_played", 0)),
	})
	StreakManager.record_game_play()
	AdManager.on_game_finished()
	get_tree().change_scene_to_file(RESULTS_SCENE)
