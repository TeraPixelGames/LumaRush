extends GdUnitTestSuite

func test_ad_cadence_mapping() -> void:
	assert_that(AdCadence.interstitial_every_n_games(0)).is_equal(1)
	assert_that(AdCadence.interstitial_every_n_games(2)).is_equal(2)
	assert_that(AdCadence.interstitial_every_n_games(4)).is_equal(3)
	assert_that(AdCadence.interstitial_every_n_games(8)).is_equal(4)
	assert_that(AdCadence.interstitial_every_n_games(20)).is_equal(5)
