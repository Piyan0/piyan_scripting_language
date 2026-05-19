extends Node2D

class Variable:
    var x = "Salwa"
    var y = "Hawa"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    var x = await PiyanScript.new()
    x.from_text("res://test.txt")
    
    
