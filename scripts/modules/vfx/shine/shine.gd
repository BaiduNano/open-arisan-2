extends Node2D

var node: Node
var follow_scale: bool
var color := Color.WHITE
var force_center: bool

@onready var lights := [
	{"node": $PointLight2D, "energy": $PointLight2D.energy},
	#{"node": $PointLight2D2, "energy": $PointLight2D2.energy}
]

func _ready() -> void:
	$ColorRect.hide()
	modulate = color
	
func _physics_process(delta: float) -> void:
	for l in lights:
		l.node.energy = remap(modulate.a, 0.0, 1.0, 0.0, l.energy)
		l.node.color = modulate

	if is_instance_valid(node):
		if !force_center:
			global_position = node.global_position
		else:
			global_position = node.global_position + (node.get_rect().size / 2.0)
		if follow_scale:
			global_scale = node.scale
	global_rotation += delta / 1.5
