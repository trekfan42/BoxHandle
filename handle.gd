@tool
extends Panel

@onready var parent_container = self.get_parent()

@export var handleWidth: float = 5.0:
	set(value):
		handleWidth = value
		update_handle_width()

var panels := []
var dragging := false
var initial_mouse_pos := Vector2.ZERO
var initial_ratios := []
var total_size := 0.0
var handle_index := -1

func _ready():
	
	
	await get_tree().process_frame  # Ensure correct size after initialization
	total_size = parent_container.size.y if parent_container is VBoxContainer else parent_container.size.x

	# Detect panels dynamically, but EXCLUDE handles based on name
	for i in range(parent_container.get_child_count()):
		var child = parent_container.get_child(i)
		
		# If name contains "handle", it's ignored; otherwise, it's a panel
		if not child.name.to_lower().contains("handle"):
			panels.append(child)

	# Determine which panels this handle affects
	handle_index = int(get_index() / 2)  # Every other Control is a handle

func update_handle_width():
	if parent_container is VBoxContainer:
		self.custom_minimum_size = Vector2(0,handleWidth)
	if parent_container is HBoxContainer:
		self.custom_minimum_size = Vector2(handleWidth,0)

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = true
		initial_mouse_pos = get_global_mouse_position()

		# Store initial ratios of all panels
		initial_ratios.clear()
		for panel in panels:
			initial_ratios.append(panel.size_flags_stretch_ratio)

	elif event is InputEventMouseButton and !event.pressed:
		dragging = false


func _process(_delta):
	if dragging:
		var current_mouse_pos = get_global_mouse_position()
		var delta_pos = (current_mouse_pos.y - initial_mouse_pos.y) if parent_container is VBoxContainer else (current_mouse_pos.x - initial_mouse_pos.x)

		# Convert movement into percentage of total space
		var ratio_change = delta_pos / float(total_size)

		# Identify affected panels
		var panel_before = handle_index
		var panel_after = handle_index + 1

		if panel_after >= panels.size():  # Prevent out-of-bounds errors
			return

		# Adjust ratios of only the two affected panels
		var new_ratio_before = max(0.01, initial_ratios[panel_before] + ratio_change)  # Prevent collapse
		var new_ratio_after = max(0.01, initial_ratios[panel_after] - ratio_change)  # Prevent collapse

		# Preserve all other panels' ratios exactly
		var new_ratios = initial_ratios.duplicate()
		new_ratios[panel_before] = snapped(new_ratio_before, 0.001)
		new_ratios[panel_after] = snapped(new_ratio_after, 0.001)

		# Apply new ratios to only the affected panels
		panels[panel_before].size_flags_stretch_ratio = new_ratios[panel_before]
		panels[panel_after].size_flags_stretch_ratio = new_ratios[panel_after]
