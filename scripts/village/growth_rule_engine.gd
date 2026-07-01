extends RefCounted
class_name GrowthRuleEngine

const ActivityEventScript = preload("res://scripts/activity/activity_event.gd")
const GrowthEventScript = preload("res://scripts/village/growth_event.gd")

func generate_growth_events(activity_events: Array) -> Array:
	var growth_events: Array = []
	for activity in activity_events:
		if activity != null:
			growth_events.append_array(_events_for_activity(activity))
	return growth_events

func _events_for_activity(activity) -> Array:
	match activity.type:
		ActivityEventScript.TYPE_CLAUDE_CODE_SESSION:
			return [_claude_session_growth(activity)]
		ActivityEventScript.TYPE_CLAUDE_CODE_TURN_COMPLETED:
			return [_simple_growth(
				activity,
				GrowthEventScript.TYPE_FLOWER_BLOOMED,
				"対話の花",
				"工房のそばに、対話の花がひとつ咲きました。",
				"commit_flower",
			)]
		ActivityEventScript.TYPE_COMMIT_CREATED:
			return [_commit_growth(activity)]
		ActivityEventScript.TYPE_TESTS_PASSED:
			return [_simple_growth(
				activity,
				GrowthEventScript.TYPE_LANTERN_LIT,
				"テストの灯り",
				"小さな灯りが増えました。テストが通った日の光です。",
				"test_lantern",
			)]
		ActivityEventScript.TYPE_DOCS_UPDATED:
			return [_simple_growth(
				activity,
				GrowthEventScript.TYPE_LIBRARY_EXPANDED,
				"図書館のページ",
				"図書館に新しいページが増えました。",
				"docs_library",
			)]
		ActivityEventScript.TYPE_REFACTOR_DETECTED:
			return [_simple_growth(
				activity,
				GrowthEventScript.TYPE_PATH_REPAIRED,
				"整った小道",
				"今日の道、少し歩きやすくなった気がします。",
				"refactor_path",
			)]
		ActivityEventScript.TYPE_BUGFIX_DETECTED:
			return [_simple_growth(
				activity,
				GrowthEventScript.TYPE_BRIDGE_REPAIRED,
				"静かな橋",
				"橋のきしみが少し静かになりました。",
				"debug_bridge",
			)]
		ActivityEventScript.TYPE_RELEASE_TAG_CREATED:
			return [_simple_growth(
				activity,
				GrowthEventScript.TYPE_BELL_RANG,
				"リリースの鐘",
				"広場の鐘が短く鳴りました。区切りのしるしです。",
				"release_bell",
			)]
		ActivityEventScript.TYPE_BRANCH_CREATED:
			return [_simple_growth(
				activity,
				GrowthEventScript.TYPE_BRANCH_TREE_GREW,
				"枝分かれの木",
				"枝の先に、新しい試みの芽が出ました。",
				"branch_tree",
			)]
		ActivityEventScript.TYPE_PROJECT_ADDED:
			return [_simple_growth(
				activity,
				GrowthEventScript.TYPE_WORKSHOP_UPGRADED,
				"新しい作業机",
				"工房に新しい机が入りました。",
				"build_workshop",
			)]
		ActivityEventScript.TYPE_VILLAGE_STARTED:
			return [_simple_growth(
				activity,
				GrowthEventScript.TYPE_PLAZA_DECORATED,
				"村のはじまり",
				"広場に小さな目印が置かれました。",
				"plaza",
			)]
		ActivityEventScript.TYPE_MANUAL_CODING_SESSION:
			return [_simple_growth(
				activity,
				GrowthEventScript.TYPE_RESIDENT_MESSAGE_ADDED,
				"住民のひとこと",
				"工房の窓に、短いメモが残っています。",
				"resident",
			)]
		ActivityEventScript.TYPE_MANUAL_REFLECTION_ADDED:
			return [_manual_reflection_growth(activity)]
		_:
			return []

func _commit_growth(activity):
	var count := int(activity.metadata.get("commit_count_24h", 1))
	var intensity := clampi(count, 1, 3)
	return _new_growth_event(
		GrowthEventScript.TYPE_FLOWER_BLOOMED,
		activity.id,
		"コミットの花",
		"花がひとつ咲きました。小さな一歩のしるしです。",
		"commit_flower",
		intensity,
	)

func _claude_session_growth(activity):
	var project_label := String(activity.metadata.get("project_label", "")).strip_edges()
	var description := "工房に小さな灯りが入りました。Claude Code と過ごした時間のしるしです。"
	if project_label != "":
		description = "%s の工房に小さな灯りが入りました。" % project_label
	return _new_growth_event(
		GrowthEventScript.TYPE_WORKSHOP_UPGRADED,
		activity.id,
		"Claude Code の工房",
		description,
		"build_workshop",
		1,
	)

func _simple_growth(
		activity,
		growth_type: String,
		title: String,
		description: String,
		visual_target: String
	):
	return _new_growth_event(growth_type, activity.id, title, description, visual_target, 1)

func _manual_reflection_growth(activity):
	var note := String(activity.metadata.get("note", "")).strip_edges().substr(0, 160)
	var description := "今日のことが、村の日記に一行増えました。"
	if note != "":
		description = note
	return _new_growth_event(
		GrowthEventScript.TYPE_DIARY_ENTRY_CREATED,
		activity.id,
		"村の日記",
		description,
		"village_diary",
		1,
	)

func _new_growth_event(
		growth_type: String,
		activity_event_id: String,
		title: String,
		description: String,
		visual_target: String,
		intensity: int
	):
	return GrowthEventScript.new().setup(growth_type, activity_event_id, title, description, visual_target, intensity)
