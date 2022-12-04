extends Interactive
class_name Character

# A player is basically a queue of actions that is constantly running
var STATES = preload("res://addons/PACgd/scripts/Character/States.gd")
var queue = preload("res://addons/PACgd/scripts/Character/Queue.gd").Queue.new()

# They know where the camera is, where they can walk
var camera
var navigation
var nav_agent
var nav_mesh
var nav_map_id

func get_nav_agent():
	nav_agent = $NavigationAgent3D

# They have an inventory
var inventory = Inventory.new()

# Their NODE has an animation player, a sprite, and a talk bubble
@onready var animation_player = $Animations
@onready var talk_bubble = $TalkBubble
@onready var sprite = $Sprite2D

# 3D characters have an offset for their bubble that helps to position it in the scene
var talk_bubble_offset = Vector3(0, 0, 0)

# They have a speed, and they don't move if the destination is close
var SPEED = 5
var MINIMUM_WALKABLE_DISTANCE = .5

# They can signal after finising actions
signal player_finished
signal message(signal_name)

# If you click checked them you will talk to them
func _ready():
	main_action = ACTIONS.talk_to
	secondary_action = ACTIONS.examine


# GODOT Function
# We constantly check if it has an action to run
var doing = false  # -> for emiting a signal after finishing an action
func _physics_process(_delta):
	# Process the queue
	var current_action = queue.current()

	if current_action:
		doing = true
		current_action.run()
	elif doing:
		doing = false
		emit_signal("player_finished")


# Internal Functions
func face_direction(direction):
	var my_pos = camera.unproject_position(position)
	var dir = camera.unproject_position(position + direction)
	
	if dir.x < my_pos.x:
		sprite.scale.x = -abs(sprite.scale.x)
	else:
		sprite.scale.x = abs(sprite.scale.x)

func interrupt():
	if queue.clear():
		play_animation("idle")

func play_animation(animation):
	animation_player.play(animation)

func say_now(text):
	talk_bubble.set_text(text)
	talk_bubble.visible = true

func quiet():
	talk_bubble.visible = false
	talk_bubble.set_text("")


# Functions to populate the queue in response to clicks in objects
func add_to_inventory(object):
	queue.append(STATES.AddToInventory.new(self, object))

func animate(animation):
	queue.append(STATES.Animate.new(self, animation))

func animate_until_finished(animation):
	queue.append(STATES.AnimateUntilFinished.new(self, animation))

func call_function_from(object, function, params=[]):
	if not params is Array:
		printerr("parameters should be an array")
		queue.append(STATES.State.new())
	else:
		queue.append(STATES.InteractWithObject.new(self, object, function, params))

func internal(fc, params):
	queue.append(STATES.CallFunction.new(self, fc, params))

func emit_message(signal_message):
	queue.append(STATES.Emit.new(self, signal_message))

func emit_finished_signal():
	queue.append(STATES.Finished.new(self))

func face_object(object):
	queue.append(STATES.FaceObject.new(self, object))

func remove_from_inventory(object):
	queue.append(STATES.RemoveFromInventory.new(self, object))

func say(text, how_long=2):
	queue.append(STATES.Say.new(self, text, how_long))

func wait_on_character(who:Character, message:String):
	queue.append(STATES.WaitOnCharacter.new(self, who, message))

func approach(object):
	assert(navigation != null) #,"You forgot to set the navigation of " + oname)

#	been having problems with this one...
#	navigation variable is a node3d but function used was originally vector3
#	looks like i had to assign from level the NavigationRegion3d, and get RID from it

#	if not object.interaction_position: return

#	var end = navigation.get_closest_point(object.interaction_position)
	var end = navigation.map_get_closest_point(nav_map_id, object.interaction_position)
	print (nav_map_id, " map id")
	print (object.interaction_position, "end")
	print (navigation, " navigation variable")
	print (position, " position")
	print (end, " ...end")
	
	var tot_length = (end - position)
	print(tot_length, " == end - position")
	print(tot_length.length(), " calling .length")
	
	if (end - position).length() > MINIMUM_WALKABLE_DISTANCE:
		# We actually need to walk
		var begin = nav_agent.map_get_closest_point(position)
		var path = nav_agent.NavigationServer.map_get_path(begin, end, true)

		queue.append(STATES.Animate.new(self, "walk"))
		queue.append(STATES.WalkPath.new(self, path))
		queue.append(STATES.FaceObject.new(self, object))
		queue.append(STATES.Animate.new(self, "idle"))
		
		print (begin, " walk func works")
	else:
		queue.append(STATES.State.new()) # queue nothing to keep signals working
		print ("position length is not more than origin point, nothing happens")

# Default answers to actions
func receive_item(who, item):
	# Remove item
	who.animate_until_finished("raise_hand")
	who.remove_from_inventory(item)
	who.animate_until_finished("lower_hand")
	who.emit_message("gave_item")
	
	# Take item
	self.animate_until_finished("raise_hand")
	self.animate_until_finished("lower_hand")
	self.wait_on_character(who, "gave_item")
	self.add_to_inventory(item)

func talk_to(who):
	who.approach(self)
	who.emit_message("arrived")
	
	# Called when main_action is invoqued by the click
	self.wait_on_character(who, "arrived")
	self.face_object(who)
	self.say("Hi " + who.name)
