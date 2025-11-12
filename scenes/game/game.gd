class_name Game extends Node

static var instance: Game

static var bgm_playback_pos: float
static var vfx_node: CanvasLayer:
	get: return instance.get_node("%VFX")
static var vfx_front_node: CanvasLayer:
	get: return instance.get_node("%VFXFront")
static var ui_node: CanvasLayer:
	get: return instance.get_node("%UI")

var _menu_scene := load("uid://bsdr2ntqoxu8l")

@onready var _open_button := %OpenButton
@onready var _reset_button := %ResetButton
@onready var _back_button := %BackButton
@onready var _menu_container := %MenuContainer
@onready var _toggle_menu_button := %ToggleMenu
@onready var _fps := %FPS

var _is_menu_shown := true

func play_bgm(fading := 0.0) -> void:
	var bgm := SFX.create(self, [SFX.playlist.wallpaper], {&"volume_db": -8.0}).play_at(bgm_playback_pos).is_bgm()
	if fading != 0.0:
		bgm.fade_in(fading)

func stop_bgm() -> void:
	bgm_playback_pos = SFX.get_sfx(self, [SFX.playlist.wallpaper]).stream_player.get_playback_position() + AudioServer.get_time_since_last_mix()
	SFX.get_sfx(self, [SFX.playlist.wallpaper]).stop()

func _init() -> void:
	instance = self
	ObjectPoolService.clear_all.call_deferred()

func _ready() -> void:
	_back_button.pressed.connect(func():
		SceneManager.change_scene(_menu_scene, false, true, true)
	)
	_open_button.toggled.connect(func(b: bool):
		_hide_menu()
		if Bottle.instance == null:
			return
		if b: Bottle.instance.open_lid()
		else: Bottle.instance.close_lid()
	)
	_reset_button.pressed.connect(func():
		get_tree().reload_current_scene()
	)
	_toggle_menu_button.pressed.connect(func():
		if _is_menu_shown: _hide_menu()
		else: _show_menu()
	)
	
	_fps.visible = App.data.debug_build
		
	WinnerInteractable.static_signals.paper_picked.connect(func(_a, _b): _menu_container.hide())
	WinnerInteractable.static_signals.picture_showed.connect(func(_a, _b): _menu_container.hide())
	WinnerInteractable.static_signals.picture_hidden.connect(func(_a, _b): _menu_container.show())
	
	(func():
		Bottle.instance.paper_passed.connect(func(_paper: Paper):
			Bottle.instance.close_lid()
			_open_button.button_pressed = false
		)
	).call_deferred()
	_hide_menu.call_deferred()
	
	_update_fps()
	play_bgm()
	tree_exiting.connect(stop_bgm)

func _show_menu() -> void:
	if _is_menu_shown:
		return
	AutoTween.new(_menu_container, &"position:y", 0.0, 0.5, Tween.TRANS_BOUNCE)
	GameFX.show_dark_overlay(false, 0.3, 0.3)
	Bottle.enable_input = false
	_toggle_menu_button.text = ""
	_is_menu_shown = true
	_menu_container.mouse_filter = Control.MOUSE_FILTER_STOP

func _hide_menu() -> void:
	if !_is_menu_shown:
		return
	var offset = _menu_container.get_node("PanelContainer").size.y
	AutoTween.new(_menu_container, &"position:y", - offset, 0.8, Tween.TRANS_ELASTIC).from(0.0)
	GameFX.hide_dark_overlay(false, 0.5)
	Bottle.enable_input = true
	_toggle_menu_button.text = ""
	_is_menu_shown = false
	_menu_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _update_fps() -> void:
	_fps.text = "%d FPS" % int(Engine.get_frames_per_second())
	get_tree().create_timer(1.0).timeout.connect(_update_fps)
