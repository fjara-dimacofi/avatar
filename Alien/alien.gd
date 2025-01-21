extends Node3D

@onready var animation_player: AnimationPlayer = $"mouth rig/AnimationPlayer"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var rhubarb_relative_path = "res://rhubarb-lib-sync/rhubarb.exe"
	var rhubarb_path = ProjectSettings.globalize_path(rhubarb_relative_path)
	
	var file_rel_path = "res://flaca.wav"
	var file_path = ProjectSettings.globalize_path(file_rel_path)
	var arguments = ["-r", "phonetic", file_path]
	var output = []
	var exit_code = OS.execute(rhubarb_path, arguments, output, true, true)
	print(output)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
