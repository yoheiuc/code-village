extends SceneTree

const MainScene = preload("res://scenes/main.tscn")
const GrowthEvent = preload("res://scripts/village/growth_event.gd")

func _init() -> void:
	var root_node = MainScene.instantiate()
	root.add_child(root_node)
	await process_frame
	await process_frame

	var hud = root_node.get_node("MainHud")
	var save_data := Dictionary(root_node.save_data)
	var state = root_node.village_state
	var previous_flowers := int(state.flowers)

	if bool(save_data.get("onboarding_guide_dismissed", true)):
		_fail("onboarding guide should start visible in a fresh temporary save")
		return
	if Array(save_data.get("repositories", [])).size() != 0:
		_fail("fresh Start Village test should not require Git repositories")
		return

	hud.onboarding_start_button.pressed.emit()
	await process_frame
	await process_frame

	save_data = Dictionary(root_node.save_data)
	state = root_node.village_state
	var activity_events := Array(save_data.get("activity_events", []))
	var growth_events := Array(save_data.get("growth_events", []))

	if not bool(save_data.get("onboarding_guide_dismissed", false)):
		_fail("Start Village should dismiss the onboarding guide")
		return
	if activity_events.is_empty() or String(Dictionary(activity_events[0]).get("type", "")) != "village_started":
		_fail("Start Village should create a village_started activity event")
		return
	if String(Dictionary(activity_events[0]).get("source", "")) != "onboarding":
		_fail("village_started should remain an onboarding event, not Git or Claude activity")
		return
	if String(Dictionary(activity_events[0]).get("repository_id", "repo")) != "":
		_fail("village_started should not require or imply a Git repository")
		return
	if growth_events.is_empty() or String(Dictionary(growth_events[0]).get("type", "")) != GrowthEvent.TYPE_PLAZA_DECORATED:
		_fail("Start Village should create plaza_decorated growth")
		return
	if int(state.flowers) != previous_flowers + 1:
		_fail("Start Village should make one small visible village change")
		return

	root_node.queue_free()
	print("Start Village onboarding test passed.")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
