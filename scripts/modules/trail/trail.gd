class_name Trail extends Line2D

const META := &"trail"

var _arr_trail: Array
var _node: Node
var _max_length: int
var _last_pos := Vector2.ZERO

## Remove trail which is following the 'node'
static func remove(node: Node, dur := 0.5) -> void:
	var instance: Trail
	if !is_instance_valid(node):
		return
	if node.has_meta(META) and is_instance_valid(node.get_meta(META)):
		instance = node.get_meta(META)
	if instance == null:
		return
	instance.destroy(dur)

## Remove trail with animation
func destroy(dur := 0.5) -> void:
	AutoTween.new(
		self, &"modulate:a",
		0.0, dur, Tween.TRANS_LINEAR).finished.connect(queue_free)
	if _node != null:
		_last_pos = _node.global_position
		_node = null

func _init(parent: Node2D, node: Node, _color := Color.WHITE, _width := 16.0, max_length := 50, curve: Curve = load("uid://b5cphgha71oo2")) -> void:
	_node = node
	_max_length = max_length
	default_color = _color
	width = _width
	width_curve = curve
	_node.tree_exited.connect(destroy)
	_node.set_meta(META, self)
	parent.add_child(self)

func _physics_process(_delta: float) -> void:
	_arr_trail.push_front(_node.global_position if _node != null else _last_pos)
	if _arr_trail.size() > _max_length / Engine.time_scale:
		_arr_trail.pop_back()
	clear_points()
	for p in _arr_trail:
		add_point(p)
