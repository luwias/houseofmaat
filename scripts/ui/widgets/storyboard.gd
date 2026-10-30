extends VBoxContainer
## Interaktív papirusz-storyboard: öt jelenet idővonalon, húzható kártyák, élő validáció.

const T = preload("res://scripts/ui/theme.gd")
const UI = preload("res://scripts/ui/ui.gd")
const CardWidget = preload("res://scripts/ui/widgets/card_widget.gd")
const Validator = preload("res://scripts/systems/story_validator.gd")

const CATS := ["all", "character", "event", "object", "location", "memory", "evidence"]

var main: Node
var cid := ""
var case_data: Dictionary
var slots := {}
var tray_flow: HFlowContainer
var filter := "all"
var filter_buttons := {}
var _last_available := []


class SceneSlot extends PanelContainer:
	var sb
	var sid := ""

	func _can_drop_data(_p: Vector2, d: Variant) -> bool:
		return d is Dictionary and d.get("type", "") == "card" and sb.can_add(sid, d.id, d.from)

	func _drop_data(_p: Vector2, d: Variant) -> void:
		sb.add_card(sid, d.id, d.from)


class TrayDrop extends PanelContainer:
	var sb

	func _can_drop_data(_p: Vector2, d: Variant) -> bool:
		return d is Dictionary and d.get("type", "") == "card" and str(d.from) != ""

	func _drop_data(_p: Vector2, d: Variant) -> void:
		sb.remove_card(str(d.from), str(d.id))


func _init(p_cid := "") -> void:
	cid = p_cid
	add_theme_constant_override("separation", 10)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _ready() -> void:
	case_data = GameData.get_case(cid)
	var hint := UI.label(Loc.t("sb_hint"), 14, T.SAND, true)
	add_child(hint)
	var paper := UI.papyrus(14)
	paper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(paper)
	var row := UI.hbox(10)
	var row_scroll := UI.scroll(row)
	paper.add_child(row_scroll)
	for sc in case_data.scenes:
		var slot := SceneSlot.new()
		slot.sb = self
		slot.sid = sc.id
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
		row.add_child(slot)
		slots[sc.id] = slot
	# tálca
	var tray := TrayDrop.new()
	tray.sb = self
	tray.add_theme_stylebox_override("panel", T.flat(Color(T.DEEP, 0.85), T.GOLD_D, 1, 6, 10))
	tray.custom_minimum_size.y = 210
	add_child(tray)
	var tv := UI.vbox(8)
	tray.add_child(tv)
	var fh := UI.hbox(6)
	tv.add_child(fh)
	fh.add_child(UI.title(Loc.t("sb_tray"), 16, T.GOLD))
	fh.add_child(UI.spacer(true, 10))
	for c in CATS:
		var b := UI.button(Loc.t("cat_" + c + "_pl"), _set_filter.bind(c))
		b.add_theme_font_size_override("font_size", 14)
		filter_buttons[c] = b
		fh.add_child(b)
	tray_flow = UI.flow(8)
	var sc := UI.scroll(tray_flow)
	sc.custom_minimum_size.y = 150
	tv.add_child(sc)
	refresh()


func _set_filter(c: String) -> void:
	filter = c
	_build_tray()


func refresh() -> void:
	_build_tray()
	for sc in case_data.scenes:
		_build_slot(sc)


func _available_cards() -> Array:
	var out := []
	for card in case_data.get("cards", []):
		if GameState.card_available(card.id):
			out.append(card.id)
	for m in case_data.get("memories", []):
		if GameState.memory_unlocked(m.id):
			out.append(m.card)
	for ev in case_data.evidence:
		if GameState.has_evidence(ev.id):
			out.append(ev.id)
	return out


func _build_tray() -> void:
	UI.clear(tray_flow)
	for c in filter_buttons:
		var b: Button = filter_buttons[c]
		b.add_theme_color_override("font_color", T.GOLD_L if c == filter else T.PAPYRUS)
	var avail := _available_cards()
	for id in avail:
		var card := GameData.card(id)
		if filter != "all" and card.category != filter:
			continue
		var left := GameState.card_remaining(cid, id)
		if left <= 0:
			continue
		var w := CardWidget.new()
		w.setup(card, "", true)
		if left > 1:
			w.set_count(left)
		if not id in _last_available and not _last_available.is_empty():
			w.modulate = Color(1.3, 1.25, 0.9)
		w.double_clicked.connect(_on_tray_double)
		tray_flow.add_child(w)
	_last_available = avail


func _on_tray_double(card_id: String) -> void:
	# dupla kattintás: az első szabad jelenetbe kerül, ahol még nincs ott
	for sc in case_data.scenes:
		var cards: Array = GameState.board(cid).get(sc.id, [])
		if cards.size() < Validator.MAX_CARDS and not card_id in cards and cards.size() > 0:
			add_card(sc.id, card_id, "")
			return
	for sc in case_data.scenes:
		var cards: Array = GameState.board(cid).get(sc.id, [])
		if cards.is_empty():
			add_card(sc.id, card_id, "")
			return


func can_add(sid: String, card_id: String, from: String) -> bool:
	if from == sid:
		return false
	var cards: Array = GameState.board(cid).get(sid, [])
	if from == "" and GameState.card_remaining(cid, card_id) <= 0:
		return false
	return cards.size() < Validator.MAX_CARDS and not card_id in cards


func add_card(sid: String, card_id: String, from: String) -> void:
	if not GameState.card_available(card_id):
		return
	if from == "" and GameState.card_remaining(cid, card_id) <= 0:
		return
	if from != "" and from != sid:
		var src: Array = GameState.board(cid).get(from, []).duplicate()
		src.erase(card_id)
		GameState.set_board_slot(cid, from, src)
		_build_slot(case_data._scenes[from])
	var cards: Array = GameState.board(cid).get(sid, []).duplicate()
	if card_id in cards:
		return
	cards.append(card_id)
	GameState.set_board_slot(cid, sid, cards)
	_build_slot(case_data._scenes[sid], true)
	_build_tray()


func remove_card(sid: String, card_id: String) -> void:
	var cards: Array = GameState.board(cid).get(sid, []).duplicate()
	cards.erase(card_id)
	GameState.set_board_slot(cid, sid, cards)
	_build_slot(case_data._scenes[sid])
	_build_tray()


func _build_slot(sc: Dictionary, flash := false) -> void:
	var slot: PanelContainer = slots[sc.id]
	UI.clear(slot)
	var cards: Array = GameState.board(cid).get(sc.id, [])
	var res := Validator.validate(case_data, sc, cards, GameState)
	var col := T.state_color(res.state)
	var sb := T.flat(Color(1, 1, 1, 0.12), Color(col, 0.9) if res.state != "empty" else Color(T.INK_L, 0.45), 2, 6, 10)
	slot.add_theme_stylebox_override("panel", sb)
	var v := UI.vbox(6)
	v.mouse_filter = Control.MOUSE_FILTER_PASS
	slot.add_child(v)
	var hh := UI.hbox(6)
	hh.add_child(UI.title(str(sc.get("numeral", "")), 22, T.RED_INK))
	hh.add_child(UI.title(sc.title, 20, T.INK))
	v.add_child(hh)
	v.add_child(UI.label(sc.get("desc", ""), 13, T.INK_L, true))
	v.add_child(UI.state_badge(res.state, 13))
	var cards_box := UI.vbox(4)
	cards_box.mouse_filter = Control.MOUSE_FILTER_PASS
	v.add_child(cards_box)
	for id in cards:
		var card := GameData.card(id)
		if card.is_empty():
			continue
		var w := CardWidget.new()
		w.setup(card, sc.id, true)
		w.custom_minimum_size = Vector2(0, 54)
		w.double_clicked.connect(func(c_id): remove_card(sc.id, c_id))
		cards_box.add_child(w)
	if cards.size() < Validator.MAX_CARDS:
		var ph := UI.box_panel(Color(0, 0, 0, 0.04), Color(T.INK_L, 0.35), 1, 6, 4)
		ph.custom_minimum_size = Vector2(0, 40)
		ph.mouse_filter = Control.MOUSE_FILTER_PASS
		var pl := UI.label(Loc.t("sb_drop_here"), 13, Color(T.INK_L, 0.7), false, HORIZONTAL_ALIGNMENT_CENTER)
		pl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		pl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		ph.add_child(pl)
		cards_box.add_child(ph)
	v.add_child(UI.separator(T.INK_L))
	if res.title != "":
		var it := UI.title("„%s”" % res.title, 16, T.INK)
		it.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(it)
		v.add_child(UI.label(res.narrative, 13, T.INK_L, true))
	var reasons := []
	if not res.support.is_empty():
		reasons.append(Loc.t("sb_supported_by", [_names(res.support)]))
	if not res.contradict.is_empty():
		reasons.append(Loc.t("sb_contradicted_by", [_names(res.contradict)]))
	for n in res.notes:
		reasons.append(n)
	if not reasons.is_empty():
		var rl := UI.label("\n".join(reasons), 12, col.darkened(0.45), true)
		v.add_child(rl)
	if flash:
		slot.modulate = Color(1.25, 1.2, 1.0)
		var tw := slot.create_tween()
		tw.tween_property(slot, "modulate", Color.WHITE, 0.6)


func _names(ids: Array) -> String:
	var out := []
	for id in ids:
		var c := GameData.card(id)
		out.append(c.get("title", id))
	return ", ".join(out)
