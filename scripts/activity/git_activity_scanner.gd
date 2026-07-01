extends RefCounted
class_name GitActivityScanner

const ActivityEventScript = preload("res://scripts/activity/activity_event.gd")

const GIT_BINARY := "git"
const SINCE_WINDOW := "24 hours ago"
const DOC_EXTENSIONS := {
	"md": true,
	"markdown": true,
	"rst": true,
	"txt": true,
	"adoc": true,
}

func can_scan_path(raw_path: String) -> bool:
	var path := _expand_home(raw_path).simplify_path()
	if path == "" or not DirAccess.dir_exists_absolute(path):
		return false
	var git_dir := path.path_join(".git")
	return DirAccess.dir_exists_absolute(git_dir) or FileAccess.file_exists(git_dir)

func scan_repository(repository: Dictionary) -> Dictionary:
	var result := {
		"ok": false,
		"events": [],
		"metadata": {},
		"errors": [],
	}

	if not bool(repository.get("enabled", true)):
		result["errors"].append("Repository is disabled.")
		return result

	var repo_id := String(repository.get("id", ""))
	var local_path := _expand_home(String(repository.get("local_path", ""))).simplify_path()
	if not can_scan_path(local_path):
		result["errors"].append("Path is not a registered local Git repository.")
		return result

	var branch_output := _run_git(local_path, ["rev-parse", "--abbrev-ref", "HEAD"])
	var current_branch := ""
	if branch_output["ok"]:
		current_branch = _first_line(String(branch_output["stdout"]))
	else:
		var symbolic_branch_output := _run_git(local_path, ["symbolic-ref", "--short", "HEAD"])
		if symbolic_branch_output["ok"]:
			current_branch = _first_line(String(symbolic_branch_output["stdout"]))
		else:
			result["errors"].append_array(branch_output["errors"])

	var commits_output := _run_git(local_path, ["log", "--since=%s" % SINCE_WINDOW, "--pretty=format:%H"])
	var commit_hashes: Array[String] = []
	if commits_output["ok"]:
		commit_hashes = _non_empty_lines(String(commits_output["stdout"]))
	elif _looks_like_empty_history(String(commits_output["stdout"])):
		commit_hashes = []
	else:
		result["errors"].append_array(commits_output["errors"])

	var file_output := _run_git(local_path, ["log", "--since=%s" % SINCE_WINDOW, "--name-only", "--pretty=format:"])
	var changed_file_count := 0
	var extension_summary := {}
	if file_output["ok"]:
		var file_names := _non_empty_lines(String(file_output["stdout"]))
		changed_file_count = file_names.size()
		extension_summary = _extension_summary(file_names)
	elif _looks_like_empty_history(String(file_output["stdout"])):
		changed_file_count = 0
		extension_summary = {}
	else:
		result["errors"].append_array(file_output["errors"])

	var tag_output := _run_git(local_path, ["tag", "--list"])
	var tag_count := 0
	if tag_output["ok"]:
		tag_count = _non_empty_lines(String(tag_output["stdout"])).size()
	else:
		result["errors"].append_array(tag_output["errors"])

	var previous_metadata := Dictionary(repository.get("last_scan_metadata", {}))
	var metadata := {
		"current_branch": current_branch,
		"commit_count_24h": commit_hashes.size(),
		"changed_file_count_24h": changed_file_count,
		"file_extension_summary_24h": extension_summary,
		"tag_count": tag_count,
		"scanned_at": Time.get_datetime_string_from_system(true),
	}
	result["metadata"] = metadata

	var events: Array = []
	var activity_window_changed := _activity_window_changed(previous_metadata, metadata)
	if commit_hashes.size() > 0 and activity_window_changed:
		events.append(_new_activity_event(
			ActivityEventScript.TYPE_COMMIT_CREATED,
			"git",
			repo_id,
			{
				"commit_count_24h": commit_hashes.size(),
				"changed_file_count_24h": changed_file_count,
				"file_extension_summary_24h": extension_summary,
				"current_branch": current_branch,
			},
			ActivityEventScript.PRIVACY_METADATA_ONLY,
		))

	if _has_docs_update(extension_summary) and activity_window_changed:
		events.append(_new_activity_event(
			ActivityEventScript.TYPE_DOCS_UPDATED,
			"git",
			repo_id,
			{
				"file_extension_summary_24h": _docs_extension_summary(extension_summary),
			},
			ActivityEventScript.PRIVACY_METADATA_ONLY,
		))

	var previous_branch := String(previous_metadata.get("current_branch", ""))
	if previous_branch != "" and current_branch != "" and previous_branch != current_branch:
		events.append(_new_activity_event(
			ActivityEventScript.TYPE_BRANCH_CREATED,
			"git",
			repo_id,
			{"current_branch": current_branch},
			ActivityEventScript.PRIVACY_METADATA_ONLY,
		))

	var previous_tag_count := int(previous_metadata.get("tag_count", tag_count))
	if tag_count > previous_tag_count:
		events.append(_new_activity_event(
			ActivityEventScript.TYPE_RELEASE_TAG_CREATED,
			"git",
			repo_id,
			{
				"tag_count": tag_count,
				"new_tag_count": tag_count - previous_tag_count,
			},
			ActivityEventScript.PRIVACY_METADATA_ONLY,
		))

	result["events"] = events
	result["ok"] = true
	return result

func _run_git(local_path: String, arguments: Array[String]) -> Dictionary:
	var output: Array = []
	var all_arguments: Array[String] = ["-C", local_path]
	all_arguments.append_array(arguments)
	var exit_code := OS.execute(GIT_BINARY, PackedStringArray(all_arguments), output, true, false)
	if exit_code != 0:
		return {
			"ok": false,
			"stdout": output[0] if output.size() > 0 else "",
			"errors": ["git %s failed with exit code %d" % [" ".join(arguments), exit_code]],
		}
	return {
		"ok": true,
		"stdout": output[0] if output.size() > 0 else "",
		"errors": [],
	}

func _looks_like_empty_history(output: String) -> bool:
	var lowered := output.to_lower()
	return lowered.find("does not have any commits") != -1 \
		or lowered.find("no commits yet") != -1 \
		or lowered.find("bad default revision") != -1

func _activity_window_changed(previous_metadata: Dictionary, metadata: Dictionary) -> bool:
	if previous_metadata.is_empty():
		return true
	return int(previous_metadata.get("commit_count_24h", -1)) != int(metadata.get("commit_count_24h", 0)) \
		or int(previous_metadata.get("changed_file_count_24h", -1)) != int(metadata.get("changed_file_count_24h", 0)) \
		or JSON.stringify(previous_metadata.get("file_extension_summary_24h", {})) != JSON.stringify(metadata.get("file_extension_summary_24h", {}))

func _new_activity_event(
		event_type: String,
		source: String,
		repository_id: String,
		metadata: Dictionary,
		privacy_level: String
	):
	return ActivityEventScript.new().setup(event_type, source, repository_id, metadata, privacy_level)

func _expand_home(path: String) -> String:
	if path == "~":
		return OS.get_environment("HOME")
	if path.begins_with("~/"):
		return OS.get_environment("HOME").path_join(path.substr(2))
	return path

func _first_line(text: String) -> String:
	var lines := _non_empty_lines(text)
	if lines.is_empty():
		return ""
	return lines[0]

func _non_empty_lines(text: String) -> Array[String]:
	var lines: Array[String] = []
	for raw_line in text.split("\n"):
		var line := String(raw_line).strip_edges()
		if line != "":
			lines.append(line)
	return lines

func _extension_summary(file_names: Array[String]) -> Dictionary:
	var summary := {}
	for file_name in file_names:
		var extension := String(file_name).get_extension().to_lower()
		if extension == "":
			extension = "[none]"
		summary[extension] = int(summary.get(extension, 0)) + 1
	return summary

func _has_docs_update(extension_summary: Dictionary) -> bool:
	for extension in extension_summary.keys():
		if DOC_EXTENSIONS.has(String(extension)):
			return true
	return false

func _docs_extension_summary(extension_summary: Dictionary) -> Dictionary:
	var docs := {}
	for extension in extension_summary.keys():
		if DOC_EXTENSIONS.has(String(extension)):
			docs[extension] = extension_summary[extension]
	return docs
