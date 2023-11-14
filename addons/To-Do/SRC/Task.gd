tool
extends HBoxContainer

signal state_changed(task)
signal content_changed()
signal task_removed(task, save)
signal move_up(task)
signal move_down(task)
signal start_task_timer(task)
signal stop_task_timer(task)
signal note_button_pressed(task)
signal favourite_pressed(task, starred)
signal color_tag_changed(task, color_tag)

const InfoBox = preload("res://addons/To-Do/SRC/TaskInfo.tscn")

# In Godot 4 the defaults will probably need to be changed to match the UI colour cheme
const DEFAULT_BORDER_COLOUR = "#202531" #LineEdit's default border
const DEFAULT_BG_COLOUR = "#262c3b" #LineEdit's default background
const DEFAULT_PICKER_RECT_COLOUR = "#2a3142" #A little lighter version of the default background, to stand out better
const TASK_BG_ALPHA:float = 0.08
const TASK_BORDER_ALPHA:float = 0.7

export var content:String
onready var label = $"%LineEdit"
onready var check_box = $"%CheckBox"
onready var color_tag_button = $"%ColorTagButton"
onready var move_up_button = $"%MoveUpButton"
onready var move_down_button = $"%MoveDownButton"
onready var start_timer_button = $"%TimerStartButton"
onready var stop_timer_button = $"%TimerStopButton"
onready var task_note_button = $"%TaskNoteButton"
onready var favourite_button = $"%FavouriteButton"
onready var colour_picker = $"%ColorPickerPopup"
onready var colour_tag_rect = $"%ColortagRect"
onready var color_picker_popup = $"%ColorPickerPopup"

var note_icon = preload("res://addons/To-Do/Icons/File.svg")
var new_note_icon = preload("res://addons/To-Do/Icons/New.svg")
var id:int
var completed := false
var has_note:bool = false
var data:Dictionary
var is_starred:bool = false
var color_tag:String = DEFAULT_BG_COLOUR
var new_stylebox_normal

func _ready():
	
	label.text = content
	check_box.pressed = completed
	label.editable = not completed
	favourite_button.pressed = is_starred
	if data.empty() :
		print("data empty")
		data = {
			"name" : content,
			"addition_time" : "...",
			"state" : "Completed" if completed else "Incomplete",
			"completion_time" : "..."
		}
	
	data.state = "Completed" if completed else "Incomplete"
	new_stylebox_normal = label.get_stylebox("normal").duplicate()
	
	# Set up colour tag picker, and the task's colour to match the colour tag
	_on_color_picked(Color(color_tag))
#	if color_tag == DEFAULT_BG_COLOUR:
#		colour_tag_rect.color = Color(DEFAULT_PICKER_RECT_COLOUR)
#		new_stylebox_normal.border_color = Color(DEFAULT_BORDER_COLOUR)
#		new_stylebox_normal.bg_color = Color(DEFAULT_BG_COLOUR)
#	else:
#		colour_tag_rect.color = Color(color_tag)
#		var new_border_color = Color(color_tag)
#		new_border_color.a = TASK_BORDER_ALPHA
#		new_stylebox_normal.border_color = new_border_color
#		var new_bg_color = Color(color_tag)
#		new_bg_color.a = TASK_BG_ALPHA
#		new_stylebox_normal.bg_color = new_bg_color
#	label.add_stylebox_override("normal", new_stylebox_normal)	
	
	colour_tag_rect.rect_size.y = color_tag_button.rect_size.y - 8
	colour_tag_rect.rect_size.x = color_tag_button.rect_size.x - 8
	colour_tag_rect.rect_position = Vector2(4,4)



func _on_CheckBox_toggled(button_pressed):
	completed = button_pressed
	if not data.empty() :
		if completed :
			favourite_button.visible = false
			label.editable = false
			start_timer_button.disabled = true
			data.state = "Completed"
			if data.completion_time == "..." :
				data.completion_time = Time.get_datetime_string_from_system(false, true)
		else :
			favourite_button.visible = true
			label.editable = true
			start_timer_button.disabled = false
			data.state = "Incomplete"
			if not data.completion_time == "..." :
				# there was a tpypo preventing "completion time to be reset to "..."
				data.completion_time = "..."

	# Sets the View/add note button
	set_has_note(has_note)
	
	emit_signal("state_changed", self)


func _on_DeleteButton_pressed():
	emit_signal("task_removed", self, true)


func _on_LineEdit_text_changed(new_text):
	if new_text == content :
		return
	content = new_text
	emit_signal("content_changed")


func _on_InfoButton_pressed():
	var ins = InfoBox.instance()
	
	if data.empty() :
		ins.text = "data isn't available"
	else :
		var text = "Name : %s \n Addition Time : %s \n State : %s \n Completion Time : %s \n"
		var formated_text = text%[data.name, data.addition_time,
		data.state, data.completion_time]
		ins.text = formated_text
	
	$"../../..".add_child(ins)

# Does what it says
func _on_MoveUpButton_pressed():
	emit_signal("move_up", self)

# Does what it says
func _on_MoveDownButton_pressed():
	emit_signal("move_down", self)

# Does what it says
func _on_TimerStartButton_pressed():
	start_timer_button.visible = false
	stop_timer_button.visible = true
	emit_signal("start_task_timer", self)

# Does what it says
func _on_TimerStopButton_pressed():
	start_timer_button.visible = true
	stop_timer_button.visible = false
	emit_signal("stop_task_timer", self)

# Not even using this, dunno why it's there
func set_task_id(value):
	id = value

# Not even using this, dunno why it's there	
func get_task_id() -> int:
	return id

# Does what it says
func _on_TaskNoteButton_pressed():
	emit_signal("note_button_pressed", self)

# Set up task-note button and tooltip
func set_has_note(value:bool):
	has_note = value
	if has_note:
		task_note_button.icon = note_icon
		
		task_note_button.disabled = false
		if completed:
			task_note_button.hint_tooltip = "View note linked to this task (read only)"
		else:
			task_note_button.hint_tooltip = "View and edit note linked to this task"
	else:
		
		task_note_button.disabled = completed
		if completed:
			task_note_button.icon = note_icon
			task_note_button.hint_tooltip = "Cannot assign notes to completed tasks"
		else:
			task_note_button.icon = new_note_icon
			task_note_button.hint_tooltip = "Add new note linked to this task"


func _on_FavouriteButton_toggled(button_pressed):
	is_starred = button_pressed
	
	if is_starred:
		move_down_button.disabled = true
		move_up_button.disabled = true
	else:
		move_down_button.disabled = false
		move_up_button.disabled = false
	emit_signal("favourite_pressed", self, is_starred)

	

# This will show the colour picker popup right above the button
func _on_ColorTagButton_pressed():
	color_picker_popup.set_global_position(color_tag_button.rect_global_position + Vector2(15,15) - Vector2(0, color_picker_popup.rect_size.y))
	color_picker_popup.popup()


# Sets the colour_tag and changes the colour of the picker and the task
func _on_color_picked(color):
	if color != Color(DEFAULT_BG_COLOUR):
		color_tag = "#" + color.to_html(false)
		colour_tag_rect.color = Color(color_tag)
		var new_border_color = Color(color_tag)
		new_border_color.a = TASK_BORDER_ALPHA
		new_stylebox_normal.border_color = new_border_color
		var new_bg_color = Color(color_tag)
		new_bg_color.a = TASK_BG_ALPHA
		new_stylebox_normal.bg_color = new_bg_color
	else:
		color_tag = DEFAULT_BG_COLOUR
		colour_tag_rect.color = Color(DEFAULT_PICKER_RECT_COLOUR)
		new_stylebox_normal.border_color = Color(DEFAULT_BORDER_COLOUR)
		new_stylebox_normal.bg_color = Color(DEFAULT_BG_COLOUR)
	
	label.add_stylebox_override("normal", new_stylebox_normal)
	emit_signal("color_tag_changed", self, color_tag)

# All the ColorRects from the grid have signals connected to this one function.
# extra_arg_0 is the hardcoded #HEX colur vale of the colourrect
func _on_Color_gui_input(event, extra_arg_0):
	if event is InputEventMouseButton and event.is_pressed():
		# Set the colour and hide the popup
		_on_color_picked(extra_arg_0) 
		color_picker_popup.hide()



# Reset the colour to default and hide the popup
func _on_ClearColorButton_pressed():
	_on_color_picked(Color(DEFAULT_BG_COLOUR))
	color_picker_popup.hide()
