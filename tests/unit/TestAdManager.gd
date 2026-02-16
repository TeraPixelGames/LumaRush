extends GdUnitTestSuite

class FakeProvider:
	extends Node
	signal interstitial_loaded
	signal interstitial_closed
	signal rewarded_loaded
	signal rewarded_earned
	signal rewarded_closed

	var interstitial_load_calls: int = 0
	var interstitial_show_calls: int = 0
	var rewarded_load_calls: int = 0
	var rewarded_show_calls: int = 0
	var interstitial_ready_after_loads: int = 1
	var rewarded_ready_after_loads: int = 1

	func load_interstitial(_ad_unit_id: String) -> void:
		interstitial_load_calls += 1
		if interstitial_load_calls >= interstitial_ready_after_loads:
			emit_signal("interstitial_loaded")

	func load_rewarded(_ad_unit_id: String) -> void:
		rewarded_load_calls += 1
		if rewarded_load_calls >= rewarded_ready_after_loads:
			emit_signal("rewarded_loaded")

	func show_interstitial(_ad_unit_id: String) -> bool:
		interstitial_show_calls += 1
		return interstitial_load_calls >= interstitial_ready_after_loads

	func show_rewarded(_ad_unit_id: String) -> bool:
		rewarded_show_calls += 1
		return rewarded_load_calls >= rewarded_ready_after_loads


class TestAdManagerNode:
	extends "res://src/ads/AdManager.gd"

	func _initialize_provider_async() -> void:
		pass


func before() -> void:
	ProjectSettings.set_setting("lumarush/ad_retry_attempts", 2)
	ProjectSettings.set_setting("lumarush/ad_retry_interval_seconds", 0.05)
	SaveStore.data["games_played"] = 1
	SaveStore.data["streak_days"] = 0

func test_interstitial_retries_load_and_show() -> void:
	var manager := TestAdManagerNode.new()
	var provider := FakeProvider.new()
	provider.interstitial_ready_after_loads = 2
	get_tree().root.add_child(manager)
	manager.provider = provider
	get_tree().root.add_child(provider)
	manager._start_interstitial_retry(1)
	await get_tree().create_timer(0.18).timeout
	assert_that(provider.interstitial_load_calls).is_greater_equal(2)
	assert_that(provider.interstitial_show_calls).is_greater_equal(1)
	assert_that(manager._last_interstitial_shown_games_played).is_equal(1)
	manager.queue_free()
	provider.queue_free()

func test_rewarded_retries_load_and_show() -> void:
	var manager := TestAdManagerNode.new()
	var provider := FakeProvider.new()
	provider.rewarded_ready_after_loads = 2
	get_tree().root.add_child(manager)
	manager.provider = provider
	get_tree().root.add_child(provider)
	var queued: bool = manager.show_rewarded_for_save()
	assert_that(queued).is_true()
	await get_tree().create_timer(0.18).timeout
	assert_that(provider.rewarded_load_calls).is_greater_equal(2)
	assert_that(provider.rewarded_show_calls).is_greater_equal(1)
	manager.queue_free()
	provider.queue_free()

func test_rewarded_powerup_emits_powerup_signal() -> void:
	var manager := TestAdManagerNode.new()
	var provider := FakeProvider.new()
	provider.rewarded_ready_after_loads = 1
	get_tree().root.add_child(manager)
	manager.provider = provider
	get_tree().root.add_child(provider)
	var powerup_earned: Array[bool] = [false]
	var save_earned: Array[bool] = [false]
	manager.connect("rewarded_powerup_earned", func() -> void:
		powerup_earned[0] = true
	)
	manager.connect("rewarded_earned", func() -> void:
		save_earned[0] = true
	)
	assert_that(manager.show_rewarded_for_powerup()).is_true()
	manager._on_rewarded_earned()
	assert_that(powerup_earned[0]).is_true()
	assert_that(save_earned[0]).is_false()
	manager.queue_free()
	provider.queue_free()

func test_rewarded_retry_exhausted_emits_closed() -> void:
	var manager := TestAdManagerNode.new()
	var provider := FakeProvider.new()
	provider.rewarded_ready_after_loads = 99
	get_tree().root.add_child(manager)
	manager.provider = provider
	get_tree().root.add_child(provider)
	var closed_count: Array[int] = [0]
	manager.connect("rewarded_closed", func() -> void:
		closed_count[0] += 1
	)
	assert_that(manager.show_rewarded_for_powerup()).is_true()
	await get_tree().create_timer(0.18).timeout
	assert_that(closed_count[0]).is_equal(1)
	manager.queue_free()
	provider.queue_free()
