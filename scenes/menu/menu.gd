class_name MainMenu extends Node

@warning_ignore("unused_signal")
signal progress(current_bytes: int, total_bytes: int)
@warning_ignore("unused_signal")
signal file_added(data: Variant)
@warning_ignore("unused_signal")
signal spawn_file_picker

static var instance: MainMenu
static var ui_node: CanvasLayer:
	get: return instance.get_node("%UI")
static var init := true

@onready var _ammount := %Ammount
@onready var _start_button := %StartButton
@onready var _clear_button := %ClearButton
@onready var _version := %Version
@onready var _toggle_music_button := %MusicButton
@onready var _add_button: Button = %AddButton
@onready var _lang_button: TextureButton = %LangButton

@onready var _bg_en := %BGEN
@onready var _bg_id := %BGID

const _en_image := preload("uid://gvqd53busr5v")
const _id_image := preload("uid://dm3okcux6wlug")

var _game_scene: PackedScene = load("uid://b5q4vk5sol5pb")
var _add_item_selector_scene: PackedScene = load("uid://cnidevfjqc057")
var _language_selector_scene: PackedScene = load("uid://c004qtx7xn717")

func _init() -> void:
	instance = self

func _ready() -> void:
	_start_button.pressed.connect(func():
		SceneManager.change_scene(_game_scene, false, true)
	)
	_clear_button.pressed.connect(func():
		var text := "Yakin?" if App.data.lang != "en" else "Are you sure?"
		var alert := Alert.create(text)
		alert.yes.pressed.connect(func():
			for d in PaperQueue.get_data():
				var paper = instance_from_id(d.id)
				paper.queue_free()
				PaperQueue.erase_data.call_deferred(d)
			alert.exit.call_deferred()
		)
	)
	_toggle_music_button.pressed.connect(func():
		Game.is_bgm_on = !Game.is_bgm_on
		_toggle_music_button.text = "󰝛" if !Game.is_bgm_on else "󰝚"
		Audio.set_bgm_vol(0.0 if !Game.is_bgm_on else 100.0)
	)
	_add_button.pressed.connect(func():
		# Forces to open file picker to display Error if the size reaches maximum
		# TODO: Better way to do this?
		if PaperQueue.get_data().size() >= %DataImporter.MAX_SIZE:
			spawn_file_picker.emit()
		else:
			ui_node.add_child(_add_item_selector_scene.instantiate())
	)
	_lang_button.pressed.connect(func():
		ui_node.add_child(_language_selector_scene.instantiate())
	)
	_version.text = "MyArisan 2 - v%s" % App.data.version
	_toggle_music_button.text = "󰝛" if !Game.is_bgm_on else "󰝚"
	
	get_tree().create_timer(0.1).timeout.connect(func():
		if !init:
			return
		Audio.set_master_vol(100.0)
		SFX.create(self, [SFX.playlist.wallpaper], {&"volume_db": -8.0})
		_lang_button.pressed.emit()
		init = false
	)
	App.static_signals.locale_changed.connect(func():
		for b in [_bg_en, _bg_id]: b.hide()
		if App.data.lang == "id": _bg_id.show()
		else: _bg_en.show()
		match App.data.lang:
			"en":
				_lang_button.texture_normal = _en_image
			"id", "id2":
				_lang_button.texture_normal = _id_image
	)
	App.static_signals.locale_changed.emit.call_deferred()
	PaperQueue.data_changed.connect(func():
		_clear_button.disabled = PaperQueue.get_data().is_empty()
		_start_button.disabled = PaperQueue.get_data().is_empty()
		if !PaperQueue.get_data().is_empty(): _ammount.text = ("Peserta: %d" if App.data.lang != "en" else "Participants: %d") % PaperQueue.get_data().size()
		else: _ammount.text = ""
	)
	PaperQueue.data_changed.emit.call_deferred()
	SFX.create(self, [SFX.playlist.wallpaper], {&"volume_db": -8.0}).play_at(Game.bgm_playback_pos).is_bgm()
	SceneManager.half_finished.connect(func():
		Game.bgm_playback_pos = SFX.get_sfx(self, [SFX.playlist.wallpaper]).stream_player.get_playback_position() + AudioServer.get_time_since_last_mix()
		,CONNECT_ONE_SHOT
	)
