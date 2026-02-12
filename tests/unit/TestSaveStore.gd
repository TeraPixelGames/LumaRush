extends GdUnitTestSuite

func test_clear_high_score_resets_to_zero() -> void:
	var original: int = int(SaveStore.data["high_score"])
	SaveStore.data["high_score"] = 1234
	SaveStore.clear_high_score()
	assert_that(int(SaveStore.data["high_score"])).is_equal(0)
	SaveStore.data["high_score"] = original

func test_set_selected_track_id_persists() -> void:
	var original: String = str(SaveStore.data.get("selected_track_id", "glassgrid"))
	SaveStore.set_selected_track_id("off")
	assert_that(str(SaveStore.data["selected_track_id"])).is_equal("off")
	SaveStore.set_selected_track_id(original)
