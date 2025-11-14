extends PanelContainer

signal finished

@onready var _text_edit: TextEdit = %TextEdit
@onready var _close_button := %CloseButton
@onready var _add_button := %AddTextButton
@onready var _confirm_label := %ConfirmLabel

var _data_importer: Node:
	get: return MainMenu.instance.get_node("%DataImporter")
var _scroll_cont: ScrollContainer:
	get: return MainMenu.instance.get_node("%ScrollContainer")
var _regex := RegEx.create_from_string("[^\\n\\s\\t$]")

func _ready() -> void:
	Animate.fade_in(self)
	_confirm_label.hide()
	_text_edit.grab_focus.call_deferred()
	_close_button.pressed.connect(func():
		for b in [_close_button, _add_button]:
			b.disabled = true
		_text_edit.focus_mode = Control.FOCUS_NONE
		await Animate.fade_out(self).finished
		finished.emit()
		_scroll_cont.grab_focus()
		queue_free()
	)
	_text_edit.text_changed.connect(func():
		## Regex if there's only newlines and spaces
		var res := _regex.search(_text_edit.text)
		_add_button.disabled = _text_edit.text.is_empty() or res == null
		SFX.create(self, [SFX.playlist.button_hover])
	)
	_text_edit.text_changed.emit()
	_add_button.pressed.connect(func():
		await _data_importer.process_text(_text_edit.text)
		if !_text_edit.text.is_empty():
			_animate_confirm_label()
			_text_edit.placeholder_text = ""
			_text_edit.text_changed.emit.call_deferred()
		_text_edit.text = ""
	)
	_data_importer.error_max_size.connect(_close_button.pressed.emit)
	
func _animate_confirm_label() -> void:
	_confirm_label.show()
	_confirm_label.modulate.a = 0.0
	await get_tree().process_frame
	
	AutoTween.new(_confirm_label, &"modulate:a", 1.0)
	AutoTween.new(_confirm_label, &"position", Vector2.ZERO).from(Vector2(0.0, 32.0)).finished.connect(_animate_out_confirm_label)
	
func _animate_out_confirm_label() -> void:
	AutoTween.new(_confirm_label, &"position", Vector2(0.0, -32.0), 0.75, Tween.TRANS_QUINT, Tween.EASE_IN)
	AutoTween.new(_confirm_label, &"modulate:a", 0.0, 0.75, Tween.TRANS_QUINT, Tween.EASE_IN).finished.connect(_confirm_label.hide)
	
