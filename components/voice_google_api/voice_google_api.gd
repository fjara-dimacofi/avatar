extends Node

var effect
var recording
var is_recording: bool = false
var pipe := StreamPeerTCP.new()
var server_address := "127.0.0.1"
var server_port := 5000
var buffer: PackedByteArray
var last_pos: int = 0

var recording_name: String = "user_voice.wav"
var recording_path = "user://" + recording_name
var mp3_response_path = "user://llm_voice.mp3"
var wav_response_path = "user://llm_voice.wav"

var _thread = Thread.new()
var context: String = ""
signal voice_response_ready

func _ready() -> void:
	var idx = AudioServer.get_bus_index("Record")
	effect = AudioServer.get_bus_effect(idx, 0)
	_connect_to_server()

func _process(_delta: float) -> void:
	if is_recording and effect.is_recording_active():
		pipe.poll()
		var recorded_audio = effect.get_recording()
		if recorded_audio:
			var full_buffer = recorded_audio.get_data()
			var current_pos = full_buffer.size()
			
			# Only get the new data since last read
			if current_pos > last_pos:
				var new_data = full_buffer.slice(last_pos, current_pos)
				_send_audio_chunk(new_data)
				last_pos = current_pos
func _input(event):
	if event.is_action_pressed("toggle_record") or event.is_action_released("toggle_record"):
		_toggle_record()

func _toggle_record():
	if is_recording:
		is_recording = false
		effect.set_recording_active(false)
		if pipe.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			var size = 0
			var size_bytes = PackedByteArray()
			size_bytes.resize(4)
			size_bytes.encode_u32(0, size)
			pipe.put_data(size_bytes)
	else:
		print("recording")
		effect.set_recording_active(true)
		is_recording = true
		
func _send_audio_chunk(audio_data: PackedByteArray):
	if pipe.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		var size = audio_data.size()
		var size_bytes = PackedByteArray()
		size_bytes.resize(4)
		size_bytes.encode_u32(0, size)
		pipe.put_data(size_bytes + audio_data)

func _connect_to_server():
	var err = pipe.connect_to_host(server_address, server_port)
	if err != OK:
		print("Connection failed")
	else:
		print("Connected to Python")

func _speech_to_text():
	var arguments = ["run", "stt_google.py", ProjectSettings.globalize_path(recording_path)]
	var output = []
	OS.execute("uv", arguments, output)
	var result = output[0].rstrip("\r\n").lstrip(" ")
	print(result)
	_text_to_llm(result)

func _text_to_llm(text):
	var output = []
	var command = 'echo "<Context>'  + context + '</Context>' + text + '" | uv run llm_google.py'
	match OS.get_name():
		"Windows":
			OS.execute("cmd.exe", ["/C", command], output)
			print(output)
		"Linux":
			command = "echo '<Context>" + context + "</Context>"+ text + "'" + " | uv run llm.py" 
			OS.execute("sh", ["-c", command], output)
			print(command)
			print(output)
	var result = output[0].rstrip("\r\n").replace("'", "").replace('"', "")
	context += "<User>" + text + "</User>" + "<LLMResponse>" + result + "</LLMResponse>"
	print(result)
	_llm_to_voice(result)
	
func _llm_to_voice(text):
	var output = []

	match OS.get_name():
		"Windows":
			var command = "'" + text + "' | Out-File -FilePath tmp -NoNewline -Encoding UTF8" \
			+ "; uv run ./tts_google.py tmp " \
			+ ProjectSettings.globalize_path(wav_response_path) \
			+ '; Remove-Item -Path tmp -Force'
			print(command)
			OS.execute("powershell.exe", ["-Command", '"' + command + '"'], output, true)
			print(output)
		"Linux":
			var command = "echo '" + text + "'" + \
			" | .venv/bin/piper --model voices/es_MX-claude-high.onnx --output_file " \
			+ ProjectSettings.globalize_path(wav_response_path)
			OS.execute("sh", ["-c", command], output, true)
			print(command)
			print(output)
	OS.execute("ffmpeg", [
		"-y", "-i",
		 ProjectSettings.globalize_path(wav_response_path),
		 ProjectSettings.globalize_path(mp3_response_path)],
		 output)
	print("recording ready")
	call_deferred("emit_signal", "voice_response_ready")


func _exit_tree() -> void:
	_thread.wait_to_finish()
