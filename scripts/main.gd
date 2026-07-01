extends Node2D

const ActivityEventScript = preload("res://scripts/activity/activity_event.gd")
const ClaudeCodeActivityIngestorScript = preload("res://scripts/activity/claude_code_activity_ingestor.gd")
const GitActivityScannerScript = preload("res://scripts/activity/git_activity_scanner.gd")
const RepositoryConfigScript = preload("res://scripts/config/repository_config.gd")
const ResidentMessageProviderScript = preload("res://scripts/dialogue/resident_message_provider.gd")
const SaveManagerScript = preload("res://scripts/save/save_manager.gd")
const UserSettingsScript = preload("res://scripts/config/user_settings.gd")
const GrowthRuleEngineScript = preload("res://scripts/village/growth_rule_engine.gd")
const VillageStateScript = preload("res://scripts/village/village_state.gd")

const CLAUDE_INBOX_POLL_INTERVAL := 10.0

@onready var village_view = $Village
@onready var hud = $MainHud

var save_manager
var claude_ingestor = ClaudeCodeActivityIngestorScript.new()
var scanner = GitActivityScannerScript.new()
var growth_rule_engine = GrowthRuleEngineScript.new()
var resident_message_provider = ResidentMessageProviderScript.new()
var save_data: Dictionary = {}
var village_state = VillageStateScript.new()
var claude_inbox_timer: Timer

func _ready() -> void:
	randomize()
	save_manager = SaveManagerScript.new()
	add_child(save_manager)
	save_data = save_manager.load_game()
	village_state = VillageStateScript.new().load_from_dict(Dictionary(save_data.get("village_state", {})))

	hud.repository_submitted.connect(_on_repository_submitted)
	hud.claude_code_import_requested.connect(_import_claude_code_events)
	hud.scan_requested.connect(_scan_registered_repositories)
	hud.tests_passed_requested.connect(_add_tests_passed)
	hud.manual_session_requested.connect(_add_manual_coding_session)
	hud.manual_reflection_requested.connect(_add_manual_reflection)
	hud.repository_removed_requested.connect(_remove_current_repository)
	hud.save_deleted_requested.connect(_delete_local_save)
	hud.onboarding_dismiss_requested.connect(_dismiss_onboarding_guide)
	hud.auto_import_toggled.connect(_set_auto_import_claude_events)

	_setup_claude_inbox_auto_import()
	_refresh_views()
	_show_save_recovery_status_if_needed()
	_import_claude_code_events(false)

func _on_repository_submitted(path: String) -> void:
	if path == "":
		hud.set_status("Path is empty.")
		return
	if not scanner.can_scan_path(path):
		hud.set_status("登録できません。ローカル Git repo path を指定してください。")
		return

	var repo = RepositoryConfigScript.new().setup_from_path(path).to_dict()
	var repositories: Array = Array(save_data.get("repositories", []))
	for existing in repositories:
		if String(Dictionary(existing).get("local_path", "")) == String(repo.get("local_path", "")):
			hud.set_status("この repo は登録済みです。")
			return

	repositories.append(repo)
	save_data["repositories"] = repositories
	var project_event = ActivityEventScript.new().setup(ActivityEventScript.TYPE_PROJECT_ADDED, "manual", String(repo["id"]))
	_apply_activity_events([project_event])
	_save()
	hud.set_status("Repo registered locally.")
	_scan_registered_repositories()

func _scan_registered_repositories() -> void:
	var repositories: Array = Array(save_data.get("repositories", []))
	if repositories.is_empty():
		hud.set_status("まずローカル Git repo を登録してください。")
		return

	var all_activity_events: Array = []
	var errors: Array[String] = []
	for index in range(repositories.size()):
		var repo := Dictionary(repositories[index])
		var result = scanner.scan_repository(repo)
		if result["ok"]:
			var metadata := Dictionary(result["metadata"])
			repo["last_scanned_at"] = String(metadata.get("scanned_at", Time.get_datetime_string_from_system(true)))
			repo["last_scan_metadata"] = metadata
			repositories[index] = repo
			all_activity_events.append_array(Array(result["events"]))
		errors.append_array(Array(result["errors"]))

	save_data["repositories"] = repositories
	if all_activity_events.is_empty():
		_add_rest_message_if_needed()
		hud.set_status("Scan complete. 大きな変化はありません。")
	else:
		_apply_activity_events(all_activity_events)
		hud.set_status("Scan complete. %d event(s)." % all_activity_events.size())

	if not errors.is_empty():
		hud.set_status("Scan finished with warning: %s" % String(errors[0]))

	_save()
	_refresh_views()

func _add_manual_coding_session() -> void:
	var event = ActivityEventScript.new().setup(ActivityEventScript.TYPE_CLAUDE_CODE_SESSION, "manual")
	_apply_activity_events([event])
	hud.set_status("Claude Code use logged.")
	_save()
	_refresh_views()

func _setup_claude_inbox_auto_import() -> void:
	claude_inbox_timer = Timer.new()
	claude_inbox_timer.wait_time = CLAUDE_INBOX_POLL_INTERVAL
	claude_inbox_timer.one_shot = false
	claude_inbox_timer.autostart = true
	claude_inbox_timer.timeout.connect(_on_claude_inbox_timer_timeout)
	add_child(claude_inbox_timer)

func _on_claude_inbox_timer_timeout() -> void:
	_import_claude_code_events(false)

func _import_claude_code_events(show_empty_status: bool = true) -> void:
	var settings = UserSettingsScript.new().load_from_dict(Dictionary(save_data.get("settings", {})))
	if not settings.auto_import_claude_events and not show_empty_status:
		return

	var imported_ids: Array = Array(save_data.get("imported_activity_event_ids", []))
	var known_ids := _known_claude_activity_event_ids(imported_ids)
	var checkpoint := Dictionary(save_data.get("claude_activity_import_checkpoint", {}))
	var result := claude_ingestor.import_events(known_ids, checkpoint)
	if not result["ok"]:
		if show_empty_status:
			hud.set_status("Claude inbox import failed: %s" % String(Array(result["errors"]).front()))
		return
	var events := Array(result["events"])
	var new_ids := Array(result["imported_ids"])
	if bool(result.get("checkpoint_changed", false)):
		save_data["claude_activity_import_checkpoint"] = Dictionary(result.get("checkpoint", {}))
		if events.is_empty():
			_save()
	if events.is_empty():
		if show_empty_status:
			_add_rest_message_if_needed()
			_save()
			_refresh_views()
			hud.set_status("No new Claude Code events. Inbox: %s" % String(result["inbox_path"]))
		return
	imported_ids = _push_recent_imported_ids(imported_ids, new_ids)
	save_data["imported_activity_event_ids"] = imported_ids
	_apply_activity_events(events)
	var prefix := "Imported" if show_empty_status else "Auto imported"
	hud.set_status("%s %d Claude Code event(s)." % [prefix, events.size()])
	_save()
	_refresh_views()

func _add_tests_passed() -> void:
	var event = ActivityEventScript.new().setup(ActivityEventScript.TYPE_TESTS_PASSED, "manual")
	_apply_activity_events([event])
	hud.set_status("Passing tests logged.")
	_save()
	_refresh_views()

func _add_manual_reflection(note: String) -> void:
	if note == "":
		hud.set_status("短い振り返りを書いてください。")
		return
	var safe_note := note.substr(0, 160)
	var event = ActivityEventScript.new().setup(
		ActivityEventScript.TYPE_MANUAL_REFLECTION_ADDED,
		"manual",
		"",
		{"note": safe_note},
		ActivityEventScript.PRIVACY_MANUAL_NOTE,
	)
	_apply_activity_events([event])
	hud.set_status("Diary line added.")
	_save()
	_refresh_views()

func _remove_current_repository() -> void:
	var repositories: Array = Array(save_data.get("repositories", []))
	if repositories.is_empty():
		hud.set_status("登録済み repo はありません。")
		return
	var removed_repo := Dictionary(repositories.pop_front())
	save_data["repositories"] = repositories
	_save()
	_refresh_views()
	hud.set_status("Removed local repo: %s" % String(removed_repo.get("display_name", "local repo")))

func _delete_local_save() -> void:
	if not save_manager.delete_save():
		hud.set_status("保存データを削除できませんでした。")
		return
	save_data = save_manager.get_default_save()
	village_state = VillageStateScript.new().load_from_dict(Dictionary(save_data.get("village_state", {})))
	_refresh_views()
	hud.set_status("Local save deleted. 村は新しい朝に戻りました。")

func _dismiss_onboarding_guide() -> void:
	save_data["onboarding_guide_dismissed"] = true
	_save()
	_refresh_views()
	hud.set_status("Guide hidden. 村はここにあります。")

func _set_auto_import_claude_events(enabled: bool) -> void:
	var settings = UserSettingsScript.new().load_from_dict(Dictionary(save_data.get("settings", {})))
	settings.auto_import_claude_events = enabled
	save_data["settings"] = settings.to_dict()
	_save()
	_refresh_views()
	hud.set_status("Claude auto import %s." % ("on" if enabled else "off"))
	if enabled:
		_import_claude_code_events(false)

func _show_save_recovery_status_if_needed() -> void:
	if save_manager == null:
		return
	if String(save_manager.last_load_warning) == "":
		return
	hud.set_status("Local save recovered. Using safe defaults.")

func _apply_activity_events(activity_events: Array) -> void:
	var growth_events = growth_rule_engine.generate_growth_events(activity_events)
	var stored_activity: Array = Array(save_data.get("activity_events", []))
	var stored_growth: Array = Array(save_data.get("growth_events", []))

	for activity in activity_events:
		if activity != null and activity.has_method("to_dict"):
			stored_activity.push_front(activity.to_dict())

	for growth_event in growth_events:
		var message := resident_message_provider.message_for_growth_event(growth_event)
		village_state.apply_growth_event(growth_event, message)
		stored_growth.push_front(growth_event.to_dict())

	if not growth_events.is_empty():
		call_deferred("_show_growth_events", growth_events.duplicate())

	_trim_array(stored_activity, 200)
	_trim_array(stored_growth, 200)
	save_data["activity_events"] = stored_activity
	save_data["growth_events"] = stored_growth
	save_data["village_state"] = village_state.to_dict()

func _show_growth_events(growth_events: Array) -> void:
	if village_view != null and village_view.has_method("show_growth_events"):
		village_view.show_growth_events(growth_events)

func _add_rest_message_if_needed() -> void:
	var settings = UserSettingsScript.new().load_from_dict(Dictionary(save_data.get("settings", {})))
	if not settings.show_rest_day_messages:
		return
	var latest: String = village_state.get_latest_resident_message()
	var rest_message: String = resident_message_provider.rest_day_message()
	if latest != rest_message:
		village_state.add_resident_message(rest_message)
		save_data["village_state"] = village_state.to_dict()

func _save() -> void:
	save_data["village_state"] = village_state.to_dict()
	save_manager.save_game(save_data)

func _refresh_views() -> void:
	village_view.set_village_state(village_state)
	hud.update_state(village_state, save_data)

func _trim_array(target: Array, max_size: int) -> void:
	while target.size() > max_size:
		target.pop_back()

func _known_claude_activity_event_ids(imported_ids: Array) -> Array:
	var lookup := {}
	var result: Array = []
	for id in imported_ids:
		_add_known_id(result, lookup, String(id))
	for activity in Array(save_data.get("activity_events", [])):
		var activity_dict := Dictionary(activity)
		if String(activity_dict.get("source", "")) == "claude_code_hook":
			_add_known_id(result, lookup, String(activity_dict.get("id", "")))
	for growth_event in Array(save_data.get("growth_events", [])):
		var growth_dict := Dictionary(growth_event)
		var activity_event_id := String(growth_dict.get("activity_event_id", ""))
		if activity_event_id.begins_with("claude-"):
			_add_known_id(result, lookup, activity_event_id)
	return result

func _push_recent_imported_ids(imported_ids: Array, new_ids: Array) -> Array:
	var result := imported_ids.duplicate()
	for id in new_ids:
		var id_string := String(id)
		if id_string == "":
			continue
		while result.has(id_string):
			result.erase(id_string)
		result.push_front(id_string)
	_trim_array(result, 500)
	return result

func _add_known_id(target: Array, lookup: Dictionary, id: String) -> void:
	if id == "" or lookup.has(id):
		return
	lookup[id] = true
	target.append(id)
