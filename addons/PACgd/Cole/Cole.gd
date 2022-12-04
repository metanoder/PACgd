extends Character

func _ready():
	SPEED = 5
	MINIMUM_WALKABLE_DISTANCE = 0.5
	talk_bubble_offset = Vector3(0, 9.7, 0)
	
	secondary_action = ACTIONS.none
	main_action = ACTIONS.none
	get_nav_agent()

func get_nav_agent():
	super()
	print(nav_agent, " From Cole: nav_agent var")
