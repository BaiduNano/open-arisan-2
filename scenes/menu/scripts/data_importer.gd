extends Node

const MAX_SIZE := 100

const F_TEXT := [] #[&"", &"txt", &"conf", &"ini"]
const F_IMAGE := [&"png", &"jpg", &"jpeg", &"webp"]
const THEME := preload("res://config/themes/global.tres")

const _loading_scene := preload("uid://2pbxy1ndy6xf")

var _thread := Thread.new()

@onready var _menu: MainMenu = owner
@onready var _add_btn: Button = %AddButton

var _file_picker: Variant
var _error_dialogue: Alert
var _error_max_dialogue: Alert

func _ready() -> void:
	_add_btn.pressed.connect(_spawn_file_picker)
	
func _spawn_file_picker() -> void:
	if _file_picker != null:
		return
	if PaperQueue.get_data().size() >= MAX_SIZE:
		_throw_max_error()
		return
	
	_create_loading_screen()
	
	if App.data.web_build:
		var nullify_picker = func():
			_remove_loading_screen()
			_file_picker = null
		_file_picker = FileAccessWeb.new()
		_file_picker.open()
		_file_picker.progress.connect(_menu.progress.emit)
		_file_picker.loaded.connect(_files_picked_web)
		_file_picker.error.connect(nullify_picker)
		_file_picker.upload_cancelled.connect(nullify_picker)
		return
		
	_file_picker = FileDialog.new()
	_file_picker.tree_exited.connect(_remove_loading_screen)
	_menu.add_child(_file_picker)
	_file_picker.show.call_deferred()
	_file_picker.access = FileDialog.ACCESS_FILESYSTEM
	_file_picker.use_native_dialog = true
	_file_picker.file_mode = FileDialog.FILE_MODE_OPEN_FILES
	_file_picker.files_selected.connect(_files_picked)
	_file_picker.canceled.connect(_file_picker.queue_free)
	
func _files_picked(paths: PackedStringArray) -> void:
	if _thread.is_started():
		_thread.wait_to_finish()
	_thread.start(func():
		for path in paths:
			_process_file(path)
		_file_picker.queue_free.call_deferred()
		_remove_loading_screen.call_deferred()
	)
	

func _files_picked_web(file_name: String, _file_type: String, base64_data: String) -> void:
	var extension := file_name.get_extension().to_lower()
	var raw_data: PackedByteArray = Marshalls.base64_to_raw(base64_data)
	
	if PaperQueue.get_data().size() >= MAX_SIZE:
		_throw_max_error()
		return
	if F_TEXT.has(extension):
		_menu.file_added.emit(raw_data.get_string_from_multibyte_char())
		
	elif F_IMAGE.has(extension):
		var image := _process_image_web(raw_data, extension)
		var texture := ImageTexture.create_from_image(image)
		_menu.file_added.emit(texture)
	else:
		_throw_error(file_name)
		
	_file_picker = null
	_remove_loading_screen.call_deferred()
	
func _process_file(path: StringName) -> void:
	var extension := path.get_extension().to_lower()
	
	if PaperQueue.get_data().size() >= MAX_SIZE:
		_throw_max_error.call_deferred()
		return
	if F_TEXT.has(extension):
		var text := FileAccess.open(path, FileAccess.READ).get_as_text()
		var spliced := text.split("\n")
		for s in spliced:
			if !s.is_empty(): _menu.file_added.emit(s)
	elif F_IMAGE.has(extension):
		var image = Image.load_from_file(path)
		var texture = ImageTexture.create_from_image(image)
		_menu.file_added.emit.call_deferred(texture)
		
	else:
		_throw_error.call_deferred(path)

func _process_image_web(data: PackedByteArray, extension: String) -> Image:
	var image := Image.new()
	
	match extension:
		&"png":
			image.load_png_from_buffer(data)
		&"jpeg", &"jpg":
			image.load_jpg_from_buffer(data)
		&"webp":
			image.load_webp_from_buffer(data)
			
	return image

func _throw_error(path: StringName) -> void:
	const META := &"exts"

	if _error_dialogue == null:
		_error_dialogue = Alert.create("")
		_error_dialogue.yes.hide()
		_error_dialogue.no.text = "OK"
		_error_dialogue.set_meta(META, [path])

	var paths: Array = _error_dialogue.get_meta(META)
	if !paths.has(path): paths.append(path)
	_error_dialogue.set_meta(META, paths)
	var strs = (func():
		var out := ""
		for s in paths:
			if App.data.platform == &"windows": out += "- %s\n" % s.split("\\")[-1]
			else: out += "- %s\n" % s.split("/")[-1]
		return out
	).call()
	var exts = (func():
		var out := ""
		var arr: PackedStringArray
		for s in paths:
			var ext = s.get_extension()
			if arr.has(ext): continue
			arr.append(ext)
			if arr.size() == 1: out += ext
			else: out += ", %s" % ext
		return out
	).call()
	#_error_dialogue.title = &"Error"
	_error_dialogue.set_text("Error:\nExtension '%s'\n%s not supported.\n\nCannot load: \n%s\n" % [exts, "is" if exts.split(",").size() == 1 else "are",strs])

func _throw_max_error() -> void:
	if _error_max_dialogue == null:
		_error_max_dialogue = Alert.create("Error: Peserta maksimal %d." % MAX_SIZE)
		_error_max_dialogue.yes.hide()
		_error_max_dialogue.no.text = "OK"

func _create_loading_screen() -> void:
	var instance: PanelContainer = _loading_scene.instantiate()
	MainMenu.ui_node.add_child(instance)
	set_meta(&"loading", instance)
	
func _remove_loading_screen() -> void:
	(func():
		if has_meta(&"loading") and is_instance_valid(get_meta(&"loading")):
			get_meta(&"loading").queue_free()
	).call_deferred()
