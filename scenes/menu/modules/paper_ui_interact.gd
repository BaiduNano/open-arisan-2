extends Node

@onready var _down_cont := %DownVBoxContainer
@onready var _top_mask := %TopMask

var _init_down_pos_y: float

func _ready() -> void:
	UIPreviewer.static_signal.previewer_toggled.connect(func(b: bool):
		AutoTween.new(_down_cont, &"position:y", _init_down_pos_y + 162.0 if b else _init_down_pos_y)
	)
	UIPaperContainer.static_signals.inspector_activated.connect(func():
		_top_mask.show()
		_top_mask.mouse_filter = Control.MouseFilter.MOUSE_FILTER_STOP
		AutoTween.new(_top_mask, &"modulate:a", 1.0, 0.5)
	)
	UIPaperContainer.static_signals.inspector_deactivated.connect(func():
		_top_mask.mouse_filter = Control.MouseFilter.MOUSE_FILTER_IGNORE
		AutoTween.new(_top_mask, &"modulate:a", 0.0, 0.5).finished.connect(_top_mask.hide)
	)
	(func(): _init_down_pos_y = _down_cont.position.y).call_deferred()
	_top_mask.hide()
