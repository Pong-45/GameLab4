class_name Stat
extends Node2D

@export var data={}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func data_add(key:String, val=1):
	return data_set(key,data_get(key)+val)

func data_get(key:String,default=0):
	key = key.to_lower()
	if !data.has(key) : return default
	return data[key]

func data_set(key:String, val=1):
	key = key.to_lower()
	if key.find("_max")>0 || key.find("_min")>0 :
		data[key] = val
	else:	
		var max = data_get(key+"_max",999999)
		var min = data_get(key+"_min",0)
		data[key] = clamp(val,min,max)
	return data[key]

func get_percent(key:String):
	var max = data_get(key+"_max",100)
	var min = data_get(key+"_min",0)
	var val = data_get(key)
	if max<=0 : max=100
	return remap(val,min,max,0,100)	
