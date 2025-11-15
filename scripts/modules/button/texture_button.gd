extends TextureButton

var parent: Node

func _ready() -> void:
	if is_instance_valid(Game.instance):
		parent = Game.instance
	elif is_instance_valid(MainMenu.instance):
		parent = MainMenu.instance
	else:
		parent = self
	if !App.data.android_build:
		mouse_entered.connect(func():
			if !disabled: SFX.create(parent, [SFX.playlist.button_hover]).no_pitch_change().is_ui()
			modulate.a = 0.8
		)
	mouse_exited.connect(func():
		modulate = Color.WHITE
	)
	button_down.connect(func():
		SFX.create(parent, [SFX.playlist.button_click], {&"volume_db": -5.0}).no_pitch_change().is_ui()
		modulate = Color(2.0, 2.0, 2.0, 1.0)
	)
	button_up.connect(func():
		modulate = Color.WHITE
		modulate.a = 0.8
	)
