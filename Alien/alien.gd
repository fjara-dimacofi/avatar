extends Node3D

@onready var animation_player: AnimationPlayer = $"mouth rig/AnimationPlayer"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var rhubarb_relative_path = "res://rhubarb-lip-sync/rhubarb.exe"
	var rhubarb_path = ProjectSettings.globalize_path(rhubarb_relative_path)
	var windows_rhubarb_path = rhubarb_path.replace("/", "\\")
	
	var file_rel_path = "res://flaca.wav"
	var file_path = ProjectSettings.globalize_path(file_rel_path)
	var windows_file_path = file_path.replace("/", "\\")
	var arguments = ["/C", windows_rhubarb_path, "-r", "phonetic", "--extendedShapes", "A", windows_file_path]
	var output = []
	var exit_code = OS.execute("cmd.exe", arguments, output)
	print(output)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
