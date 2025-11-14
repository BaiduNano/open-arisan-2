extends Node

var _menu_scene := load("uid://bsdr2ntqoxu8l")

@onready var _open_button := %OpenButton
@onready var _reset_button := %ResetButton
@onready var _back_button := %BackButton
@onready var _menu_container := %MenuContainer
@onready var _toggle_menu_button := %ToggleMenu
@onready var _toggle_music_button := %MusicButton

var _is_menu_shown := true

func _ready() -> void:
	_back_button.pressed.connect(func():
		SceneManager.change_scene(_menu_scene, false, true, true)
		SceneManager.half_finished.connect(Game.stop_bgm, CONNECT_ONE_SHOT)
	)
	_open_button.toggled.connect(func(b: bool):
		_hide_menu()
		if Bottle.instance == null:
			return
		if b: Bottle.instance.open_lid()
		else: Bottle.instance.close_lid()
	)
	_reset_button.pressed.connect(func():
		Game.stop_bgm()
		get_tree().reload_current_scene()
	)
	_toggle_menu_button.pressed.connect(func():
		if _is_menu_shown: _hide_menu()
		else: _show_menu()
	)
	_toggle_music_button.pressed.connect(Game.toggle_bgm.bind(_toggle_music_button))
	_toggle_music_button.text = "󰝛" if !Game.is_bgm_on else "󰝚"
		
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
