class_name Bottle extends CharacterBody2D

@warning_ignore("unused_signal")
signal paper_passed(which: Paper)

static var instance: Bottle
static var g_position: Vector2
static var enable_input := true

const SPEED := 50.0e3
const ROT_SPEED := 30.0
const LID_ANIM_DUR := 0.5

var rect: Rect2:
	get: return $Jar.get_rect()

@onready var _touch_area := %TouchArea
@onready var _lid_sensor := %LidSensor
@onready var _lid := %Lid
@onready var _jar_lid_sprite := %JarLid

var _cursor_inside := false
var _buffered_cursor_inside := false
var _grab := false
var _jar_lid_sprite_init_transform: Transform2D
var _init_rotation: float
var _last_delta_rotation: float
var _init_position: Vector2
var _bottle_pos: Vector2:
	get: return global_position + _init_position
var _m_pos: Vector2:
	get: return get_global_mouse_position()
var _viewport_size: Vector2:
	get: return get_viewport().get_visible_rect().size

func open_lid() -> void:
	_lid.process_mode = Node.PROCESS_MODE_DISABLED
	_lid_sensor.set_deferred(&"monitoring", true)
	var tgt_pos := Vector2(-16.0, -128) + _jar_lid_sprite_init_transform.origin
	AutoTween.new(_jar_lid_sprite, &"position", tgt_pos, LID_ANIM_DUR)
	AutoTween.new(_jar_lid_sprite, &"rotation_degrees", 15.0, LID_ANIM_DUR)
	AutoTween.new(_jar_lid_sprite, &"modulate:a", 0.0, LID_ANIM_DUR).from(1.0)
	SFX.create(self, [SFX.playlist.pop], {&"volume_db": 0.0})
	
func close_lid() -> void:
	_lid.process_mode = Node.PROCESS_MODE_INHERIT
	_lid_sensor.set_deferred(&"monitoring", false)
	AutoTween.new(_jar_lid_sprite, &"transform", _jar_lid_sprite_init_transform, LID_ANIM_DUR)
	AutoTween.new(_jar_lid_sprite, &"modulate:a", 1.0, LID_ANIM_DUR).from(0.0)
	get_tree().create_timer(0.2).timeout.connect(SFX.create.bind(self, [SFX.playlist.jar_close], {&"volume_db": 0.0}))
	
func _init() -> void:
	instance = self

func _ready() -> void:
	_touch_area.mouse_entered.connect(func():
		_buffered_cursor_inside = true
		if !_grab: _cursor_inside = true)
	_touch_area.mouse_exited.connect(func():
		_buffered_cursor_inside = false
		if !_grab: _cursor_inside = false)
	_lid_sensor.body_entered.connect(func(body: Node2D):
		if body is Paper and body.is_inside_bottle:
			body.set_outside_bottle()
	)
	(func(): _jar_lid_sprite_init_transform = _jar_lid_sprite.transform).call_deferred()
	close_lid.call_deferred()
	global_position = get_viewport().get_visible_rect().get_center()

	enable_input = true
	
func _input(event: InputEvent) -> void:
	if !enable_input:
		_grab = false
		return
	if event.is_action_pressed(&"Grab"):
		(func(): _grab = true).call_deferred()
		_init_position = _m_pos - global_position
		_init_rotation = global_rotation
	if event.is_action_released(&"Grab"):
		(func(): _grab = false; _cursor_inside = _buffered_cursor_inside).call_deferred()
		_last_delta_rotation = _get_delta_rotation() if !_cursor_inside else global_rotation

func _physics_process(delta: float) -> void:
	g_position = global_position
	if _grab and _cursor_inside:
		var dir := _m_pos - _bottle_pos
		velocity = dir * delta * SPEED
		move_and_slide.call_deferred()
		return
	var angle := _get_delta_rotation() if _grab else _last_delta_rotation
	var delt := (Vector2.from_angle(global_rotation) - Vector2.from_angle(angle) ).length()
	global_rotation = rotate_toward(global_rotation, angle, delt * delta * ROT_SPEED)
	velocity = lerp(velocity, Vector2.ZERO, delta * 10.0)
	move_and_slide.call_deferred()
	_cap_to_viewport.call_deferred()

func _get_delta_rotation() -> float:
	return (_m_pos - global_position).angle() - _init_position.angle() + _init_rotation

func _cap_to_viewport() -> void:
	global_position = Vector2(
		clampf(global_position.x, 0.0, _viewport_size.x),
		clampf(global_position.y, 0.0, _viewport_size.y)
	)
