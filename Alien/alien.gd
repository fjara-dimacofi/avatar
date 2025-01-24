extends Node3D

@onready var animation_player: AnimationPlayer = $"mouth rig/AnimationPlayer"
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamVoice
@onready var voice_recorder: Node = $VoiceRecorder
const RhubarbParser = preload("res://rhubarb_parser.gd")
const GdScriptAudioImport = preload("res://GDScriptAudioImport.gd")

var wait_timer: float = -1
var curr_animation: String = "B"
var mouth_positions = []
var next_mouth_position = 0
var time_since_start: float = 0
var pending_dialog: bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	voice_recorder.voice_response_ready.connect(_generate_rhubarb_lipsync)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if abs(wait_timer) < 0.01 and pending_dialog:
		audio_stream_player.play()
		time_since_start = 0
		pending_dialog = false
	if not audio_stream_player.playing and wait_timer < 0:
		animation_player.play("A")
		wait_timer = 0.5
		next_mouth_position = 0
	
	if audio_stream_player.playing and next_mouth_position < mouth_positions.size():
		var timestamp = mouth_positions[next_mouth_position][0]
		var mouth_position = mouth_positions[next_mouth_position][1]
		
		if time_since_start > timestamp:
			animation_player.play(mouth_position, 0.2)
			next_mouth_position += 1
		time_since_start += delta
	
	wait_timer -= delta
	
func _generate_rhubarb_lipsync():
	var mp3file = FileAccess.open(voice_recorder.mp3_response_path, FileAccess.READ)
	var sound = AudioStreamMP3.new()
	sound.data = mp3file.get_buffer(mp3file.get_length())
	audio_stream_player.stream = sound
	var wav_file_path = ProjectSettings.globalize_path(voice_recorder.wav_response_path)
	var rhubarb_parser = RhubarbParser.new()
	match OS.get_name():
		"Windows":
			const rhubarb_relative_path = "res://rhubarb-lip-sync/rhubarb.exe"
			var rhubarb_path = ProjectSettings.globalize_path(rhubarb_relative_path)
			var windows_rhubarb_path = rhubarb_path.replace("/", "\\")	
			var windows_file_path = wav_file_path.replace("/", "\\")
			var arguments = ["/C", windows_rhubarb_path, "-r", "phonetic", "--extendedShapes", "A", windows_file_path]
			var output = []
			var exit_code = OS.execute("cmd.exe", arguments, output)
			mouth_positions = rhubarb_parser.parse(output[0])
		"Linux":
			var arguments = ["-r", "phonetic", "--extendedShapes", "", wav_file_path]
			var output = []
			var exit_code = OS.execute("rhubarb", arguments, output)
			mouth_positions = rhubarb_parser.parse(output[0])
	pending_dialog = true
