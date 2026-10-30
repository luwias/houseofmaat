extends RefCounted
## Adatvezérelt feltétel-kiértékelő és hatás-végrehajtó.
##
## Feltételek (egy szótár minden kulcsának teljesülnie kell):
##   true / false, [ ...lista = mind ], {"all": [...]}, {"any": [...]}, {"not": {...}}
##   {"flag": "x"}, {"evidence": "K06"}, {"inspected": "K02"}, {"revealed": "K01.flip"}
##   {"node": "merit.about"}, {"choice": {"hapu_approach": "threat"}}, {"lexicon": "ship"}
##   {"memory": "M1"}, {"clarified": "M3.1"}, {"compared": "K04+K06"}, {"clue": "CL_x"}
##   {"case_done": "kha"}, {"card": "c_hapu"}, {"stat": ["maat", ">=", 60]}
##   {"reliability": ["K13", ">=", 60]}
##   Ítéletkörnyezetben (ctx): {"verdict": [...]}, {"param": ["truth", ">=", 65]},
##   {"slot": ["death", "i_death_murder", ["confirmed", "supported"]]}
##
## Hatások: unlock_evidence, set_flag, clear_flag, reliability, choice, lexicon,
##   unlock_memory, clue, param, toast


static func check(cond, gs, ctx: Dictionary = {}) -> bool:
	if cond == null:
		return true
	match typeof(cond):
		TYPE_BOOL:
			return cond
		TYPE_ARRAY:
			for c in cond:
				if not check(c, gs, ctx):
					return false
			return true
		TYPE_DICTIONARY:
			for key in cond:
				if not _check_key(str(key), cond[key], gs, ctx):
					return false
			return true
	return true


static func _check_key(key: String, v, gs, ctx: Dictionary) -> bool:
	match key:
		"all":
			for c in v:
				if not check(c, gs, ctx):
					return false
			return true
		"any":
			for c in v:
				if check(c, gs, ctx):
					return true
			return false
		"not":
			return not check(v, gs, ctx)
		"flag":
			return gs.has_flag(str(v))
		"evidence":
			return gs.has_evidence(str(v))
		"inspected":
			return gs.is_inspected(str(v))
		"revealed":
			return gs.is_revealed(str(v))
		"node":
			return gs.node_visited(str(v))
		"choice":
			for k in v:
				if str(gs.get_choice(str(k))) != str(v[k]):
					return false
			return true
		"lexicon":
			return gs.knows_glyph(str(v))
		"memory":
			return gs.memory_unlocked(str(v))
		"clarified":
			return gs.is_clarified(str(v))
		"compared":
			return gs.was_compared(str(v))
		"clue":
			return gs.has_clue(str(v))
		"case_done":
			return gs.case_done(str(v))
		"card":
			return gs.card_available(str(v))
		"stat":
			return compare(gs.get_stat(str(v[0])), str(v[1]), float(v[2]))
		"reliability":
			return compare(gs.get_reliability(str(v[0])), str(v[1]), float(v[2]))
		"verdict":
			return str(ctx.get("verdict", "")) in v
		"param":
			var params: Dictionary = ctx.get("params", {})
			return compare(float(params.get(str(v[0]), 0.0)), str(v[1]), float(v[2]))
		"slot":
			var slots: Dictionary = ctx.get("slots", {})
			var res = slots.get(str(v[0]))
			if res == null:
				return false
			if str(res.get("interp", "")) != str(v[1]):
				return false
			if v.size() > 2:
				return str(res.get("state", "")) in v[2]
			return true
	push_warning("Ismeretlen feltétel: %s" % key)
	return false


static func compare(a: float, op: String, b: float) -> bool:
	match op:
		">=":
			return a >= b
		">":
			return a > b
		"<=":
			return a <= b
		"<":
			return a < b
		"==":
			return is_equal_approx(a, b)
		"!=":
			return not is_equal_approx(a, b)
	return false


static func _arr(v) -> Array:
	return v if v is Array else [v]


static func apply(effects, gs, case_id: String = "") -> void:
	if effects == null:
		return
	if effects is Dictionary:
		effects = [effects]
	for e in effects:
		for key in e:
			var v = e[key]
			match str(key):
				"unlock_evidence":
					for id in _arr(v):
						gs.unlock_evidence(str(id))
				"set_flag":
					for f in _arr(v):
						gs.set_flag(str(f))
				"clear_flag":
					for f in _arr(v):
						gs.clear_flag(str(f))
				"reliability":
					for id in v:
						gs.set_reliability(str(id), float(v[id]))
				"choice":
					for k in v:
						gs.set_choice(str(k), v[k])
				"lexicon":
					for g in _arr(v):
						gs.learn_glyph(str(g))
				"unlock_memory":
					for m in _arr(v):
						gs.unlock_memory(str(m))
				"clue":
					for c in _arr(v):
						gs.add_clue(str(c))
				"param":
					for p in v:
						gs.add_param(case_id, str(p), float(v[p]))
				"toast":
					gs.toast.emit(str(v), "info")
				_:
					push_warning("Ismeretlen hatás: %s" % key)
