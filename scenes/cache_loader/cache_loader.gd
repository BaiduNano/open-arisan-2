extends Node2D

## Spawn all effects so they are saved on the caches

const NEXT_SCENE := preload("uid://bsdr2ntqoxu8l")

var _sprite_2d := Sprite2D.new()

func _ready() -> void:
	Audio.set_master_vol(0.0)
	for c in [_vfxs, _sfxs, _particles]:
		c.call()
		await get_tree().physics_frame
	await get_tree().create_timer(1.0).timeout
	SceneManager.change_scene(NEXT_SCENE, true)
	
func _particles() -> void:
	# BGM POPUP
	add_child(preload("uid://d2paoku5bjocl").instantiate())
	# WINNER INTERACTABLE
	#add_child(preload("uid://3ybh7v3obbk0").instantiate())
	WinnerInteractable.create(Paper.new())
	# WINNER PREVIEWER
	add_child(preload("uid://bsygsbwamwn1k").instantiate())
	# WINNER SPOTLIGHT
	add_child(preload("uid://dhga6l105rwpq").instantiate())
	# CONFETTI PACK
	add_child(preload("uid://damlvbxf1ikxo").instantiate())
	# CONFETTI RAIN
	add_child(preload("uid://ccc8qr6gny81l").instantiate())
	
func _vfxs() -> void:
	VFX.Explosion.CircularExplosion.new(Vector2.ZERO)
	VFX.Explosion.SquareHighlight.new(Vector2.ZERO)
	VFX.Explosion.Shockwave.new(Vector2.ZERO)
	VFX.Particles.BigBlast.new(Vector2.ZERO)
	VFX.Particles.InwardSpellBlast.new(Vector2.ZERO)
	VFX.Particles.OutwardSpellBlast.new(Vector2.ZERO)
	VFX.Particles.Emoji.new(self, Vector2.ONE)
	add_child(_sprite_2d)
	VFX.Highlight.new(_sprite_2d)
	VFX.Shine.new(_sprite_2d)

func _sfxs() -> void:
	for p in SFX.playlist.keys():
		SFX.create(self, [SFX.playlist[p]])
