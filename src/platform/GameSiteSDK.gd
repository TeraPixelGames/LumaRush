extends Node

# Optional platform bridge stub used by autoload configuration.
# Implement provider-specific integrations here when needed.

func is_available() -> bool:
	return false

func get_provider_name() -> String:
	return "none"

func get_user_id() -> String:
	return ""

func get_display_name() -> String:
	return ""
