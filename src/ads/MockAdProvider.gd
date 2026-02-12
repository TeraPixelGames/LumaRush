extends IAdProvider
class_name MockAdProvider

var interstitial_ready := true
var rewarded_ready := true

func initialize(app_id: String) -> void:
	pass

func load_interstitial(ad_unit_id: String) -> void:
	interstitial_ready = true
	emit_signal("interstitial_loaded")

func load_rewarded(ad_unit_id: String) -> void:
	rewarded_ready = true
	emit_signal("rewarded_loaded")

func show_interstitial(ad_unit_id: String) -> bool:
	if not interstitial_ready:
		return false
	interstitial_ready = false
	call_deferred("_emit_interstitial_closed")
	return true

func show_rewarded(ad_unit_id: String) -> bool:
	if not rewarded_ready:
		return false
	rewarded_ready = false
	call_deferred("_emit_rewarded_earned")
	call_deferred("_emit_rewarded_closed")
	return true

func _emit_interstitial_closed() -> void:
	emit_signal("interstitial_closed")

func _emit_rewarded_earned() -> void:
	emit_signal("rewarded_earned")

func _emit_rewarded_closed() -> void:
	emit_signal("rewarded_closed")
