extends PanelContainer

@onready var _en_button := %ENButton
@onready var _id_button := %IDButton
@onready var _id2_button := %ID2Button

func _ready() -> void:
	Animate.fade_in(self)
	_en_button.pressed.connect(func():
		TranslationServer.set_locale("en")
		App.static_signals.locale_changed.emit()
		_animate_out()
	)
	_id_button.pressed.connect(func():
		TranslationServer.set_locale("id")
		App.static_signals.locale_changed.emit()
		_animate_out()
	)
	_id2_button.pressed.connect(func():
		TranslationServer.set_locale("id2")
		App.static_signals.locale_changed.emit()
		_animate_out()
	)

func _animate_out() -> void:
	Animate.fade_out(self).finished.connect(queue_free)
