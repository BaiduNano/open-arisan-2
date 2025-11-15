extends Node

@onready var _grid := %GridContainer

static var _paper_scene: PackedScene = preload("uid://dugdwg88q3hsa")
static var _paper_cont_scene: PackedScene = preload("uid://f285gc3buqk")

func _ready() -> void:
	owner.file_added.connect(_create_paper)
	PaperQueue.data_changed.connect(_toggle_bg)
	
	if !PaperQueue.get_data().is_empty():
		for d in PaperQueue.get_data():
			_create_paper_from_existing(d)
		_toggle_bg()
	_toggle_bg.call_deferred()

func _toggle_bg() -> void:
	if PaperQueue.get_data().is_empty(): %BGCont.modulate.a = 1.0
	else: %BGCont.modulate.a = 0.33

func _create_paper_from_existing(data: Dictionary) -> void:
	var paper := await _create_paper(data.content, false, data.color)
	data.id = paper.get_instance_id()

func _create_paper(data: Variant, append_data := true, color = null) -> Paper:
	var paper: Paper = _paper_scene.instantiate()
	var paper_cont := _paper_cont_scene.instantiate()
	var center_point := paper_cont.get_child(0)
	
	if color != null:
		paper.default_color = color
	else:
		paper.default_color = _get_random_color()

	var queue_data := {
		&"id": paper.get_instance_id(),
		&"content": data if data is not String else await TextToTexture.get_texture_from_text(data),
		&"color": paper.default_color
	}
	
	_grid.add_child(paper_cont)
	center_point.add_child(paper)

	paper.queue_data = queue_data
	paper.owner = paper_cont
	paper.set_physics_process(false)
	paper.freeze = true
	(func(): paper.global_position = center_point.global_position).call_deferred()
	
	if append_data:
		PaperQueue.append_data(queue_data)
	
	return paper

func _get_random_color(saturation: float = 1.0, value: float = 1.0) -> Color:
	var random_hue = randf() 
	return Color.from_hsv(random_hue, saturation, value)
