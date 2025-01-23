extends Node

var effect
var recording
var recording_name: String = "user_voice.wav"

func _ready() -> void:
	var idx = AudioServer.get_bus_index("Record")
	effect = AudioServer.get_bus_effect(idx, 0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event):
	if event.is_action_pressed("toggle_record") or event.is_action_released("toggle_record"):
		_toggle_record()
func _toggle_record():
	if effect.is_recording_active():
		recording = effect.get_recording()
		effect.set_recording_active(false)
		var save_path = "user://" + recording_name
		recording.save_to_wav(save_path)
	else:
		effect.set_recording_active(true)
