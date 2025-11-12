class_name MainMenu extends Node

const GRID_SMALL := 3
const GRID_MEDIUM := 5
const GRID_LARGE := 7
const GRID_JUMBO := 10

const ASPECT_SMALL := 0.7
const ASPECT_MEDIUM := 1.4
const ASPECT_LARGE := 2.0

@warning_ignore("unused_signal")
signal progress(current_bytes: int, total_bytes: int)
signal file_added(data: Variant)

static var instance: MainMenu
static var ui_node: CanvasLayer:
	get: return instance.get_node("%UI")
	
static var _paper_scene: PackedScene = preload("uid://dugdwg88q3hsa")
static var _paper_cont_scene: PackedScene = preload("uid://f285gc3buqk")

@onready var _grid := %GridContainer
@onready var _start_button := %StartButton
@onready var _clear_button := %ClearButton
@onready var _down_cont := %DownVBoxContainer
@onready var _top_mask := %TopMask
@onready var _ammount := %Ammount

var _game_scene: PackedScene = load("uid://b5q4vk5sol5pb")
var _init_down_pos_y: float

func _init() -> void:
	instance = self

func _ready() -> void:
	file_added.connect(_create_object)
	get_viewport().size_changed.connect(_update_grid)
	_top_mask.hide()
	_update_grid.call_deferred()
	_start_button.pressed.connect(func():
		SceneManager.change_scene(_game_scene, false, true)
	)
	_clear_button.pressed.connect(func():
		var alert := Alert.create("Yakin?")
		alert.yes.pressed.connect(func():
			for d in PaperQueue.get_data():
				var paper = instance_from_id(d.id)
				paper.queue_free()
				PaperQueue.erase_data.call_deferred(d)
			alert.exit.call_deferred()
		)
	)
	
	(func(): _init_down_pos_y = _down_cont.position.y).call_deferred()
	
	var toggle_bg = func():
		if PaperQueue.get_data().is_empty(): %BG.modulate.a = 1.0
		else: %BG.modulate.a = 0.33
	
	PaperQueue.data_changed.connect(toggle_bg)
	PaperQueue.data_changed.connect(func():
		if !PaperQueue.get_data().is_empty(): _ammount.text = "Peserta: %d" % PaperQueue.get_data().size()
		else: _ammount.text = ""
	)
	PaperQueue.data_changed.emit()
	
	UIPreviewer.static_signal.previewer_toggled.connect(func(b: bool):
		AutoTween.new(_down_cont, &"position:y", _init_down_pos_y + 162.0 if b else _init_down_pos_y)
	)
	UIPaperContainer.inspector_signals.inspector_activated.connect(func():
		_top_mask.show()
		_top_mask.mouse_filter = Control.MouseFilter.MOUSE_FILTER_STOP
		AutoTween.new(_top_mask, &"modulate:a", 1.0, 0.5)
	)
	UIPaperContainer.inspector_signals.inspector_deactivated.connect(func():
		_top_mask.mouse_filter = Control.MouseFilter.MOUSE_FILTER_IGNORE
		AutoTween.new(_top_mask, &"modulate:a", 0.0, 0.5).finished.connect(_top_mask.hide)
	)
	if !PaperQueue.get_data().is_empty():
		for i in range(PaperQueue.get_data().size()):
			_create_object_from_existing(PaperQueue.get_data()[i], i)
		toggle_bg.call()
		
	SFX.create(self, [SFX.playlist.wallpaper], {&"volume_db": -8.0}).play_at(Game.bgm_playback_pos).is_bgm()
	tree_exiting.connect(func():
		Game.bgm_playback_pos = SFX.get_sfx(self, [SFX.playlist.wallpaper]).stream_player.get_playback_position() + AudioServer.get_time_since_last_mix()
	)

func _create_object_from_existing(data: Dictionary, index: int) -> void:
	var paper := _create_object(data.content, false, data.color)
	PaperQueue.get_data()[index].id = paper.get_instance_id()

func _create_object(data: Variant, append_data := true, color = null) -> Paper:
	var paper: Paper = _paper_scene.instantiate()
	var type := PaperQueue.TYPE.TEXTURE if data is ImageTexture else PaperQueue.TYPE.STRING
	var paper_cont := _paper_cont_scene.instantiate()
	var center_point := paper_cont.get_child(0)
	
	if color != null:
		paper.default_color = color
	
	_grid.add_child(paper_cont)
	center_point.add_child(paper)
	
	var queue_data := {
		&"id": paper.get_instance_id(),
		&"type": type,
		&"content": data,
		&"color": paper.default_color
	}
	
	paper.queue_data = queue_data
	paper.owner = paper_cont
	paper.set_physics_process(false)
	paper.freeze = true
	
	if append_data:
		PaperQueue.append_data(queue_data)
	
	return paper

func _update_grid() -> void:
	var aspect := float(get_tree().root.size.x) / float(get_tree().root.size.y)
	
	if aspect <= ASPECT_SMALL:
		_grid.columns = GRID_SMALL
	elif aspect <= ASPECT_MEDIUM:
		_grid.columns = GRID_MEDIUM
	elif aspect <= ASPECT_LARGE:
		_grid.columns = GRID_LARGE
	else:
		_grid.columns = GRID_JUMBO
