extends Node

var effect
var recording
var recording_name: String = "user_voice.wav"
var recording_path = "user://" + recording_name
var response_path = "user://llm_voice.mp3"
var _thread = Thread.new()
var context: String = ""
signal voice_response_ready

func _ready() -> void:
	var idx = AudioServer.get_bus_index("Record")
	effect = AudioServer.get_bus_effect(idx, 0)
	voice_response_ready.connect(_thread.wait_to_finish)

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
		recording.save_to_wav(recording_path)
		_thread.start(_speech_to_text)
	else:
		effect.set_recording_active(true)

func _speech_to_text():
	var arguments = ["run", "stt.py", ProjectSettings.globalize_path(recording_path)]
	var output = []
	OS.execute("uv", arguments, output)
	var result = output[0].rstrip("\n").lstrip(" ")
	_text_to_llm(result)

func _text_to_llm(text):
	var output = []
	var command = "echo '" + context + text + "'| uv run llm.py"
	OS.execute("sh", ["-c", command], output)
	var result = output[0].rstrip("\n")
	context += "<User>" + text + "</User>" + "<LLMResponse>" + result + "</LLMResponse>"
	_llm_to_voice(result)
	
func _llm_to_voice(text):
	var output = []
	var wav_response_path = "user://llm_voice.wav"
	var command = "echo " + text + \
	 " | .venv/bin/piper --model voices/es_MX-claude-high.onnx --output_file " \
	+ ProjectSettings.globalize_path(wav_response_path)
	OS.execute("sh", ["-c", command], output, true)
	OS.execute("ffmpeg", ["-y", "-i", ProjectSettings.globalize_path(wav_response_path), ProjectSettings.globalize_path(response_path)], output, true)
	print("recording ready")
	call_deferred("emit_signal", "voice_response_ready")


func _exit_tree() -> void:
	_thread.wait_to_finish()
