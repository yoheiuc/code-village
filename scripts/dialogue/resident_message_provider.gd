extends RefCounted
class_name ResidentMessageProvider

const GrowthEventScript = preload("res://scripts/village/growth_event.gd")

const REST_MESSAGE := "何も変わらない日も、村はここにあります。"

var messages_by_growth_type := {
	GrowthEventScript.TYPE_FLOWER_BLOOMED: [
		"花がひとつ咲きました。小さな一歩のしるしです。",
		"工房のそばに、新しい色が増えました。",
	],
	GrowthEventScript.TYPE_LANTERN_LIT: [
		"小さな灯りが増えました。テストが通った日の光です。",
		"夜道が少し歩きやすくなりました。",
	],
	GrowthEventScript.TYPE_LIBRARY_EXPANDED: [
		"図書館に新しいページが増えました。",
		"棚のすきまに、今日の知恵が収まりました。",
	],
	GrowthEventScript.TYPE_PATH_REPAIRED: [
		"今日の道、少し歩きやすくなった気がします。",
		"石畳がひとつ、いい場所に戻りました。",
	],
	GrowthEventScript.TYPE_BRIDGE_REPAIRED: [
		"橋のきしみが少し静かになりました。",
		"向こう岸まで、安心して渡れそうです。",
	],
	GrowthEventScript.TYPE_BRANCH_TREE_GREW: [
		"枝の先に、新しい試みの芽が出ました。",
		"分かれ道も、村の景色の一部です。",
	],
	GrowthEventScript.TYPE_BELL_RANG: [
		"広場の鐘が短く鳴りました。区切りのしるしです。",
		"今日は鐘の音が、いつもより澄んでいました。",
	],
	GrowthEventScript.TYPE_RESIDENT_MESSAGE_ADDED: [
		"工房の窓に、短いメモが残っています。",
		"村人が小さくうなずいて通り過ぎました。",
	],
	GrowthEventScript.TYPE_DIARY_ENTRY_CREATED: [
		"今日のことが、村の日記に一行増えました。",
		"あとで読み返せる一日になりました。",
	],
	GrowthEventScript.TYPE_WORKSHOP_UPGRADED: [
		"工房に小さな灯りが入りました。",
		"机の上に、今日の試行錯誤がそっと置かれています。",
	],
}

func message_for_growth_event(event) -> String:
	var messages: Array = messages_by_growth_type.get(event.type, [REST_MESSAGE])
	if messages.is_empty():
		return REST_MESSAGE
	var index := absi(hash(event.id)) % messages.size()
	return String(messages[index])

func rest_day_message() -> String:
	return REST_MESSAGE
