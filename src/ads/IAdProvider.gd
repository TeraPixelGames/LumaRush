extends RefCounted
class_name IAdProvider

# Mockable interface so tests don't depend on the real SDK.
signal interstitial_loaded
signal interstitial_closed
signal rewarded_loaded
signal rewarded_earned
signal rewarded_closed

func initialize(app_id: String) -> void:
	pass

func load_interstitial(ad_unit_id: String) -> void:
	pass

func load_rewarded(ad_unit_id: String) -> void:
	pass

func show_interstitial(ad_unit_id: String) -> bool:
	return false

func show_rewarded(ad_unit_id: String) -> bool:
	return false
