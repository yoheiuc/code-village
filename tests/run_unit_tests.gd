extends SceneTree

const ActivityEvent = preload("res://scripts/activity/activity_event.gd")
const AssetCatalog = preload("res://scripts/assets/asset_catalog.gd")
const ClaudeCodeActivityIngestor = preload("res://scripts/activity/claude_code_activity_ingestor.gd")
const GitActivityScanner = preload("res://scripts/activity/git_activity_scanner.gd")
const ResidentMessageProvider = preload("res://scripts/dialogue/resident_message_provider.gd")
const MainHUD = preload("res://scripts/ui/main_hud.gd")
const UserSettings = preload("res://scripts/config/user_settings.gd")
const GrowthEvent = preload("res://scripts/village/growth_event.gd")
const GrowthRuleEngine = preload("res://scripts/village/growth_rule_engine.gd")
const SaveManager = preload("res://scripts/save/save_manager.gd")
const VillageSpriteLayer = preload("res://scripts/village/village_sprite_layer.gd")
const VillageTileLayer = preload("res://scripts/village/village_tile_layer.gd")
const VillageState = preload("res://scripts/village/village_state.gd")

var failures: Array[String] = []

func _init() -> void:
	_test_asset_catalog_manifest()
	_test_growth_rule_engine()
	_test_claude_code_session_growth()
	_test_claude_code_ingestor_sanitizes_and_dedupes()
	_test_claude_code_ingestor_checkpoint_skips_trimmed_old_events()
	_test_claude_code_ingestor_ignores_oversized_malformed_line()
	_test_claude_code_inbox_grows_village_without_git()
	_test_manual_reflection_becomes_diary_text()
	_test_village_state()
	_test_main_hud_does_not_prefill_local_repo_path()
	_test_privacy_defaults()
	_test_git_scanner_guardrails()
	_test_git_scanner_metadata_only()
	_test_git_scanner_empty_repo()
	_test_git_scanner_duplicate_suppression()
	_test_git_scanner_detached_head()
	_test_git_scanner_worktree()
	_test_save_manager_delete_save()
	_test_save_manager_recovers_from_invalid_save()

	if failures.is_empty():
		print("All Code Village tests passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _test_asset_catalog_manifest() -> void:
	var catalog = AssetCatalog.new()
	_assert(catalog.load_manifest(), "asset manifest should load")
	_assert(catalog.mode() == "placeholder", "asset manifest should mark placeholder mode")
	_assert(catalog.tile_size() == 16, "asset manifest should define 16px tile size")
	_assert(catalog.reference_resolution() == Vector2(1280, 720), "asset manifest should define reference resolution")
	_assert(catalog.asset_exists("tiles", "grass"), "asset manifest should point to placeholder grass")
	_assert(catalog.asset_exists("buildings", "workshop"), "asset manifest should point to placeholder workshop")
	_assert(catalog.asset_exists("environment", "tree"), "asset manifest should point to placeholder environment tree")
	_assert(catalog.asset_exists("environment", "plaza_core"), "asset manifest should point to placeholder plaza core")
	_assert(catalog.asset_exists("characters", "resident_a"), "asset manifest should point to placeholder resident")
	_assert(catalog.asset_exists("characters", "lamp_moth"), "asset manifest should point to placeholder lamp moth companion")
	_assert(catalog.asset_exists("ui", "settings"), "asset manifest should point to placeholder settings icon")
	_assert(catalog.asset_exists("effects", "growth_pulse"), "asset manifest should point to placeholder growth effect")
	_assert(catalog.asset_exists("effects", "lantern_light_pulse"), "asset manifest should point to placeholder lantern effect")
	_assert(catalog.asset_exists("effects", "workshop_glow"), "asset manifest should point to placeholder workshop effect")
	_assert(catalog.growth_visual_exists("workshop_upgraded"), "growth visual should exist for workshop growth")
	_assert(catalog.growth_visual_path("unknown_growth") == "", "unknown growth visual should be absent safely")
	_assert(not catalog.growth_effect_anchor("commit_flower").is_empty(), "growth effect anchor should exist for commit flowers")
	for effect_target in [
		"commit_flower",
		"test_lantern",
		"docs_library",
		"refactor_path",
		"debug_bridge",
		"release_bell",
		"branch_tree",
		"build_workshop",
		"resident",
		"village_diary",
	]:
		var anchor := catalog.growth_effect_anchor(effect_target)
		var effect_path := String(anchor.get("path", ""))
		_assert(effect_path.begins_with("res://assets/placeholders/effects/"), "growth effect anchor should use placeholder effect path for %s" % effect_target)
		_assert(FileAccess.file_exists(effect_path), "growth effect placeholder should exist for %s" % effect_target)
	_assert(catalog.placeholder_color("grass", "#ffffff") != Color.WHITE, "placeholder palette should return manifest color")
	_assert(catalog.sprite_layout().size() >= 8, "asset manifest should define key Sprite2D placements")
	_assert(catalog.state_visual_rules().size() >= 6, "asset manifest should define state-driven visual overlays")

	var sprite_layer = VillageSpriteLayer.new()
	sprite_layer.setup(catalog)
	_assert(sprite_layer.sprite_count() >= 15, "VillageSpriteLayer should instantiate placeholder sprites")
	_assert(sprite_layer.load_errors.is_empty(), "VillageSpriteLayer should load placeholder sprites without errors")
	_assert(sprite_layer.has_sprite("workshop"), "VillageSpriteLayer should include workshop sprite")
	_assert(sprite_layer.has_sprite("debug_bridge"), "VillageSpriteLayer should include bridge sprite")
	_assert(sprite_layer.has_sprite("plaza_core"), "VillageSpriteLayer should include plaza sprite")
	_assert(sprite_layer.has_sprite("tree_northwest"), "VillageSpriteLayer should include environment tree sprites")
	_assert(sprite_layer.has_sprite("lamp_moth"), "VillageSpriteLayer should include the first placeholder companion")
	var lamp_moth = sprite_layer.sprites.get("lamp_moth")
	_assert(is_instance_valid(lamp_moth) and lamp_moth.has_meta("idle_motion"), "placeholder companion should have manifest-driven idle motion")
	var growth_state = VillageState.new()
	growth_state.flowers = 7
	growth_state.lanterns = 3
	growth_state.repaired_paths = 1
	growth_state.bridge_state = "repaired"
	growth_state.library_level = 2
	growth_state.workshop_level = 2
	growth_state.branch_tree_level = 2
	growth_state.release_bell_rings = 1
	sprite_layer.apply_village_state(growth_state)
	_assert(sprite_layer.growth_sprite_count("flower") == 7, "VillageSpriteLayer should render flowers from VillageState")
	_assert(sprite_layer.growth_sprite_count("lantern") == 3, "VillageSpriteLayer should render lanterns from VillageState")
	_assert(sprite_layer.state_sprite_count() >= 6, "VillageSpriteLayer should render manifest state overlays from VillageState")
	var effect_event = GrowthEvent.new().setup(
		GrowthEvent.TYPE_FLOWER_BLOOMED,
		"activity-effect",
		"effect",
		"effect visible",
		"commit_flower",
		1,
	)
	sprite_layer.show_growth_events([effect_event])
	_assert(sprite_layer.effect_sprite_count() == 1, "VillageSpriteLayer should render transient growth event effect")
	var effect_sprite = sprite_layer.effect_sprites.values()[0]
	_assert(effect_sprite.texture.get_width() >= 80, "transient growth effect should use the manifest effect asset")
	var lantern_event = GrowthEvent.new().setup(
		GrowthEvent.TYPE_LANTERN_LIT,
		"activity-lantern-effect",
		"lantern effect",
		"lantern effect visible",
		"test_lantern",
		1,
	)
	var library_event = GrowthEvent.new().setup(
		GrowthEvent.TYPE_LIBRARY_EXPANDED,
		"activity-library-effect",
		"library effect",
		"library effect visible",
		"docs_library",
		1,
	)
	sprite_layer.show_growth_events([effect_event, lantern_event, library_event, lantern_event])
	_assert(sprite_layer.effect_sprite_count() == 3, "VillageSpriteLayer should cap transient growth effects at three sprites")
	sprite_layer.free()

	var tile_layer = VillageTileLayer.new()
	tile_layer.setup(catalog)
	_assert(tile_layer.built, "VillageTileLayer should build TileMapLayer")
	_assert(tile_layer.tile_set != null, "VillageTileLayer should own a TileSet")
	_assert(tile_layer.get_used_cells().size() > 0, "VillageTileLayer should paint terrain cells")
	_assert(tile_layer.get_cell_source_id(Vector2i(40, 22)) == 0, "VillageTileLayer should paint plaza center")
	tile_layer.free()

func _test_growth_rule_engine() -> void:
	var activity = ActivityEvent.new().setup(
		ActivityEvent.TYPE_COMMIT_CREATED,
		"test",
		"repo-test",
		{"commit_count_24h": 9},
	)
	var engine = GrowthRuleEngine.new()
	var growth_events = engine.generate_growth_events([activity])
	_assert(growth_events.size() == 1, "commit activity should create one growth event")
	_assert(growth_events[0].type == GrowthEvent.TYPE_FLOWER_BLOOMED, "commit should bloom flower")
	_assert(growth_events[0].intensity == 3, "commit intensity should be capped")

func _test_claude_code_session_growth() -> void:
	var activity = ActivityEvent.new().setup(
		ActivityEvent.TYPE_CLAUDE_CODE_SESSION,
		"test",
		"",
		{"project_label": "code-village"},
	)
	var engine = GrowthRuleEngine.new()
	var growth_events = engine.generate_growth_events([activity])
	_assert(growth_events.size() == 1, "Claude Code session should create one growth event")
	_assert(growth_events[0].type == GrowthEvent.TYPE_WORKSHOP_UPGRADED, "Claude Code session should grow workshop")
	_assert(growth_events[0].description.find("code-village") != -1, "Claude Code session should keep safe project label")

func _test_claude_code_ingestor_sanitizes_and_dedupes() -> void:
	var inbox_path = OS.get_cache_dir().path_join("code_village_claude_inbox_%d.jsonl" % randi())
	var file = FileAccess.open(inbox_path, FileAccess.WRITE)
	_assert(file != null, "Claude Code inbox test file should be writable")
	if file != null:
		file.store_line(JSON.stringify({
			"id": "claude-test-1",
			"type": ActivityEvent.TYPE_CLAUDE_CODE_SESSION,
			"occurred_at": "2026-07-01T00:00:00Z",
			"source": "claude_code_hook",
			"metadata": {
				"project_label": "code-village",
				"hook_event": "Stop",
				"session_hash": "abc123",
				"prompt": "secret prompt text",
				"cwd": "/Users/example/private-project",
			},
			"prompt": "top level secret",
		}))
		file.store_line(JSON.stringify({
			"id": "claude-test-2",
			"type": ActivityEvent.TYPE_CLAUDE_CODE_TURN_COMPLETED,
			"occurred_at": "2026-07-01T00:01:00Z",
			"source": "claude_code_hook",
			"metadata": {
				"project_label": "/Users/example/private-project",
				"hook_event": "Stop",
				"session_hash": "def456",
			},
		}))
		file.close()

	var ingestor = ClaudeCodeActivityIngestor.new()
	ingestor.inbox_path = inbox_path
	var first_result = ingestor.import_events([])
	_assert(first_result["ok"], "Claude Code inbox import should succeed")
	_assert(Array(first_result["events"]).size() == 2, "Claude Code inbox should import safe events")
	var event = Array(first_result["events"])[0]
	var encoded = JSON.stringify(event.to_dict())
	_assert(encoded.find("secret prompt text") == -1, "Claude Code inbox should not keep prompt text")
	_assert(encoded.find("private-project") == -1, "Claude Code inbox should not keep raw cwd")
	_assert(String(event.metadata.get("project_label", "")) == "code-village", "Claude Code inbox should keep safe project label")
	var path_event = Array(first_result["events"])[1]
	var path_encoded = JSON.stringify(path_event.to_dict())
	_assert(String(path_event.metadata.get("project_label", "")) == "private-project", "Claude Code inbox should reduce project_label path to basename")
	_assert(path_encoded.find("/Users/example/private-project") == -1, "Claude Code inbox should not store raw project_label path")

	var second_result = ingestor.import_events(Array(first_result["imported_ids"]))
	_assert(Array(second_result["events"]).is_empty(), "Claude Code inbox should dedupe imported IDs")

func _test_claude_code_ingestor_checkpoint_skips_trimmed_old_events() -> void:
	var inbox_path = OS.get_cache_dir().path_join("code_village_claude_checkpoint_%d.jsonl" % randi())
	var file = FileAccess.open(inbox_path, FileAccess.WRITE)
	_assert(file != null, "Claude Code checkpoint inbox test file should be writable")
	if file != null:
		_write_claude_inbox_line(file, "claude-checkpoint-old-1", ActivityEvent.TYPE_CLAUDE_CODE_SESSION)
		_write_claude_inbox_line(file, "claude-checkpoint-old-2", ActivityEvent.TYPE_CLAUDE_CODE_TURN_COMPLETED)
		file.close()

	var ingestor = ClaudeCodeActivityIngestor.new()
	ingestor.inbox_path = inbox_path
	var first_result = ingestor.import_events([])
	_assert(first_result["ok"], "Claude Code checkpoint first import should succeed")
	_assert(Array(first_result["events"]).size() == 2, "Claude Code checkpoint should import initial events")
	var checkpoint := Dictionary(first_result["checkpoint"])
	_assert(int(checkpoint.get("offset", 0)) > 0, "Claude Code checkpoint should store byte offset")

	var second_result = ingestor.import_events([], checkpoint)
	_assert(Array(second_result["events"]).is_empty(), "Claude Code checkpoint should skip old events even when imported ids are empty")

	var append_file = FileAccess.open(inbox_path, FileAccess.READ_WRITE)
	_assert(append_file != null, "Claude Code checkpoint inbox should be appendable")
	if append_file != null:
		append_file.seek_end()
		_write_claude_inbox_line(append_file, "claude-checkpoint-new-1", ActivityEvent.TYPE_CLAUDE_CODE_SESSION)
		append_file.close()

	var third_result = ingestor.import_events([], checkpoint)
	var third_events := Array(third_result["events"])
	_assert(third_events.size() == 1, "Claude Code checkpoint should import only appended events")
	if third_events.size() == 1:
		_assert(third_events[0].id == "claude-checkpoint-new-1", "Claude Code checkpoint should not re-import trimmed old ids")

	var fourth_result = ingestor.import_events([], Dictionary(third_result["checkpoint"]))
	_assert(Array(fourth_result["events"]).is_empty(), "Claude Code checkpoint should advance after appended import")
	DirAccess.remove_absolute(inbox_path)

func _test_claude_code_ingestor_ignores_oversized_malformed_line() -> void:
	var inbox_path = OS.get_cache_dir().path_join("code_village_claude_malformed_%d.jsonl" % randi())
	var file = FileAccess.open(inbox_path, FileAccess.WRITE)
	_assert(file != null, "Claude Code malformed inbox test file should be writable")
	if file != null:
		var oversized := "{"
		for index in range(9000):
			oversized += "x"
		file.store_line(oversized)
		_write_claude_inbox_line(file, "claude-malformed-valid-1", ActivityEvent.TYPE_CLAUDE_CODE_SESSION)
		file.close()

	var ingestor = ClaudeCodeActivityIngestor.new()
	ingestor.inbox_path = inbox_path
	var first_result = ingestor.import_events([])
	_assert(first_result["ok"], "Claude Code malformed import should succeed")
	_assert(Array(first_result["events"]).size() == 1, "Claude Code malformed import should keep valid events")
	_assert(Array(first_result["errors"]).size() == 1, "Claude Code malformed import should report oversized line once")
	_assert(int(Dictionary(first_result["checkpoint"]).get("offset", 0)) > 0, "Claude Code malformed import should advance checkpoint")
	var second_result = ingestor.import_events([], Dictionary(first_result["checkpoint"]))
	_assert(Array(second_result["events"]).is_empty(), "Claude Code malformed import should not re-read oversized line after checkpoint")
	DirAccess.remove_absolute(inbox_path)

func _test_claude_code_inbox_grows_village_without_git() -> void:
	var inbox_path = OS.get_cache_dir().path_join("code_village_claude_growth_%d.jsonl" % randi())
	var file = FileAccess.open(inbox_path, FileAccess.WRITE)
	_assert(file != null, "Claude Code growth inbox test file should be writable")
	if file != null:
		file.store_line(JSON.stringify({
			"id": "claude-growth-session",
			"type": ActivityEvent.TYPE_CLAUDE_CODE_SESSION,
			"occurred_at": "2026-07-01T00:00:00Z",
			"source": "claude_code_hook",
			"repository_id": "",
			"metadata": {
				"project_label": "code-village",
				"hook_event": "SessionStart",
			},
			"privacy_level": ActivityEvent.PRIVACY_METADATA_ONLY,
		}))
		file.store_line(JSON.stringify({
			"id": "claude-growth-turn",
			"type": ActivityEvent.TYPE_CLAUDE_CODE_TURN_COMPLETED,
			"occurred_at": "2026-07-01T00:01:00Z",
			"source": "claude_code_hook",
			"repository_id": "",
			"metadata": {
				"project_label": "code-village",
				"hook_event": "Stop",
			},
			"privacy_level": ActivityEvent.PRIVACY_METADATA_ONLY,
		}))
		file.close()

	var ingestor = ClaudeCodeActivityIngestor.new()
	ingestor.inbox_path = inbox_path
	var import_result = ingestor.import_events([])
	_assert(import_result["ok"], "Claude Code growth inbox import should succeed")
	var activity_events: Array = Array(import_result["events"])
	_assert(activity_events.size() == 2, "Claude Code growth inbox should import two events")
	for activity in activity_events:
		_assert(activity.repository_id == "", "Claude Code growth should not require a Git repository")
		_assert(activity.source == "claude_code_hook", "Claude Code growth should keep hook source")
		_assert(activity.privacy_level == ActivityEvent.PRIVACY_METADATA_ONLY, "Claude Code growth should remain metadata-only")

	var engine = GrowthRuleEngine.new()
	var growth_events = engine.generate_growth_events(activity_events)
	_assert(growth_events.size() == 2, "Claude Code inbox events should create growth without Git")

	var state = VillageState.new()
	var previous_workshop_level: int = state.workshop_level
	var previous_flowers: int = state.flowers
	var message_provider = ResidentMessageProvider.new()
	for growth_event in growth_events:
		state.apply_growth_event(growth_event, message_provider.message_for_growth_event(growth_event))

	_assert(state.workshop_level == previous_workshop_level + 1, "Claude Code session should upgrade the workshop without Git")
	_assert(state.flowers == previous_flowers + 1, "Claude Code turn should bloom a flower without Git")
	_assert(state.get_latest_resident_message() != "", "Claude Code growth should add a resident message")
	DirAccess.remove_absolute(inbox_path)

func _test_manual_reflection_becomes_diary_text() -> void:
	var activity = ActivityEvent.new().setup(
		ActivityEvent.TYPE_MANUAL_REFLECTION_ADDED,
		"test",
		"",
		{"note": "今日は保存まわりを少し整えた。"},
		ActivityEvent.PRIVACY_MANUAL_NOTE,
	)
	var engine = GrowthRuleEngine.new()
	var growth_events = engine.generate_growth_events([activity])
	_assert(growth_events.size() == 1, "manual reflection should create diary growth")
	_assert(growth_events[0].type == GrowthEvent.TYPE_DIARY_ENTRY_CREATED, "manual reflection should create diary entry")
	_assert(growth_events[0].description == "今日は保存まわりを少し整えた。", "manual reflection note should become diary text")

func _test_village_state() -> void:
	var state = VillageState.new()
	var event = GrowthEvent.new().setup(
		GrowthEvent.TYPE_LIBRARY_EXPANDED,
		"activity-test",
		"docs",
		"docs grew",
		"docs_library",
		1,
	)
	var previous_library_level = state.library_level
	state.apply_growth_event(event, "図書館に新しいページが増えました。")
	_assert(state.library_level == previous_library_level + 1, "library level should increase")
	_assert(not state.diary_entries.is_empty(), "diary should receive entry")
	_assert(not state.get_today_entries().is_empty(), "today diary should use local date like the HUD")
	_assert(state.get_latest_resident_message() != "", "resident message should be present")

	var release_event = GrowthEvent.new().setup(
		GrowthEvent.TYPE_BELL_RANG,
		"activity-release",
		"release",
		"bell rang",
		"release_bell",
		1,
	)
	var previous_bell_rings = state.release_bell_rings
	state.apply_growth_event(release_event, "広場の鐘が短く鳴りました。")
	_assert(state.release_bell_rings == previous_bell_rings + 1, "release bell rings should persist in VillageState")

func _test_main_hud_does_not_prefill_local_repo_path() -> void:
	var hud = MainHUD.new()
	hud._ready()
	_assert(hud.repo_input != null, "MainHUD should create optional Git repo input")
	_assert(hud.repo_input.text == "", "MainHUD should not prefill local repository path")
	_assert(hud.top_left_panel != null and hud.top_left_panel.name == "VillageStatusSign", "MainHUD should present status as a village sign")
	_assert(hud.top_right_panel != null and hud.top_right_panel.name == "VillageToolShelf", "MainHUD should present actions as a village tool shelf")
	_assert(hud.recent_growth_panel != null and hud.recent_growth_panel.name == "IssueBoardPlaque", "Recent growth should read like a village notice board")
	_assert(hud.diary_book_panel != null and hud.diary_book_panel.name == "VillageDiaryBook", "Diary should read like an in-world diary book")
	_assert(hud.resident_bubble_panel != null and hud.resident_bubble_panel.name == "ResidentSpeechBubble", "Resident message should read like an in-world speech bubble")
	_assert(hud.onboarding_panel != null and hud.onboarding_panel.name == "FirstRunGuideBoard", "First run guide should be a compact in-world board")
	_assert(hud.onboarding_welcome_label != null and hud.onboarding_welcome_label.text.find("Claude Code") != -1, "First run guide should frame Claude Code as the primary input")
	_assert(hud.onboarding_welcome_label.text.find("Git は任意") != -1, "First run guide should keep Git optional")
	_assert(hud.onboarding_privacy_label != null and hud.onboarding_privacy_label.text.find("No sync") != -1, "First run guide should show local-only privacy")
	_assert(hud.onboarding_privacy_label.text.find("prompt") != -1 and hud.onboarding_privacy_label.text.find("diff") != -1, "First run guide should name data it does not read")
	_assert(hud.resident_bubble_panel.visible, "Resident speech bubble should be visible when settings are closed")
	var fresh_state = VillageState.new()
	hud.update_state(fresh_state, {"settings": {"auto_import_claude_events": true}, "repositories": [], "imported_activity_event_ids": [], "onboarding_guide_dismissed": false})
	_assert(hud.onboarding_panel.visible, "First run guide should be visible until dismissed")
	hud._toggle_settings()
	_assert(not hud.resident_bubble_panel.visible, "Resident speech bubble should hide while Workshop Settings is open")
	_assert(not hud.onboarding_panel.visible, "First run guide should hide while Workshop Settings is open")
	hud._toggle_settings()
	_assert(hud.onboarding_panel.visible, "First run guide should return when settings close and it is not dismissed")
	_assert(hud.import_button != null and hud.import_button.text == "" and hud.import_button.icon != null, "Claude import should be an icon tool, not a text dashboard button")
	_assert(hud.git_scan_button != null and hud.git_scan_button.text == "" and hud.git_scan_button.icon != null, "Optional Git scan should be an icon tool, not a text dashboard button")
	_assert(hud.settings_button != null and hud.settings_button.text == "" and hud.settings_button.icon != null, "Settings should be an icon tool, not a text dashboard button")
	_assert(hud.auto_import_check != null and hud.auto_import_check.button_pressed, "Claude Code auto import should have a visible local-only toggle")
	var state = VillageState.new()
	hud.update_state(state, {"settings": {"auto_import_claude_events": false}, "repositories": [], "imported_activity_event_ids": [], "onboarding_guide_dismissed": true})
	_assert(not hud.auto_import_check.button_pressed, "HUD should reflect saved auto import off state")
	_assert(hud.inbox_label.text.find("auto off") != -1, "HUD should show auto import off state")
	_assert(not hud.onboarding_panel.visible, "First run guide should stay hidden after dismissal")
	_assert(hud.settings_title_label != null and hud.settings_title_label.text == "Workshop Settings", "Settings should read like an in-world workshop board")
	_assert(hud._format_entries("Recent Growth", [
		{"title": "one"},
		{"title": "two"},
		{"title": "three"},
	]).split("\n").size() <= 4, "bottom plaques should fit title plus three entries")
	hud.free()

func _test_privacy_defaults() -> void:
	var settings = UserSettings.new()
	_assert(settings.local_only, "local_only should default true")
	_assert(not settings.store_commit_messages, "commit messages should not be stored")
	_assert(not settings.store_file_names, "file names should not be stored")
	_assert(not settings.enable_external_network, "external network should be disabled")
	_assert(settings.auto_import_claude_events, "Claude Code auto import should default true")
	_assert(settings.is_mvp_privacy_safe(), "default settings should be privacy safe")

func _test_git_scanner_guardrails() -> void:
	var scanner = GitActivityScanner.new()
	var result = scanner.scan_repository({
		"id": "repo-missing",
		"local_path": "/tmp/code-village-missing-repo",
		"enabled": true,
	})
	_assert(not result["ok"], "scanner should reject missing repo path")
	_assert(Array(result["events"]).is_empty(), "missing repo should not create events")

func _test_git_scanner_metadata_only() -> void:
	var temp_dir = _create_temp_git_repo_with_commit("metadata_only")

	var scanner = GitActivityScanner.new()
	var result = scanner.scan_repository({
		"id": "repo-temp",
		"local_path": temp_dir,
		"enabled": true,
	})
	var encoded = JSON.stringify(result)
	_assert(result["ok"], "scanner should scan temp git repo")
	_assert(encoded.find("secret message") == -1, "scanner result should not contain commit message")
	_assert(encoded.find("README.md") == -1, "scanner result should not store file names")
	_assert(encoded.find("\"md\"") != -1, "scanner result should keep extension summary")

func _test_git_scanner_empty_repo() -> void:
	var temp_dir = _create_temp_git_repo("empty")
	var scanner = GitActivityScanner.new()
	var result = scanner.scan_repository({
		"id": "repo-empty",
		"local_path": temp_dir,
		"enabled": true,
	})
	_assert(result["ok"], "scanner should handle empty git repo without crashing")
	_assert(Array(result["events"]).is_empty(), "empty repo should not create events")
	_assert(Array(result["errors"]).is_empty(), "empty repo should not report git log errors")

func _test_git_scanner_duplicate_suppression() -> void:
	var temp_dir = _create_temp_git_repo_with_commit("duplicate")
	var scanner = GitActivityScanner.new()
	var first_result = scanner.scan_repository({
		"id": "repo-duplicate",
		"local_path": temp_dir,
		"enabled": true,
	})
	_assert(first_result["ok"], "first duplicate scan should succeed")
	_assert(Array(first_result["events"]).size() > 0, "first duplicate scan should create growth-worthy activity")

	var second_result = scanner.scan_repository({
		"id": "repo-duplicate",
		"local_path": temp_dir,
		"enabled": true,
		"last_scan_metadata": Dictionary(first_result["metadata"]),
	})
	_assert(second_result["ok"], "second duplicate scan should succeed")
	_assert(Array(second_result["events"]).is_empty(), "same metadata scan should not create duplicate events")

func _test_git_scanner_detached_head() -> void:
	var temp_dir = _create_temp_git_repo_with_commit("detached")
	_run_command("git", ["-C", temp_dir, "checkout", "--detach", "HEAD"])
	var scanner = GitActivityScanner.new()
	var result = scanner.scan_repository({
		"id": "repo-detached",
		"local_path": temp_dir,
		"enabled": true,
	})
	_assert(result["ok"], "scanner should handle detached HEAD")
	_assert(String(Dictionary(result["metadata"]).get("current_branch", "")) == "HEAD", "detached HEAD should be recorded as HEAD")

func _test_git_scanner_worktree() -> void:
	var temp_dir = _create_temp_git_repo_with_commit("worktree-source")
	var worktree_dir = OS.get_cache_dir().path_join("code_village_worktree_%d" % randi())
	_run_command("git", ["-C", temp_dir, "worktree", "add", "-b", "feature/code-village-test", worktree_dir])
	var scanner = GitActivityScanner.new()
	var result = scanner.scan_repository({
		"id": "repo-worktree",
		"local_path": worktree_dir,
		"enabled": true,
	})
	_assert(result["ok"], "scanner should handle git worktree")
	_assert(scanner.can_scan_path(worktree_dir), "scanner should accept worktree .git file")

func _test_save_manager_delete_save() -> void:
	var temp_path = OS.get_cache_dir().path_join("code_village_save_test_%d.json" % randi())
	var save_manager = SaveManager.new()
	save_manager.save_path = temp_path
	var data = save_manager.get_default_save()
	_assert(not bool(data.get("onboarding_guide_dismissed", true)), "onboarding guide should default visible")
	data["repositories"] = [{"id": "repo-test", "display_name": "Test", "local_path": "/tmp/test"}]
	_assert(save_manager.save_game(data), "save manager should write test save")
	_assert(FileAccess.file_exists(temp_path), "test save should exist")
	_assert(save_manager.delete_save(), "save manager should delete test save")
	_assert(not FileAccess.file_exists(temp_path), "test save should be removed")
	save_manager.free()

	var nested_dir = OS.get_cache_dir().path_join("code_village_nested_save_%d" % randi())
	var nested_path = nested_dir.path_join("inner").path_join("code_village_save.json")
	var nested_save_manager = SaveManager.new()
	nested_save_manager.save_path = nested_path
	_assert(nested_save_manager.save_game(nested_save_manager.get_default_save()), "save manager should create parent dirs for nested save path")
	_assert(FileAccess.file_exists(nested_path), "nested save should exist after parent dir creation")
	DirAccess.remove_absolute(nested_path)
	DirAccess.remove_absolute(nested_dir.path_join("inner"))
	DirAccess.remove_absolute(nested_dir)
	nested_save_manager.free()

func _test_save_manager_recovers_from_invalid_save() -> void:
	var temp_path = OS.get_cache_dir().path_join("code_village_invalid_save_test_%d.json" % randi())
	var save_manager = SaveManager.new()
	save_manager.save_path = temp_path

	var empty_file = FileAccess.open(temp_path, FileAccess.WRITE)
	_assert(empty_file != null, "empty save test file should be writable")
	empty_file.store_string("")
	empty_file.close()
	var empty_data := save_manager.load_game()
	_assert(empty_data.has("village_state"), "empty save should fall back to default save data")
	_assert(save_manager.last_load_warning == "Save file is empty.", "empty save should record a local warning")

	var corrupt_file = FileAccess.open(temp_path, FileAccess.WRITE)
	_assert(corrupt_file != null, "corrupt save test file should be writable")
	corrupt_file.store_string("{broken")
	corrupt_file.close()
	var corrupt_data := save_manager.load_game()
	_assert(corrupt_data.has("village_state"), "corrupt save should fall back to default save data")
	_assert(save_manager.last_load_warning.find("parse failed") != -1, "corrupt save should record parse warning")

	var array_file = FileAccess.open(temp_path, FileAccess.WRITE)
	_assert(array_file != null, "array save test file should be writable")
	array_file.store_string("[]")
	array_file.close()
	var array_data := save_manager.load_game()
	_assert(array_data.has("village_state"), "non-object save should fall back to default save data")
	_assert(save_manager.last_load_warning == "Save file root is not an object.", "non-object save should record type warning")

	DirAccess.remove_absolute(temp_path)
	save_manager.free()

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _run_command(command: String, args: Array) -> void:
	var output: Array = []
	var exit_code = OS.execute(command, PackedStringArray(args), output, true, false)
	_assert(exit_code == 0, "%s %s should succeed" % [command, " ".join(args)])

func _create_temp_git_repo(label: String) -> String:
	var temp_dir = OS.get_cache_dir().path_join("code_village_git_%s_%d" % [label, randi()])
	var make_dir_error = DirAccess.make_dir_recursive_absolute(temp_dir)
	_assert(make_dir_error == OK, "temp git repo directory should be created")
	_run_command("git", ["init", temp_dir])
	_run_command("git", ["-C", temp_dir, "config", "user.email", "code-village@example.invalid"])
	_run_command("git", ["-C", temp_dir, "config", "user.name", "Code Village Test"])
	return temp_dir

func _create_temp_git_repo_with_commit(label: String) -> String:
	var temp_dir = _create_temp_git_repo(label)
	var readme_path = temp_dir.path_join("README.md")
	var file = FileAccess.open(readme_path, FileAccess.WRITE)
	_assert(file != null, "test README should be writable")
	if file != null:
		file.store_string("temporary test file")
		file.close()

	_run_command("git", ["-C", temp_dir, "add", "README.md"])
	_run_command("git", ["-C", temp_dir, "-c", "core.hooksPath=/dev/null", "commit", "-m", "secret message should not be stored"])
	return temp_dir

func _write_claude_inbox_line(file: FileAccess, event_id: String, event_type: String, project_label: String = "code-village") -> void:
	file.store_line(JSON.stringify({
		"id": event_id,
		"type": event_type,
		"occurred_at": "2026-07-01T00:00:00Z",
		"source": "claude_code_hook",
		"repository_id": "",
		"metadata": {
			"project_label": project_label,
			"hook_event": "Stop",
			"session_hash": "abc123",
		},
		"privacy_level": ActivityEvent.PRIVACY_METADATA_ONLY,
	}))
