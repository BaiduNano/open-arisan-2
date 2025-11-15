class_name App extends Node

static var static_signals := _static_signals.new()

static var data: Dictionary:
	get: return {
	"name": ProjectSettings.get_setting("application/config/name"),
	"name_localized": ProjectSettings.get_setting("application/config/name_localized"),
	"description": ProjectSettings.get_setting("application/config/description"),
	"version": ProjectSettings.get_setting("application/config/version"),
	"platform": OS.get_name().to_lower(),
	"debug_build": OS.is_debug_build() and !OS.get_name().contains("Web"),
	"web_build": OS.get_name().contains("Web"),
	"android_build": OS.get_name().contains("Android"),
	"lang": TranslationServer.get_locale()
}

class _static_signals:
	@warning_ignore("unused_signal")
	signal locale_changed

var _next_scene := load("uid://dlkw23a56je3m")

func _ready() -> void:
	## request access so it can load the images properly
	if data.android_build:
		OS.request_permissions()
	
	SceneManager.change_scene.call_deferred(_next_scene, true)
