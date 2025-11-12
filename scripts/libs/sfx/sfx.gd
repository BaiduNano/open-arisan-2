class_name SFX extends RefCounted

signal finished

static var audio_streams: Array

const SFX_META := &"sfx"
const META := &"audio_stream"
const RANDOM_PITCH := 1.1
const MAX_POLYPHONY := 5
const PANNING_STRENGTH := 2.0

const playlist := {
	&"cheer": preload("uid://dqnool3yc7ue3"),
	&"confetti": preload("uid://d3bk1yiownt6v"),
	&"pop": preload("uid://boyheh1t5yjp2"),
	&"jar_close": preload("uid://b5aoifj802yrl"),
	&"rizz": preload("uid://xi22xe13l36e"),
	&"wow": preload("uid://8fachf3wlf1i"),
	&"lighting": preload("uid://ci4mdkhe7cqaj"),
	&"crowd": preload("uid://b1o20ooeuadcc"),
	
	&"button_click": preload("uid://cise2x7ivtceq"),
	&"button_hover": preload("uid://b4o23pyrhs71p"),
	
	&"hit_large": preload("uid://c2ktjjfshhbvg"),
	&"hit_small_1": preload("uid://cuc7m6m8ddtmw"),
	&"hit_small_2": preload("uid://dbkyuva2d6x0o"),
	
	&"paper_hint": preload("uid://c6ln1xhbik0ws"),
	
	&"xeno": preload("uid://d1mq0xwav7eou"),
	&"wallpaper": preload("uid://clvus7nmw2hob"),
	&"drum_roll": preload("uid://br1vktbr7tmxo"),
	&"cymbal": preload("uid://nomcjqym7wfd")
}
#"uid://clvus7nmw2hob" wallper
#uid://bytwt277ibnpw pirate
static var _reparent_node: Node2D:
	get: return Arena.others_nodes

var stream_player: AudioStreamPlayer
var _tween_delay_timer: SceneTreeTimer
var _last_playback_pos := 0.0
var _playback_tweener: Tween

static func create(node: Node, streams: Array, options := {&"volume_db": 0.0}) -> SFX:
	var instance: SFX
	if get_sfx(node, streams) == null:
		instance = SFX.new()
		node.set_meta(_get_sfx_hash(streams), instance)
	else:
		instance = get_sfx(node, streams)
	instance.stream_player = _get_stream_from_node(node, streams)
	if instance.stream_player == null:
		instance.stream_player = _create_stream(node, streams)
		instance.stream_player.bus = Audio.get_bus_str(Audio.AUDIO_BUS.SFX)
		# Doing some random JS bullsh*t to see if it works
		instance.stream_player.stream = (func() -> AudioStreamRandomizer:
			var stream = AudioStreamRandomizer.new()
			for i in range(streams.size()):
				stream.add_stream(i, streams[i])
			stream.random_pitch = RANDOM_PITCH
			return stream
		).call()
		
		# Reparent to 'other_nodes' if the parent is destroyed
		# FIXME: Putting callable here does not work somehow, it has to be lambda
		node.tree_exited.connect(func(): instance.reparent_stream())
		
		instance.stream_player.finished.connect(instance.finished.emit)
	
	for o in options.keys():
		instance.stream_player.set(o, options[o])
	
	(func():
		if !instance.stream_player.is_inside_tree():
			await instance.stream_player.tree_entered
		instance.stream_player.play()
	).call_deferred()
	
	return instance

static func get_sfx(node: Node, stream: Array) -> SFX:
	var meta := _get_sfx_hash(stream)
	if is_instance_valid(node) and node.has_meta(meta):
		return node.get_meta(meta) if node.get_meta(meta) != null else null
	return null

static func _get_sfx_hash(stream) -> String:
	return SFX_META + str(stream.hash())

static func _get_stream_from_node(node: Node, stream: Array) -> AudioStreamPlayer:
	var meta = _get_hash(stream)
	if is_instance_valid(node) and node.has_meta(meta):
		return node.get_meta(meta) if node.get_meta(meta) != null else null
	return null

static func _get_hash(stream) -> String:
	return META + str(stream.hash())

func set_pitch_change(val: float) -> SFX:
	if stream_player != null:
		(stream_player.stream as AudioStreamRandomizer).random_pitch = val
	return self

func no_pitch_change() -> SFX:
	return set_pitch_change(1.0)

func continue_playback() -> SFX:
	play_at(_last_playback_pos)
	return self

func play_at(offset: float) -> SFX:
	(func():
		if stream_player != null:
			if !stream_player.is_inside_tree():
				await stream_player.tree_entered
			stream_player.stop.call_deferred()
			stream_player.play.call_deferred(offset)
	).call()
	return self

func stop() -> SFX:
	_cancel_pending_tween()
	if is_instance_valid(stream_player):
		_last_playback_pos = stream_player.get_playback_position() + AudioServer.get_time_since_last_mix()
	stream_player.stop()
	return self

func delay(offset: float) -> SFX:
	if stream_player != null:
		stream_player.stop.call_deferred()
		stream_player.get_tree().create_timer(offset, false).timeout.connect(stream_player.play)
	return self
	
func is_ui() -> SFX:
	if stream_player != null:
		stream_player.bus = Audio.get_bus_str(Audio.AUDIO_BUS.UI)
	return process_always()
	
func is_bgm() -> SFX:
	if stream_player != null:
		stream_player.max_polyphony = 1
		stream_player.bus = Audio.get_bus_str(Audio.AUDIO_BUS.BGM)
	return process_always().no_pitch_change()

func change_volume(to_db: float, smoothing := 1.0) -> SFX:
	if stream_player != null:
		if smoothing:
			AutoTween.new(stream_player, &"volume_db", to_db, smoothing, Tween.TRANS_LINEAR)
		else:
			stream_player.volume_db = to_db
	return self

func process_always() -> SFX:
	if stream_player != null:
		stream_player.process_mode = Node.PROCESS_MODE_ALWAYS
	return self

func fade_in(dur := 1.0) -> SFX:
	if stream_player != null:
		(func(): AutoTween.new(stream_player, &"volume_db", stream_player.volume_db, dur, Tween.TRANS_EXPO, Tween.EASE_OUT).from(-42.0)).call_deferred()
		_cancel_pending_tween()
	return self

func fade_out(dur := 1.0, delay_offset := 0.0) -> SFX:
	if stream_player != null:
		_cancel_pending_tween()
		if delay_offset != 0.0:
			(func():
				_tween_delay_timer = stream_player.get_tree().create_timer(delay_offset, false)
				_tween_delay_timer.timeout.connect(_fadeout_tween.bind(dur), CONNECT_ONE_SHOT)
			).call_deferred()
		else:
			_fadeout_tween(dur)
	return self

func reparent_stream():
	if !is_instance_valid(stream_player):
		return
	if !stream_player.playing:
		_delete_stream()
		return
	stream_player.reparent(_reparent_node)
	# FIXME: This too, has to be lambda
	finished.connect(func(): _delete_stream())

static func _create_stream(node: Node, stream: Array) -> AudioStreamPlayer:
	var instance := AudioStreamPlayer.new()
	instance.max_polyphony = MAX_POLYPHONY
	audio_streams.append(instance)
	node.set_meta(_get_hash(stream), instance)
	node.add_child(instance)
	return instance

func _delete_stream() -> void:
	audio_streams.erase(stream_player)
	if is_instance_valid(stream_player):
		stream_player.queue_free()

func _cancel_pending_tween() -> void:
	if _tween_delay_timer != null and _tween_delay_timer.timeout.is_connected(_fadeout_tween):
		_tween_delay_timer.timeout.disconnect(_fadeout_tween)
		_tween_delay_timer = null

func _fadeout_tween(dur) -> void:
	AutoTween.new(stream_player, &"volume_db", -42.0, dur, Tween.TRANS_LINEAR, Tween.EASE_IN).finished.connect(func():
		if _playback_tweener != null:
			_playback_tweener.kill()
			_playback_tweener = null
		stop()
	)
	_playback_tweener = stream_player.create_tween()
	_playback_tweener.tween_callback(func():
		if is_instance_valid(stream_player):
			_last_playback_pos = stream_player.get_playback_position() + AudioServer.get_time_since_last_mix()
	)
	
	_cancel_pending_tween()
