extends Node
class_name SaveManager

const SAVE_PATH := "user://malatang_save.json"
var host

func setup(game_host) -> void:
	host=game_host

func save_game(show_message := true) -> void:
	if not is_instance_valid(host): return
	var save_data: Dictionary={
		"day":host.day,"daily_sales":host.daily_sales,"daily_target":host.daily_target,"daily_material_cost":host.daily_material_cost,
		"daily_completed_orders":host.daily_completed_orders,"daily_rating_total":host.daily_rating_total,
		"money":host.money,"rating":host.rating,"completed_orders":host.completed_orders,
		"stock":host.stock,"packaging":host.packaging,"broth_stock_packs":host.broth_stock_packs,"broth_servings":host.broth_servings,"broth_water_added":host.broth_water_added,"broth_stock_added":host.broth_stock_added,"broth_base_added":host.broth_base_added,"pending_upgrades":host.pending_upgrades,
		"upgrade_levels":host.upgrade_levels,"dining_unlocked":host.dining_unlocked,"store_stage":host.store_stage,"game_clock_minutes":host.game_clock_minutes,"tutorial_seen":host.tutorial_seen,"tutorial_step":host.tutorial_step,"tutorial_delivery_done":host.tutorial_delivery_done
	}
	if not write_state(save_data):
		if show_message and is_instance_valid(host.result_label): host.result_label.text="Save failed."
		return
	if show_message and is_instance_valid(host.result_label): host.result_label.text="Game saved."

func load_game() -> void:
	if not is_instance_valid(host): return
	var data: Dictionary=read_state()
	if data.is_empty(): return
	host.day=int(data.get("day",1)); host.daily_sales=int(data.get("daily_sales",0)); host.daily_target=int(data.get("daily_target",30000))
	host.game_clock_minutes=clampf(float(data.get("game_clock_minutes",10.0*60.0)),float(host.OPENING_HOUR*60),float(host.CLOSING_HOUR*60))
	host.last_clock_minute=-1; host.auto_close_day=0
	host.daily_material_cost=int(data.get("daily_material_cost",0)); host.daily_completed_orders=int(data.get("daily_completed_orders",0)); host.daily_rating_total=float(data.get("daily_rating_total",0.0))
	host.money=int(data.get("money",25000)); host.rating=float(data.get("rating",3.5)); host.completed_orders=int(data.get("completed_orders",0))
	host.packaging=int(data.get("packaging",50)); host.broth_stock_packs=int(data.get("broth_stock_packs",1)); host.broth_servings=int(data.get("broth_servings",0)); host.broth_water_added=bool(data.get("broth_water_added",false)); host.broth_stock_added=bool(data.get("broth_stock_added",false)); host.broth_base_added=bool(data.get("broth_base_added",false)); host.dining_unlocked=bool(data.get("dining_unlocked",false)); host.store_stage=int(data.get("store_stage",2 if host.dining_unlocked else 1))
	host.store_stage=clampi(host.store_stage,1,3); host.dining_unlocked=host.store_stage>=2
	host.tutorial_seen=bool(data.get("tutorial_seen",false)); host.tutorial_step=clampi(int(data.get("tutorial_step",0)),0,11); host.tutorial_delivery_done=bool(data.get("tutorial_delivery_done",false))
	if host.day>2: host.tutorial_seen=true
	var loaded_stock: Variant=data.get("stock",{})
	if loaded_stock is Dictionary:
		for key in loaded_stock: host.stock[str(key)]=int(loaded_stock[key])
	var loaded_levels: Variant=data.get("upgrade_levels",{})
	if loaded_levels is Dictionary:
		for key in loaded_levels: host.upgrade_levels[str(key)]=int(loaded_levels[key])
	host.pending_upgrades.clear()
	var loaded_pending: Variant=data.get("pending_upgrades",[])
	if loaded_pending is Array:
		for key in loaded_pending:
			var pending_key:=str(key)
			host.pending_upgrades.append("stage2" if pending_key=="dining" else pending_key)


func reset_game() -> void:
	var save_file_path:=ProjectSettings.globalize_path(SAVE_PATH)
	if FileAccess.file_exists(save_file_path): DirAccess.remove_absolute(save_file_path)
	if is_instance_valid(host): host.get_tree().reload_current_scene()

func write_state(state: Dictionary) -> bool:
	var file:=FileAccess.open(SAVE_PATH,FileAccess.WRITE)
	if file==null:
		return false
	file.store_string(JSON.stringify(state,"\t"))
	file.close()
	return true

func read_state() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file:=FileAccess.open(SAVE_PATH,FileAccess.READ)
	if file==null:
		return {}
	var parsed: Variant=JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		return parsed
	return {}
