extends Node3D

# This is the main script for the Level.

func _ready():
	# For the players, we need to define their "navigation" and "camera"
	# properties.
	# - The Node3D node will guide our character through the level, telling
	#   him which paths to follow to go from one place to the other
	# - The Camera3D lets the player know which direction he should be facing when
	#   moving around 
#	$Cole.navigation = $Node3D_floor/NavigationRegion3D
	$Cole.navigation = NavigationServer3D
	$Cole.camera = $Camera3D
	$Cole.nav_mesh = $Node3D_floor
	$Cole.nav_map_id = $Node3D_floor/NavigationRegion3D.get_region_rid()
	
	# We need to initialize our point and click system letting it know:
	# - Who's the player
	$PointClick.init($Cole)
