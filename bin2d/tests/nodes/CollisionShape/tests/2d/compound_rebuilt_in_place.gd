extends PhysicsUnitTest2D


# A static body with a concave CollisionPolygon2D holds its convex pieces in one compound collider,
# anchored on the first shape. Giving the polygon new points makes Godot remove every shape and add
# the new ones. Removing the anchor used to drop the compound's handle before the compound was torn
# down, so the old collider stayed in the world: invisible to queries, but still solid.

const FLOOR_Y := 300.0
const DROP := 150.0
const BALL_RADIUS := 10.0
const MOVE_FRAME := 60
const CHECK_FRAME := 150

var simulation_duration := 4
var outline: CollisionPolygon2D
var ball: RigidBody2D

func test_description() -> String:
	return """Checks that when a concave [CollisionPolygon2D] on a static body gets new points,
	nothing keeps colliding with the old shape.
	"""

func test_name() -> String:
	return "CollisionShape2D | a compound rebuilt in place leaves no collider behind"

# A U-shaped floor: concave, so Godot splits it into several convex pieces.
func u_floor(top: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(CENTER.x - 200, top - 60), Vector2(CENTER.x - 150, top - 60),
		Vector2(CENTER.x - 150, top), Vector2(CENTER.x + 150, top),
		Vector2(CENTER.x + 150, top - 60), Vector2(CENTER.x + 200, top - 60),
		Vector2(CENTER.x + 200, top + 40), Vector2(CENTER.x - 200, top + 40)])

func test_start() -> void:
	var ground := StaticBody2D.new()
	outline = CollisionPolygon2D.new()
	outline.polygon = u_floor(FLOOR_Y)
	ground.add_child(outline)
	add_child(ground)

	ball = RigidBody2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = BALL_RADIUS
	shape.shape = circle
	ball.add_child(shape)
	ball.position = Vector2(CENTER.x, FLOOR_Y - 50)
	ball.can_sleep = false
	add_child(ball)

	var checks = func(_p_target: PhysicsUnitTest2D, p_monitor: GenericManualMonitor):
		if p_monitor.frame == MOVE_FRAME:
			outline.polygon = u_floor(FLOOR_Y + DROP)
		if p_monitor.frame != CHECK_FRAME:
			return

		p_monitor.add_test("A body falls onto the floor's new position")
		var resting_y := FLOOR_Y + DROP - BALL_RADIUS
		var landed := absf(ball.position.y - resting_y) < 5.0
		if not landed:
			p_monitor.add_test_error("Ball rested at y=%.1f, expected near y=%.1f (the old floor is at y=%.1f)."
				% [ball.position.y, resting_y, FLOOR_Y - BALL_RADIUS])
		p_monitor.add_test_result(landed)
		p_monitor.monitor_completed()

	create_generic_manual_monitor(self, checks, simulation_duration)
