class_name App extends Node

static var data := {
	"name": ProjectSettings.get_setting("application/config/name"),
	"name_localized": ProjectSettings.get_setting("application/config/name_localized"),
	"description": ProjectSettings.get_setting("application/config/description"),
	"version": ProjectSettings.get_setting("application/config/version"),
	"platform": OS.get_name().to_lower(),
	"debug_build": OS.is_debug_build() and !OS.get_name().contains("Web"),
	"web_build": OS.get_name().contains("Web"),
	"android_build": OS.get_name().contains("Android"),
}

const NEXT_SCENE := preload("uid://dlkw23a56je3m")

func _ready() -> void:
	SceneManager.change_scene.call_deferred(NEXT_SCENE, true)
