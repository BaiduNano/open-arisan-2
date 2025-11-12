extends Node

const confetti_pack_scene := preload("uid://damlvbxf1ikxo")
const confetti_rain_scene := preload("uid://ccc8qr6gny81l")
const spotlight_scene := preload("uid://dhga6l105rwpq")
const bgm_popup_scene := preload("uid://d2paoku5bjocl")

const XENO_FADEOUT := 5.0

var _cf_rain: Control
var _spotlight: BoxContainer
var _spotlight_timer: SceneTreeTimer
var _viewport_size: Vector2:
	get: return get_viewport().get_visible_rect().size
var _viewport_center: Vector2:
	get: return get_viewport().get_visible_rect().get_center()

func _ready() -> void:
	WinnerInteractable.static_signals.paper_picked.connect(func(_which: Paper, interacted: bool):
		GameFX.enable_motion_blur()
		if !interacted:
			SFX.create(self, [SFX.playlist.xeno]).no_pitch_change().is_bgm().play_at(53.315).fade_in().fade_out(10.0, 15.0)
			_add_bgm_info("TheFatRat - Xenogenesis", Color.WHITE)
			Game.instance.stop_bgm()
	)
	WinnerInteractable.static_signals.paper_scaled_to_zero.connect(func():
		await get_tree().create_timer(0.05).timeout
		VFX.Explosion.Shockwave.new(_viewport_center, {&"reverse": true})
		await get_tree().create_timer(0.45).timeout
		VFX.Explosion.CircularExplosion.new(_viewport_center, max(_viewport_size.x, _viewport_size.y) / 2.0, 0.5, Color.WHITE).reparent(Game.vfx_front_node).reverse().recalculate_duration()
	)
	WinnerInteractable.static_signals.winner_shown.connect(func(which: TextureRect):
		_add_cf_pack()
		VFX.Explosion.Shockwave.new(get_viewport().get_visible_rect().get_center())
		VFX.Explosion.CircularExplosion.new(_viewport_center, max(which.size.x, which.size.y), 2.0, Color.WHITE).reparent(Game.vfx_front_node).recalculate_duration()
		VFX.Explosion.EnergyBlast.new(_viewport_center)
		VFX.Particles.OutwardSpellBlast.new(_viewport_center, 0.5)
		get_tree().create_timer(0.1, false).timeout.connect(func():
			VFX.Explosion.Shockwave.new(get_viewport().get_visible_rect().get_center(), {&"gap" : 0.01})
		)
		get_tree().create_timer(0.2, false).timeout.connect(func():
			VFX.Explosion.CircularExplosion.new(_viewport_center, max(which.size.x, which.size.y) / 1.5, 1.5, Color.WHITE).reparent(Game.vfx_front_node).recalculate_duration()
		)
		
		_spotlight_timer = get_tree().create_timer(XENO_FADEOUT * 2.5, false)
		_spotlight_timer.timeout.connect(_spot_light_remove)
		
		GameFX.show_dark_overlay(true)
		CameraShaker.new(28.0, 1.0)
		
		SFX.create(self, [SFX.playlist.cheer], {&"volume_db": -4.0}).no_pitch_change()
		SFX.create(self, [SFX.playlist.confetti], {&"volume_db": -4.0}).no_pitch_change()
		SFX.create(self, [SFX.playlist.rizz], {&"volume_db": -4.0}).no_pitch_change()
		SFX.create(self, [SFX.playlist.wow]).no_pitch_change()
		SFX.create(self, [SFX.playlist.crowd], {&"volume_db": -8.0}).no_pitch_change().is_bgm().fade_in(1.0).fade_out(10.0, XENO_FADEOUT)

		_spotlight = spotlight_scene.instantiate()
		Game.vfx_front_node.add_child(_spotlight)
		_spotlight.fade_in()
	)
	
	WinnerInteractable.static_signals.picture_showed.connect(func(which: TextureRect, _paper: Paper):
		_toggle_cf_rain(true)
		VFX.Shine.new(which, Color.WHITE, false, true).rescale(Vector2.ONE * 2.0)
		VFX.Particles.Emoji.new(which, which.size)
	)
	
	WinnerInteractable.static_signals.picture_hidden.connect(func(which: TextureRect, _paper: Paper):
		_toggle_cf_rain(false)
		VFX.Shine.remove(which)
		get_tree().create_timer(0.5).timeout.connect(GameFX.disable_motion_blur)
		VFX.Particles.Emoji.remove(which)
		SFX.get_sfx(self, [SFX.playlist.crowd]).fade_out(5.0)
		SFX.get_sfx(self, [SFX.playlist.xeno]).fade_out(5.0)
		if !SFX.get_sfx(Game.instance, [SFX.playlist.wallpaper]).stream_player.playing:
			Game.instance.play_bgm(5.0)
		if _spotlight != null:
			_spotlight.fade_out()
			if _spotlight_timer.timeout.is_connected(_spot_light_remove):
				_spotlight_timer.timeout.disconnect(_spot_light_remove)
	)

func _add_cf_pack() -> void:
	Game.ui_node.add_child(confetti_pack_scene.instantiate())

func _toggle_cf_rain(b: bool) -> void:
	if b:
		if _cf_rain != null:
			AutoTween.new(_cf_rain, &"modulate:a", 1.0)
			return
		_cf_rain = confetti_rain_scene.instantiate()
		Game.ui_node.add_child(_cf_rain)
		AutoTween.new(_cf_rain, &"modulate:a", 1.0).from(0.0)
	else:
		if is_instance_valid(_cf_rain): AutoTween.new(_cf_rain, &"modulate:a", 0.0).finished.connect(_cf_rain.queue_free)

func _spot_light_remove() -> void:
	if _spotlight != null:
		_spotlight.fade_out(5.0)
	Game.instance.play_bgm(15.0)


func _add_bgm_info(what: String, color: Color, alpha := 0.7) -> void:
	var bgm_info := bgm_popup_scene.instantiate()
	color.a = alpha
	bgm_info.text = what
	bgm_info.color = color
	Game.ui_node.add_child(bgm_info)
