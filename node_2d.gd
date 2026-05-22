extends Node2D

class Variable:
    var x = "Salwa"
    var y = "Hawa"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    var x = await PiyanScriptingLanguage.new()
    x.from_path("res://test.psl")
    await get_tree().create_timer(1).timeout

    OS.execute("code.cmd", [ProjectSettings.globalize_path("res://test.psl")], [])
    

    
    
