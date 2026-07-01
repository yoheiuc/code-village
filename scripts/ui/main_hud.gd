extends CanvasLayer
class_name MainHUD

signal repository_submitted(path: String)
signal claude_code_import_requested
signal scan_requested
signal tests_passed_requested
signal manual_session_requested
signal manual_reflection_requested(note: String)
signal repository_removed_requested
signal save_deleted_requested
signal onboarding_dismiss_requested
signal auto_import_toggled(enabled: bool)

var level_label: Label
var today_label: Label
var project_label: Label
var inbox_label: Label
var recent_growth_label: Label
var diary_label: Label
var resident_label: Label
var status_label: Label
var repo_input: LineEdit
var reflection_input: LineEdit
var auto_import_check: CheckBox
var onboarding_panel: PanelContainer
var onboarding_welcome_label: Label
var onboarding_privacy_label: Label
var onboarding_settings_button: Button
var onboarding_start_button: Button
var settings_panel: PanelContainer
var remove_repo_button: Button
var import_button: Button
var git_scan_button: Button
var settings_button: Button
var settings_title_label: Label
var top_left_panel: PanelContainer
var top_right_panel: PanelContainer
var recent_growth_panel: PanelContainer
var diary_book_panel: PanelContainer
var resident_bubble_panel: PanelContainer
var qa_force_settings_open: bool = false
var onboarding_should_show: bool = false

func _ready() -> void:
	_build_ui()
	qa_force_settings_open = OS.get_environment("CODE_VILLAGE_QA_PANEL") == "settings"
	if qa_force_settings_open:
		settings_panel.visible = true
	_sync_overlay_visibility()

func update_state(state, save_data: Dictionary) -> void:
	level_label.text = "Village Level %d" % state.village_level
	today_label.text = "Village Tools · %s" % Time.get_date_string_from_system(false)

	var repositories: Array = Array(save_data.get("repositories", []))
	if repositories.is_empty():
		project_label.text = "Git path: optional"
	else:
		var repo := Dictionary(repositories[0])
		project_label.text = "Optional Git: %s" % String(repo.get("display_name", "local repo"))
	remove_repo_button.disabled = repositories.is_empty()
	onboarding_should_show = not bool(save_data.get("onboarding_guide_dismissed", false)) and not qa_force_settings_open
	onboarding_panel.visible = onboarding_should_show and not settings_panel.visible
	var settings := Dictionary(save_data.get("settings", {}))
	var auto_import := bool(settings.get("auto_import_claude_events", true))
	if auto_import_check != null:
		auto_import_check.set_pressed_no_signal(auto_import)
	inbox_label.text = "Claude seeds: %s / auto %s" % [
		Array(save_data.get("imported_activity_event_ids", [])).size(),
		"on" if auto_import else "off",
	]

	recent_growth_label.text = _format_entries("Recent Growth", state.get_recent_growth(3))
	diary_label.text = _format_entries("Village Diary", state.get_today_entries().slice(0, 3))
	resident_label.text = state.get_latest_resident_message()

func set_status(message: String) -> void:
	status_label.text = message

func _build_ui() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	top_left_panel = _sign_panel(Vector2(20, 20), Vector2(292, 102))
	top_left_panel.name = "VillageStatusSign"
	root.add_child(top_left_panel)
	var top_left_box := _vbox(top_left_panel)
	level_label = _label("Village Level 1", 20)
	project_label = _label("Git path: optional", 12)
	inbox_label = _label("Claude seeds: 0 / auto on", 12)
	var privacy_label := _label("Local-only village / No sync", 12)
	top_left_box.add_child(level_label)
	top_left_box.add_child(project_label)
	top_left_box.add_child(inbox_label)
	top_left_box.add_child(privacy_label)

	top_right_panel = _sign_panel(Vector2(1034, 20), Vector2(226, 106))
	top_right_panel.name = "VillageToolShelf"
	root.add_child(top_right_panel)
	var top_right_box := _vbox(top_right_panel, 6)
	today_label = _label("Village Tools", 15)
	top_right_box.add_child(today_label)
	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 8)
	top_right_box.add_child(action_row)
	import_button = _tool_button("res://assets/placeholders/ui/import_claude_events.svg", "Import Claude Code events")
	import_button.name = "ImportClaudeEventsTool"
	import_button.pressed.connect(_on_claude_import_pressed)
	action_row.add_child(import_button)
	git_scan_button = _tool_button("res://assets/placeholders/ui/scan_optional_git.svg", "Scan optional Git repo")
	git_scan_button.name = "OptionalGitTool"
	git_scan_button.pressed.connect(_on_scan_pressed)
	action_row.add_child(git_scan_button)
	settings_button = _tool_button("res://assets/placeholders/ui/settings.svg", "Open workshop settings")
	settings_button.name = "WorkshopSettingsTool"
	settings_button.pressed.connect(_toggle_settings)
	action_row.add_child(settings_button)
	status_label = _label("Waiting by the workshop.", 10)
	top_right_box.add_child(status_label)

	recent_growth_panel = _notice_board(Vector2(20, 604), Vector2(326, 90))
	recent_growth_panel.name = "IssueBoardPlaque"
	root.add_child(recent_growth_panel)
	var bottom_left_box := _vbox(recent_growth_panel, 4)
	recent_growth_label = _label("Recent Growth\n- 村のはじまり", 13)
	bottom_left_box.add_child(recent_growth_label)

	diary_book_panel = _diary_book(Vector2(374, 608), Vector2(322, 86))
	diary_book_panel.name = "VillageDiaryBook"
	root.add_child(diary_book_panel)
	var bottom_center_box := _vbox(diary_book_panel, 4)
	diary_label = _label("Village Diary\n- 今日の記録はまだありません", 13)
	diary_label.add_theme_color_override("font_color", Color("#473925"))
	bottom_center_box.add_child(diary_label)

	resident_bubble_panel = _speech_bubble(Vector2(728, 548), Vector2(532, 58))
	resident_bubble_panel.name = "ResidentSpeechBubble"
	root.add_child(resident_bubble_panel)
	var resident_bubble_box := _vbox(resident_bubble_panel, 4)
	resident_label = _label("何も変わらない日も、村はここにあります。", 13)
	resident_label.add_theme_color_override("font_color", Color("#3e3424"))
	resident_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	resident_bubble_box.add_child(resident_label)

	onboarding_panel = _settings_board(Vector2(330, 20), Vector2(650, 136))
	onboarding_panel.name = "FirstRunGuideBoard"
	root.add_child(onboarding_panel)
	var onboarding_box := _vbox(onboarding_panel, 7)
	var guide_row := HBoxContainer.new()
	guide_row.add_theme_constant_override("separation", 16)
	onboarding_box.add_child(guide_row)
	var welcome_box := VBoxContainer.new()
	welcome_box.add_theme_constant_override("separation", 3)
	welcome_box.custom_minimum_size = Vector2(302, 0)
	welcome_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	guide_row.add_child(welcome_box)
	welcome_box.add_child(_section_label("Code Village"))
	onboarding_welcome_label = _label("Claude Code のローカルイベントで村が育つ。Git は任意です。", 12)
	welcome_box.add_child(onboarding_welcome_label)
	var privacy_box := VBoxContainer.new()
	privacy_box.add_theme_constant_override("separation", 3)
	privacy_box.custom_minimum_size = Vector2(286, 0)
	privacy_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	guide_row.add_child(privacy_box)
	privacy_box.add_child(_section_label("Privacy"))
	onboarding_privacy_label = _label("Local only / No sync。prompt、response、source、diff、secrets は読みません。", 12)
	privacy_box.add_child(onboarding_privacy_label)
	var guide_button_row := HBoxContainer.new()
	guide_button_row.add_theme_constant_override("separation", 8)
	onboarding_box.add_child(guide_button_row)
	onboarding_settings_button = _button("Open Settings")
	onboarding_settings_button.pressed.connect(_on_open_settings_pressed)
	guide_button_row.add_child(onboarding_settings_button)
	onboarding_start_button = _button("Start Village")
	onboarding_start_button.pressed.connect(_on_hide_guide_pressed)
	guide_button_row.add_child(onboarding_start_button)

	settings_panel = _settings_board(Vector2(912, 154), Vector2(348, 392))
	settings_panel.name = "WorkshopSettingsBoard"
	root.add_child(settings_panel)
	var settings_box := _vbox(settings_panel, 6)
	var settings_header := HBoxContainer.new()
	settings_header.add_theme_constant_override("separation", 8)
	settings_box.add_child(settings_header)
	settings_title_label = _label("Workshop Settings", 18)
	settings_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_header.add_child(settings_title_label)
	var close_settings_button := _button("Close")
	close_settings_button.custom_minimum_size = Vector2(72, 28)
	close_settings_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	close_settings_button.pressed.connect(_toggle_settings)
	settings_header.add_child(close_settings_button)
	settings_box.add_child(_section_label("Privacy"))
	settings_box.add_child(_label("Local only. No sync. No commit messages or file names.", 12))
	settings_box.add_child(_label("Claude Code auto import reads the local inbox only.", 12))
	auto_import_check = _checkbox("Auto import local Claude events")
	auto_import_check.toggled.connect(_on_auto_import_toggled)
	settings_box.add_child(auto_import_check)
	settings_box.add_child(_section_label("Claude Code Notes"))
	var note_button_row := HBoxContainer.new()
	note_button_row.add_theme_constant_override("separation", 6)
	settings_box.add_child(note_button_row)
	var session_button := _button("Log Use")
	session_button.pressed.connect(_on_manual_session_pressed)
	note_button_row.add_child(session_button)
	var tests_button := _button("Tests OK")
	tests_button.pressed.connect(_on_tests_passed_pressed)
	note_button_row.add_child(tests_button)
	reflection_input = LineEdit.new()
	reflection_input.placeholder_text = "Short village note"
	settings_box.add_child(reflection_input)
	var reflection_button := _button("Add Note")
	reflection_button.pressed.connect(_on_manual_reflection_pressed)
	settings_box.add_child(reflection_button)
	settings_box.add_child(_section_label("Optional Git"))
	repo_input = LineEdit.new()
	repo_input.placeholder_text = "Optional local Git repository path"
	settings_box.add_child(repo_input)
	var repo_button_row := HBoxContainer.new()
	repo_button_row.add_theme_constant_override("separation", 6)
	settings_box.add_child(repo_button_row)
	var add_button := _button("Add Git Repo")
	add_button.pressed.connect(_on_add_repository_pressed)
	repo_button_row.add_child(add_button)
	remove_repo_button = _button("Remove Repo")
	remove_repo_button.pressed.connect(_on_remove_repository_pressed)
	repo_button_row.add_child(remove_repo_button)
	var delete_save_button := _button("Delete Save")
	delete_save_button.pressed.connect(_on_delete_save_pressed)
	settings_box.add_child(delete_save_button)
	settings_panel.visible = false

func _panel(position: Vector2, size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = position
	panel.custom_minimum_size = size
	panel.size = size
	panel.add_theme_stylebox_override("panel", _panel_style())
	return panel

func _sign_panel(position: Vector2, size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = position
	panel.custom_minimum_size = size
	panel.size = size
	panel.add_theme_stylebox_override("panel", _sign_style())
	return panel

func _settings_board(position: Vector2, size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = position
	panel.custom_minimum_size = size
	panel.size = size
	panel.add_theme_stylebox_override("panel", _settings_board_style())
	return panel

func _plaque(position: Vector2, size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = position
	panel.custom_minimum_size = size
	panel.size = size
	panel.add_theme_stylebox_override("panel", _plaque_style())
	return panel

func _notice_board(position: Vector2, size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = position
	panel.custom_minimum_size = size
	panel.size = size
	panel.add_theme_stylebox_override("panel", _notice_board_style())
	return panel

func _diary_book(position: Vector2, size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = position
	panel.custom_minimum_size = size
	panel.size = size
	panel.add_theme_stylebox_override("panel", _diary_book_style())
	return panel

func _speech_bubble(position: Vector2, size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = position
	panel.custom_minimum_size = size
	panel.size = size
	panel.add_theme_stylebox_override("panel", _speech_bubble_style())
	return panel

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.14, 0.13, 0.78)
	style.border_color = Color(0.88, 0.80, 0.58, 0.8)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func _plaque_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.23, 0.18, 0.13, 0.84)
	style.border_color = Color(0.85, 0.68, 0.42, 0.86)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	return style

func _notice_board_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.26, 0.18, 0.11, 0.88)
	style.border_color = Color(0.80, 0.58, 0.30, 0.92)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 2
	style.border_width_bottom = 4
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.content_margin_left = 13
	style.content_margin_right = 13
	style.content_margin_top = 10
	style.content_margin_bottom = 9
	return style

func _diary_book_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.82, 0.72, 0.52, 0.90)
	style.border_color = Color(0.38, 0.27, 0.16, 0.88)
	style.border_width_left = 5
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 3
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 5
	style.content_margin_left = 16
	style.content_margin_right = 12
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	return style

func _sign_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.24, 0.19, 0.13, 0.82)
	style.border_color = Color(0.91, 0.75, 0.47, 0.9)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 1
	style.border_width_bottom = 3
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func _settings_board_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.20, 0.16, 0.12, 0.92)
	style.border_color = Color(0.91, 0.75, 0.47, 0.94)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 3
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func _speech_bubble_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.88, 0.82, 0.65, 0.90)
	style.border_color = Color(0.36, 0.28, 0.18, 0.84)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func _vbox(parent: PanelContainer, separation: int = 8) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	parent.add_child(box)
	return box

func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 28)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return button

func _checkbox(text: String) -> CheckBox:
	var check := CheckBox.new()
	check.text = text
	check.button_pressed = true
	check.custom_minimum_size = Vector2(0, 26)
	check.add_theme_font_size_override("font_size", 12)
	check.add_theme_color_override("font_color", Color("#f5ecd0"))
	return check

func _tool_button(icon_path: String, tooltip: String) -> Button:
	var button := Button.new()
	button.text = ""
	button.tooltip_text = tooltip
	button.custom_minimum_size = Vector2(44, 34)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.icon = _load_tool_icon(icon_path, tooltip)
	button.expand_icon = true
	button.add_theme_stylebox_override("normal", _tool_button_style(Color(0.13, 0.11, 0.09, 0.88)))
	button.add_theme_stylebox_override("hover", _tool_button_style(Color(0.20, 0.17, 0.12, 0.92)))
	button.add_theme_stylebox_override("pressed", _tool_button_style(Color(0.09, 0.08, 0.07, 0.94)))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return button

func _load_tool_icon(icon_path: String, tooltip: String) -> Texture2D:
	if ResourceLoader.exists(icon_path):
		var resource := ResourceLoader.load(icon_path)
		if resource is Texture2D:
			return resource as Texture2D
	return _fallback_tool_icon(tooltip)

func _fallback_tool_icon(tooltip: String) -> Texture2D:
	var image := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var accent := Color("#d8b35f")
	if tooltip.find("Git") != -1:
		accent = Color("#8fbf7a")
	elif tooltip.find("Settings") != -1 or tooltip.find("settings") != -1:
		accent = Color("#7fb5d6")
	elif tooltip.find("Claude") != -1:
		accent = Color("#d99b6b")
	_paint_rect(image, 5, 5, 14, 14, Color(0.10, 0.08, 0.06, 0.95))
	_paint_rect(image, 7, 7, 10, 10, accent)
	_paint_rect(image, 10, 3, 4, 18, Color(0.93, 0.84, 0.61, 0.85))
	_paint_rect(image, 3, 10, 18, 4, Color(0.93, 0.84, 0.61, 0.85))
	return ImageTexture.create_from_image(image)

func _paint_rect(image: Image, x: int, y: int, width: int, height: int, color: Color) -> void:
	for px in range(x, x + width):
		for py in range(y, y + height):
			if px >= 0 and py >= 0 and px < image.get_width() and py < image.get_height():
				image.set_pixel(px, py, color)

func _tool_button_style(bg_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = Color(0.77, 0.59, 0.34, 0.72)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 2
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.content_margin_left = 5
	style.content_margin_right = 5
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style

func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("#f5ecd0"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _section_label(text: String) -> Label:
	var label := _label(text, 14)
	label.add_theme_color_override("font_color", Color("#f0d58d"))
	return label

func _format_entries(title: String, entries: Array) -> String:
	if entries.is_empty():
		return "%s\n- 今日の記録はまだありません" % title
	var lines := [title]
	for entry in entries:
		var item := Dictionary(entry)
		lines.append("- %s" % String(item.get("title", "小さな変化")))
	return "\n".join(lines)

func _on_add_repository_pressed() -> void:
	repository_submitted.emit(repo_input.text.strip_edges())

func _on_scan_pressed() -> void:
	scan_requested.emit()

func _on_claude_import_pressed() -> void:
	claude_code_import_requested.emit()

func _on_tests_passed_pressed() -> void:
	tests_passed_requested.emit()

func _on_manual_session_pressed() -> void:
	manual_session_requested.emit()

func _on_manual_reflection_pressed() -> void:
	manual_reflection_requested.emit(reflection_input.text.strip_edges())
	reflection_input.text = ""

func _toggle_settings() -> void:
	settings_panel.visible = not settings_panel.visible
	_sync_overlay_visibility()

func _sync_overlay_visibility() -> void:
	if resident_bubble_panel != null:
		resident_bubble_panel.visible = not settings_panel.visible
	if onboarding_panel != null:
		onboarding_panel.visible = onboarding_should_show and not settings_panel.visible

func _on_open_settings_pressed() -> void:
	settings_panel.visible = true
	_sync_overlay_visibility()

func _on_remove_repository_pressed() -> void:
	repository_removed_requested.emit()

func _on_delete_save_pressed() -> void:
	save_deleted_requested.emit()

func _on_hide_guide_pressed() -> void:
	onboarding_dismiss_requested.emit()

func _on_auto_import_toggled(enabled: bool) -> void:
	auto_import_toggled.emit(enabled)
