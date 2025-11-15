@tool
extends Node2D

@export var speed := 0.18
@export var offset_angle := 50.0
@export var flip_h := false

@onready var light := %PointLight2D

@onready var _bg := $ColorRect
@onready var _container := $Container
@onready var _spotlight := %Spotlight

func _ready() -> void:
	if !Engine.is_editor_hint():
		_bg.hide()

func _physics_process(delta: float) -> void:
	_spotlight.rotation = deg_to_rad(-offset_angle) + (PI/8.0 * sin(Time.get_ticks_msec() * delta * speed))
	_container.scale.x = 1.0 if !flip_h else -1.0
