extends Control

onready var loading_dialog: WindowDialog = $DialogBoxes/LoadingDialog
onready var loading_dialog_progress: ProgressBar = $DialogBoxes/LoadingDialog/VBoxContainer/ProgressBar
onready var export_progress: WindowDialog = $DialogBoxes/ExportProgress
onready var export_progress_bar: ProgressBar = $DialogBoxes/ExportProgress/VBoxContainer/ProgressBar
onready var file_dialog: FileDialog = $DialogBoxes/FileDialog
onready var sequencer: Node = $Application/Main/SongEditor/Sequencer
onready var instrument_panel: VBoxContainer = $Application/InstrumentsPanel

func load_instruments():
	var dir = Directory.new()
	dir.open("res://Instruments")
	dir.list_dir_begin(true, true)

	var instruments = []

	var instrument_name = dir.get_next()
	while instrument_name != "":
		if dir.file_exists("./%s/Instrument.tscn" % instrument_name):
			instruments.append(instrument_name)
		else:
			push_warning("Instrument %s does not have an Instrument.tscn file" % instrument_name)

		instrument_name = dir.get_next()

	loading_dialog_progress.max_value = instruments.size()

	for name in instruments:
		$DialogBoxes/LoadingDialog/VBoxContainer/Label.text = name

		yield(get_tree(), "idle_frame")
		var instrument: PackedScene = load("%s/%s/Instrument.tscn" % [dir.get_current_dir(), name])
		GoDAW.register_instrument(name, instrument)
		loading_dialog_progress.value += 1

	loading_dialog.hide()
	$Application/InstrumentsPanel.reload_instruments()

func _on_TopMenu_export_pressed():
	file_dialog.popup_centered()
	var path = yield(file_dialog, "file_selected")

	var recorder = AudioEffectRecord.new()
	AudioServer.add_bus_effect(0, recorder, AudioServer.get_bus_effect_count(0))

	export_progress.popup_centered()
	sequencer.connect("on_note", export_progress_bar, "set_value")
	
	recorder.set_recording_active(true)
	sequencer.play()
	yield(sequencer, "playback_finished")
	recorder.set_recording_active(false)

	var recording = recorder.get_recording()
	recording.save_to_wav(path)
	export_progress.hide()

func _ready():
	# Editor Setup
	
	# Set Font
	var font = get_theme().get_default_font().font_data
	instrument_panel.title.get_font("font", "Label").font_data = font
	
	#load instruments
	loading_dialog.popup()
	yield(load_instruments(), "completed")
	
	test()

# This function is solely test code
func test():
	var example: SongScript = preload("res://Example.gd").new()
	example.entry()
	sequencer.sequence(example.sequence)
