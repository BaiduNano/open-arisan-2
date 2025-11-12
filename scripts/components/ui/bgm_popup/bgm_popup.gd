extends MarginContainer

const MARGIN := 32.0

var text = ""
var color := Color("1a1a1a")

@onready var _label = %Label
@onready var _container = %"Container"

var _size_x: float:
	get: return _container.get_rect().size.x

func _ready() -> void:
	(func():
		var from = _container.position + Vector2(_size_x + MARGIN, 0.0)
		_label.text = text
		for l in _container.get_children():
			l.add_theme_color_override("font_color", color)
		AutoTween.new(_container, &"modulate:a", 1.0).from(0.0)
		AutoTween.new(_container, &"position", _container.position).from(from)
		await get_tree().create_timer(3.0).timeout
		AutoTween.new(_container, &"modulate:a", 0.0, 0.8, Tween.TRANS_QUINT, Tween.EASE_IN)
		await AutoTween.new(_container, &"position", from, 0.8, Tween.TRANS_QUINT, Tween.EASE_IN).finished
		queue_free()
	).call_deferred()
	
