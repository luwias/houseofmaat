extends Node
## Nyelvi réteg. A felület szövegei a data/<nyelv>/ui.json-ban vannak,
## a narratív adatok (esetek, termek) ugyanebben a nyelvi mappában.
## Új nyelv: másold le a data/hu mappát data/en néven, és fordítsd le.

var locale := "hu"
var _strings: Dictionary = {}


func _ready() -> void:
	load_locale(locale)


func load_locale(code: String) -> void:
	locale = code
	var path := "res://data/%s/ui.json" % code
	var txt := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(txt) if txt != "" else null
	_strings = parsed if parsed is Dictionary else {}
	if _strings.is_empty():
		push_error("Hiányzó vagy hibás nyelvi fájl: %s" % path)


func t(key: String, args: Array = []) -> String:
	var s := str(_strings.get(key, key))
	if not args.is_empty():
		s = s % args
	return s


func has_key(key: String) -> bool:
	return _strings.has(key)


func data_path(rel: String) -> String:
	return "res://data/%s/%s" % [locale, rel]
