extends Node

var effect
var recording
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
		_thread.start(_speech_to_llm)
	else:
		print("recording")
		effect.set_recording_active(true)

func _speech_to_llm():
	const instance_name = "instance-20250205-202855"
	const target_path = "/home/fjara/"
	const zone = "southamerica-east1-c"
	var scp_command = \
		'"C:/Users/fjara/AppData/Local/Google/Cloud SDK/google-cloud-sdk/bin/gcloud"' + \
		" compute " + \
		"scp " + \
		ProjectSettings.globalize_path(recording_path) + " " +\
		instance_name + ":" + target_path + " " +  \
		"--zone=" + zone
	OS.execute(
		"cmd.exe",
	 	["/C", scp_command]
	)
	print("Voice recording sent.")
	# Get IP
	var ip_command = \
		"gcloud compute instances describe " + \
	 	instance_name + \
		" --zone="+zone + \
		' --format="get(networkInterfaces[0].accessConfigs[0].natIP)"'
	var ip_output = []
	OS.execute(
		"cmd.exe",
		["/C", ip_command],
		ip_output,
		true
	)
	var instance_ip = ip_output[0].rstrip("\r\n")
	print(instance_ip)
	var script_command = \
		"ssh " + \
		"-i C:/Users/fjara/.ssh/google_compute_engine " + \
		"fjara@" + instance_ip + \
		' "/home/fjara/whisper/.venv/bin/python ' + \
		'/home/fjara/whisper/main.py ' + \
		'/home/fjara/' + recording_name + '"'
	var script_output = []
	OS.execute(
		"powershell.exe",
		["-Command", script_command],
		script_output,
		true
	)
	var result = script_output[0]
	print(result)
	_llm_to_voice(result)
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
			OS.execute("powershell.exe", ["-Command", '"' + command + '"'], output, true)
			print(output[0])
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

func _on_bathroom_pressed() -> void:
	var text = "El baño está en el pasillo de al fondo a la derecha"
	_thread.start(_llm_to_voice.bind(text))

func _on_gate_pressed() -> void:
	var text = "Sigue caminando por este pasillo hasta la señalética, luego\
	 dobla a la derecha y te encontrarás con las puertas de embarque"
	_thread.start(_llm_to_voice.bind(text))

func _on_hello_pressed() -> void:
	var text = "Hola! En que puedo ayudarte?"
	_thread.start(_llm_to_voice.bind(text))
