class_name Main
extends Node

@export var rng_seed: String
@export var cell_scene: PackedScene

## Um dicionario Vector2i : bool que contem todas as posicoes de celulas vivas e se elas continuarao 
## vivas no proximo step
var alive_nodes: Dictionary = {}

var process_counter: float = 0
var steps_per_second: float = 10

@onready var world: Node2D = $World
@onready var play_pause_button: Button = $"GUI/Play-Pause Button"

var next_step_finished: bool = true

func _ready() -> void:
	Global.main = self
	Global.rng.seed = hash(rng_seed)
	
	if steps_per_second == 0:
		steps_per_second = 1
	
	set_process(false)


func _process(delta: float) -> void:
	process_counter += delta
	
	if process_counter >= 1/steps_per_second:
		process_next_step()
		process_counter = 0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and next_step_finished:
			var cell_pos: Vector2i = Vector2i(world.get_global_mouse_position())
			
			if not alive_nodes.has(cell_pos):
				alive_nodes[cell_pos] = true
				
				var instance: Node2D = cell_scene.instantiate() 
				world.add_child(instance)
				instance.position = cell_pos
				print(cell_pos)


func process_next_step() -> void:
	if not next_step_finished:
		return
	
	next_step_finished = false
	
	var cells_to_check = {}
	for cell in alive_nodes:
		for x in range(-1, 2):
			for y in range(-1, 2):
				cells_to_check[cell + Vector2i(x, y)] = true
	
	var next_generation = {}
	for cell in cells_to_check:
		var neighbor_count = get_neighbor_count(cell)
	
		if neighbor_count == 3 or (neighbor_count == 2 and alive_nodes.has(cell)):
			next_generation[cell] = true
	
	alive_nodes = next_generation
	
	set_next_generation()
	print("Step Completed")
	next_step_finished = true


## Spawna ou despawna celulas dependendo se o valor delas for true ou false, respectivamente. Apos
## isso, remove todas as celulas com o valor false da lista
func set_next_generation() -> void:
	for cell_obj in world.get_children():
		world.remove_child(cell_obj)
		cell_obj.queue_free()
	
	for key in alive_nodes.keys():
		if alive_nodes[key]:
			var instance: Node2D = cell_scene.instantiate() 
			world.add_child(instance)
			instance.position = key
		else:
			alive_nodes.erase(key)


func get_neighbor_count(pos: Vector2i) -> int:
	var neighbor_count = 0
	
	for x2 in range(-1, 2):
		for y2 in range(-1, 2):
			if alive_nodes.has(pos + Vector2i(x2,y2)):
				if not (x2 == 0 and y2 == 0):
					neighbor_count += 1
	
	return neighbor_count


func _on_play_pause_button_toggled(toggled_on: bool) -> void:
	play_pause_button.text = "Pause" if toggled_on else "Play"
	set_process(toggled_on)
