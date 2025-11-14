class_name UIPaperContainer extends CenterContainer

class static_signal:
	@warning_ignore("unused_signal")
	signal inspector_activated
	@warning_ignore("unused_signal")
	signal inspector_deactivated

static var active_container: UIPaperContainer
static var buffered_container: UIPaperContainer
static var static_signals := static_signal.new()

var inspect: UIInspector
var is_mouse_inside := false

static var _inspect_scene := preload("uid://cjpbipivafssk")

@onready var _center := $Control

var _paper: Paper:
	get: return _center.get_child(0)

func activate_inspector() -> void:
	_create_inspector()
	_activate_inspector()

func remove_inspector() -> void:
	_remove_inspector()

func _ready() -> void:
	mouse_entered.connect(_mouse_entered)
	mouse_exited.connect(_mouse_exited)
	(func(): _paper.tree_exited.connect(queue_free)).call_deferred()

func _input(event: InputEvent) -> void:
	if !event.is_action_pressed(&"Grab"):
		return
	if buffered_container == self:
		return
	if is_mouse_inside and active_container == null:
		_activate_inspector()
		SFX.create(MainMenu.instance, [SFX.playlist.button_click], {&"volume_db": -5.0}).no_pitch_change().is_ui()
	if !is_mouse_inside and active_container == self:
		_remove_inspector()
		_poke_buffered()
		SFX.create(MainMenu.instance, [SFX.playlist.button_hover]).no_pitch_change().is_ui()

func _mouse_entered() -> void:
	if active_container == null:
		_create_inspector()
		SFX.create(MainMenu.instance, [SFX.playlist.button_hover]).no_pitch_change().is_ui()
	else:
		buffered_container = self
	is_mouse_inside = true

func _mouse_exited() -> void:
	if active_container == null:
		_remove_inspector()
	is_mouse_inside = false

func _activate_inspector() -> void:
	if inspect != null:
		inspect.activate()
		active_container = self
		_anim_pop()
		static_signals.inspector_activated.emit()

func _create_inspector() -> void:
	inspect = _inspect_scene.instantiate()
	inspect.paper_pair = _paper
	inspect.modulate.a = 0.75
	inspect.paper_container_pair = self
	inspect.global_position = _center.global_position
	MainMenu.ui_node.add_child(inspect)
	inspect.animate_in()
	_anim_shake()

func _remove_inspector() -> void:
	if !is_instance_valid(inspect):
		return
	inspect.animate_out()
	inspect.deactivate_buttons.call_deferred()
	active_container = null
	static_signals.inspector_deactivated.emit()

func _poke_buffered() -> void:
	if buffered_container != null and buffered_container.is_mouse_inside:
		buffered_container._create_inspector()
		(func(): buffered_container = null).call_deferred()
	else:
		buffered_container = null

func _anim_shake() -> void:
	var amount = (8.0 + randf_range(0.0, 2.0) ) * [-1, 1].pick_random()
	await AutoTween.new(_paper, &"rotation_degrees", rotation_degrees + amount, 0.1).from(0.0).finished
	AutoTween.new(_paper, &"rotation_degrees", 0.0, 1.33, Tween.TRANS_ELASTIC).from(rotation_degrees + amount)

func _anim_pop() -> void:
	AutoTween.new(_paper, &"position:y", 0.0, 1.0, Tween.TRANS_ELASTIC).from(10.0)
