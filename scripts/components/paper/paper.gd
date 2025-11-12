class_name Paper extends RigidBody2D

const SCALE_ON_GAME := Vector2(0.75, 0.75)
const CONTACT_REFRESH := 0.2
const CONTACT_SPEED_MINIMUM := 224.0
const RECT_SCALE := 1.2

@onready var icon := %Icon

var queue_data: Dictionary
var is_inside_bottle := true
var default_color = null

@onready var _straw := %Straw
@onready var _icon_cont := $IconCont

var _enable_contact := true
var _collision_point: Vector2
var _inactive := false

func set_outside_bottle() -> void:
	is_inside_bottle = false
	collision_mask = 0
	collision_layer = 0
	set_collision_mask_value(1, true)
	set_collision_layer_value(10, true)
	get_parent().move_child(self, -1)
	physics_material_override.bounce = 0.85
	Bottle.instance.paper_passed.emit(self)
	var col = default_color
	col.a = 0.3
	linear_velocity += Vector2(-1.0, 0.0).rotated(Bottle.instance.global_rotation + PI/2.0) * 1000.0
	Trail.new(Arena.others_nodes, self, col).z_index = -1
	for c in get_children():
		AutoTween.new(c, &"global_scale", SCALE_ON_GAME)

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 1
	body_entered.connect(_contact)
	if get_tree().current_scene is Game:
		var target_scale: Vector2
		if PaperQueue.get_data().size() <= 32:
			target_scale = SCALE_ON_GAME
		elif PaperQueue.get_data().size() <= 64:
			target_scale = SCALE_ON_GAME * 0.85
		else:
			target_scale = SCALE_ON_GAME * 0.75
		for c in get_children():
			if !is_inside_bottle:
				continue
			c.global_scale = target_scale

	if default_color == null:
		default_color = _get_random_color()
		
	_straw.modulate = default_color
	
	sleeping_state_changed.connect(func():
		if is_inside_bottle or !sleeping or _inactive:
			return
		_inactive = true
		physics_material_override.bounce = 0.05
		WinnerInteractable.create.call_deferred(self)
		AutoTween.new(_icon_cont, &"scale", Vector2.ONE, 0.5)
		Trail.remove(self)
		for i in range(2):
			_anim_shake()
			SFX.create(Game.instance, [SFX.playlist.paper_hint], {&"volume_db": 6.0})
			for j in range(3):
				VFX.Explosion.SquareHighlight.new(global_position, default_color)
				await get_tree().create_timer(0.1, false).timeout
			await get_tree().create_timer(0.3, false).timeout
		AutoTween.new(_icon_cont, &"scale", SCALE_ON_GAME, 0.5)
	)
	
##Detects collision and retreive collision point
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if state.get_contact_count() == 0:
		return
	_collision_point = state.get_contact_local_position(0)

func _contact(_node: Node) -> void:
	if !_enable_contact:
		return
	if _node is Bottle:
		return
	if linear_velocity.length() < CONTACT_SPEED_MINIMUM:
		return
		
	var volume := remap(linear_velocity.length(),0.0, 1000.0, -32.0, -8.0)
	volume = clampf(volume, -32.0, -8.0)
	
	if !is_inside_bottle and !_inactive:
		VFX.Explosion.CircularExplosion.new(_collision_point, 80.0, 0.66, default_color)
		CameraShaker.new(remap(linear_velocity.length(),0.0, 1000.0, 0.0, 8.0))
		SFX.create(Game.instance, [SFX.playlist.hit_large],
			{&"volume_db": volume / 2.0})
	else:
		SFX.create(Game.instance, [SFX.playlist.hit_small_1, SFX.playlist.hit_small_2],
			{&"volume_db": volume * 1.5})
		
	_toggle_contact()

func _toggle_contact() -> void:
	_enable_contact = false
	get_tree().create_timer(CONTACT_REFRESH, false).timeout.connect(func():
		_enable_contact = true
	)

func _physics_process(_delta: float) -> void:
	if !is_instance_valid(Bottle.instance):
		return
	if !is_inside_bottle:
		return
	var bottle := Bottle.instance
	var max_dist := bottle.rect.size.y / 1.5
	if global_position.distance_to(bottle.global_position) >= max_dist:
		global_position = bottle.global_position
		
func _get_random_color(saturation: float = 1.0, value: float = 1.0) -> Color:
	var random_hue = randf() 
	return Color.from_hsv(random_hue, saturation, value)

func _anim_shake() -> void:
	var amount = 7.0 * [-1, 1].pick_random()
	await AutoTween.new(_icon_cont, &"rotation_degrees", _icon_cont.rotation_degrees + amount, 0.1).from(0.0).finished
	await AutoTween.new(_icon_cont, &"rotation_degrees", 0.0, 0.8, Tween.TRANS_ELASTIC).from(_icon_cont.rotation_degrees + amount).finished
