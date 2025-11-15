class_name GameFX extends Node

static var dark_overlay: ColorRect:
	get: return Game.instance.get_node("%DarkOverlay")
static var motion_blur: Node:
	get: return Game.instance.get_node("Modules/MotionBlur")

static func show_dark_overlay(instant := false, modulate := 0.6, duration := 1.0, transition := Tween.TRANS_SINE) -> void:
	dark_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	dark_overlay.show()
	if instant: dark_overlay.modulate.a = modulate
	else: AutoTween.new(dark_overlay, &"modulate:a", modulate, duration, transition)

static func hide_dark_overlay(instant := false, duration := 1.0, transition := Tween.TRANS_SINE) -> void:
	dark_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if instant: dark_overlay.modulate.a = 0.0; dark_overlay.hide()
	else: AutoTween.new(dark_overlay, &"modulate:a", 0.0, duration, transition).finished.connect(dark_overlay.hide)

static func enable_motion_blur() -> void:
	if App.data.android_build:
		motion_blur.activate()

static func disable_motion_blur() -> void:
	motion_blur.deactivate()

func _ready() -> void:
	hide_dark_overlay(true)
