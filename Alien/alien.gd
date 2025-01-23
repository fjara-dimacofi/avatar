extends Node3D

@onready var animation_player: AnimationPlayer = $"mouth rig/AnimationPlayer"
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamVoice
const RhubarbParser = preload("res://rhubarb_parser.gd")

var wait_timer: float = 0.5
var curr_animation: String = "B"
var mouth_positions = []
var next_mouth_position = 0
var time_since_start: float = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	const file_rel_path = "res://flaca.wav"
	var file_path = ProjectSettings.globalize_path(file_rel_path)
	var rhubarb_parser = RhubarbParser.new()
	match OS.get_name():
		"Windows":
			const rhubarb_relative_path = "res://rhubarb-lip-sync/rhubarb.exe"
			var rhubarb_path = ProjectSettings.globalize_path(rhubarb_relative_path)
			var windows_rhubarb_path = rhubarb_path.replace("/", "\\")	
			var windows_file_path = file_path.replace("/", "\\")
			var arguments = ["/C", windows_rhubarb_path, "-r", "phonetic", "--extendedShapes", "A", windows_file_path]
			var output = []
			var exit_code = OS.execute("cmd.exe", arguments, output)
			mouth_positions = rhubarb_parser.parse(output[0])
		"Linux":
			var arguments = ["-r", "phonetic", "--extendedShapes", "", file_path]
			var output = []
			var exit_code = OS.execute("rhubarb", arguments, output)
			mouth_positions = rhubarb_parser.parse(output[0])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if true:
		return
	if abs(wait_timer) < 0.01:
		audio_stream_player.play()
		time_since_start = 0
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

		
	
