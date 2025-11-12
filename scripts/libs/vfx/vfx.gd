class_name VFX extends RefCounted

const scenes := {
	&"explosions": {
		&"circular": preload("uid://bndtph6e8gcgu"),
		&"square": preload("uid://bjdxpf106m1gi"),
		&"shockwave": preload("uid://cvfhh7t0njvth"),
		&"energy_bast": preload("uid://wbino68hyx6a")
	},
	&"highlight_shader": preload("uid://bbwdbx3s8baj3"),
	&"shine": preload("uid://pdt520vswtym"),
	&"particles": {
		&"bullet_spark1": preload("uid://c1u3fnwh771x3"),
		&"blood_splat1": preload("uid://e4rsgij50m0i"),
		&"inward_spell_blast": preload("uid://b1xuprti224l2"),
		&"outward_spell_blast": preload("uid://cmkikdf7h5kbk"),
		&"big_blast": preload("uid://kmtwa87nkc6i"),
		&"particle_emoji": preload("uid://dlvds5cx8mayy")
	},
}

class Shine:
	const META := &"shine"
	var instance: Node2D
	func _init(node: Node, color := Color.WHITE, follow_scale := true, force_center := false) -> void:
		instance = scenes.shine.instantiate()
		instance.node = node
		instance.color = color
		instance.follow_scale = follow_scale
		instance.force_center = force_center
		Game.vfx_front_node.add_child(instance)
		node.set_meta(META, instance)
		node.tree_exited.connect(func():
			if is_instance_valid(instance): remove(instance)
		)
		AutoTween.new(instance, &"modulate:a", 1.0, 0.3, Tween.TRANS_LINEAR).from(0.0)
	
	func rescale(scale := Vector2.ONE) -> void:
		instance.global_scale = scale
		
	static func remove(node: Node) -> void:
		if node.has_meta(META) or node.scene_file_path == scenes.shine.resource_path:
			var inst = node.get_meta(META) if node.scene_file_path != scenes.shine.resource_path else node
			AutoTween.new(inst, &"modulate:a", 0.0, 0.3, Tween.TRANS_LINEAR).finished.connect(func():
				if !inst.is_queued_for_deletion(): inst.queue_free()
			)

class Highlight:
	const OLD_META := &"old_shader_material"
	const META := &"highlight_shader_material"
	
	func _init(sprite: Sprite2D, thickness := 10.0, outline_color := Color("1a1a1a")) -> void:
		var material: ShaderMaterial
		
		if sprite.has_meta(META):
			material = sprite.get_meta(META)
		
		else:
			if sprite.material != null and sprite.material.resource_path != scenes.highlight_shader.resource_path:
				sprite.set_meta(OLD_META, sprite.material)
			material = ShaderMaterial.new()
			material.shader = scenes.highlight_shader.duplicate()
			sprite.material = material
			sprite.set_meta(META, material)
		
		material.set_shader_parameter(&"thickness", thickness)
		material.set_shader_parameter(&"outline_color", outline_color)
	
	static func disable(sprite: Sprite2D) -> void:
		if sprite.has_meta(META):
			var material: ShaderMaterial = sprite.get_meta(META)
			material.set_shader_parameter(&"thickness", 0.0)
			material.set_shader_parameter(&"outline_color", Color.TRANSPARENT)
	
	static func remove(sprite: Sprite2D) -> void:
		if sprite.has_meta(OLD_META):
			sprite.material = sprite.get_meta(OLD_META)
		else:
			sprite.material = null

class Explosion:
	class CircularExplosion:
		var instance: Node2D
		func _init(where: Vector2, thiccness := 45.0, duration := 0.5, color := Color("1a1a1a")) -> void:
			var pool: ObjectPool = ObjectPoolService.get_pool(scenes.explosions.circular)
			instance = pool.claim_new()
			if instance.get_parent() != ObjectPoolService.default_parent:
				reparent(ObjectPoolService.default_parent)
			instance.thiccness = thiccness
			instance.duration = duration
			instance.color = color
			instance.global_position = where
		
		func reverse() -> CircularExplosion:
			instance.reverse = true
			return self
		
		func reparent(node: Node) -> CircularExplosion:
			instance.reparent(node)
			return self
			
		func recalculate_duration() -> CircularExplosion:
			instance.recalculate_duration()
			return self
			
	class SquareHighlight:
		func _init(where: Vector2, color := Color("1a1a1a"),dimension :=  Vector2(360.0, 156.0), minimum_scale := 0.33, thiccness := 8.0, duration := 0.8, filled := false) -> void:
			var pool: ObjectPool = ObjectPoolService.get_pool(scenes.explosions.square)
			var instance: Node2D = pool.claim_new()
			instance.thiccness = thiccness
			instance.duration = duration
			instance.color = color
			instance.dimension = dimension
			instance.filled = filled
			instance.minimum_scale = minimum_scale
			instance.global_position = where
			
	class Shockwave:
		func _init(where: Vector2, options := {&"gap": 0.02}) -> void:
			var instance: BackBufferCopy = scenes.explosions.shockwave.instantiate()
			instance.tracker.global_position = where
			for o in options.keys():
				instance.set(o, options[o])
			Game.ui_node.add_child(instance)
			Arena.others_nodes.add_child(instance.tracker)

	class EnergyBlast:
		func _init(where: Variant, gradient: GradientTexture1D = null) -> void:
			var instance: ColorRect = scenes.explosions.energy_bast.instantiate()
			if where is Vector2:
				instance.target_pos = where
			if where is Node:
				instance.follow_node = where
			instance.gradient = gradient
			Game.vfx_front_node.add_child(instance)

class Particles:
	class BulletSpark:
		var instance: ParticlesGPU
		func _init(where: Vector2, normal: Vector2, incident_angle: float) -> void:
			var pool: ObjectPool = ObjectPoolService.get_pool(scenes.particles.bullet_spark1)
			instance = pool.claim_new()
			instance.normal = normal
			instance.global_position = where
			instance.incident_angle = incident_angle
			
	class BloodSplat:
		var instance: ParticlesGPU
		func _init(where: Vector2) -> void:
			var pool: ObjectPool = ObjectPoolService.get_pool(scenes.particles.blood_splat1)
			instance = pool.claim_new()
			instance.global_position = where
			
	class InwardSpellBlast:
		var instance: GPUParticles2D
		func _init(where: Variant, alpha := 1.0, modulate_color := Color.WHITE) -> void:
			instance = scenes.particles.inward_spell_blast.instantiate()
			instance.where = where
			instance.alpha = alpha
			instance.modulate = modulate_color
			Game.vfx_front_node.add_child(instance)
			
		func reparent(node: Node) -> void:
			instance.reparent(node)
			
	class OutwardSpellBlast:
		var instance: GPUParticles2D
		func _init(where: Variant, alpha := 1.0, modulate_color := Color.WHITE) -> void:
			instance = scenes.particles.outward_spell_blast.instantiate()
			instance.where = where
			instance.alpha = alpha
			instance.modulate = modulate_color
			Game.vfx_front_node.add_child(instance)
			
		func reparent(node: Node) -> void:
			instance.reparent(node)
			
	class BigBlast:
		func _init(where: Variant, alpha := 1.0, modulate_color := Color.WHITE) -> void:
			var instance: GPUParticles2D = scenes.particles.big_blast.instantiate()
			instance.where = where
			instance.alpha = alpha
			instance.modulate = modulate_color
			Game.vfx_front_node.add_child(instance)
	
	class Emoji:
		const META := &"p_emoji"
		func _init(node: Node, rect_size: Vector2) -> void:
			var instance: Node = scenes.particles.particle_emoji.instantiate()
			instance.node = node
			instance.emission_rect_extents = rect_size
			Game.vfx_node.add_child(instance)
			node.set_meta(META, instance)
			
		static func remove(node: Node) -> void:
			if node.has_meta(META):
				var instance = node.get_meta(META)
				AutoTween.new(instance, &"modulate:a", 0.0).finished.connect(instance.queue_free)
