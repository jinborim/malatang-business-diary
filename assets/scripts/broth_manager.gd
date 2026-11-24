extends Node

# 육수팩과 육수 준비 상태의 공통 판정을 담당합니다.
var host

func setup(game_host) -> void:
	host=game_host

func set_stock_source_enabled(enabled: bool) -> void:
	var source:=host.get_node_or_null("BrothStock") as Node3D
	if not is_instance_valid(source): return
	source.set_meta("interaction_disabled",not enabled)
	source.set_meta("broth_stock_open",host.broth_stock_open_in_world if enabled else false)
	var body:=source.get_node_or_null("StaticBody3D") as StaticBody3D
	if is_instance_valid(body): body.collision_layer=1 if enabled else 0; body.collision_mask=1 if enabled else 0

func start_boil_effect() -> void:
	if not is_instance_valid(host.broth_liquid): return
	if is_instance_valid(host.broth_boil_tween): host.broth_boil_tween.kill()
	host.broth_liquid.scale=host.broth_liquid_base_scale
	host.broth_boil_tween=host.create_tween().set_loops()
	host.broth_boil_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	host.broth_boil_tween.tween_property(host.broth_liquid,"scale",host.broth_liquid_base_scale*Vector3(1.06,1.0,1.06),0.32)
	host.broth_boil_tween.tween_property(host.broth_liquid,"scale",host.broth_liquid_base_scale,0.32)

func stop_boil_effect() -> void:
	if is_instance_valid(host.broth_boil_tween): host.broth_boil_tween.kill()
	if is_instance_valid(host.broth_liquid): host.broth_liquid.scale=host.broth_liquid_base_scale

func sync_held_stock_state() -> void:
	if not is_instance_valid(host) or not host.has_broth_stock_pack: return
	if is_instance_valid(host.held_broth_stock_open_model) and host.held_broth_stock_open_model.visible:
		host.broth_stock_pack_open=true

func stock_node_is_open(node: Node) -> bool:
	if not is_instance_valid(host) or not is_instance_valid(node): return false
	if node==host.broth_stock_open_model: return true
	return bool(node.get_meta("broth_stock_open",false))

func can_prepare() -> bool:
	if not is_instance_valid(host): return true
	if host.broth_making:
		host.result_label.text="마라 육수를 끓이고 있습니다."
		return false
	if host.broth_servings>10:
		host.result_label.text="육수가 %d인분 남았습니다. 10인분 이하일 때 새로 만들 수 있습니다."%host.broth_servings
		return false
	return true

func update_liquid_visual() -> void:
	if not is_instance_valid(host) or not is_instance_valid(host.broth_liquid): return
	var liquid_color:=Color("#78a9b8")
	var should_show:bool=host.broth_water_added
	if host.broth_stock_added:
		liquid_color=Color("#a85b2b")
		should_show=true
	if host.broth_base_added:
		liquid_color=Color("#8f3026")
		should_show=true
	if host.broth_servings>0:
		liquid_color=Color("#c66b26")
		should_show=true
	if host.broth_servings<=0 and not host.broth_water_added and not host.broth_stock_added and not host.broth_base_added:
		should_show=false
	host.broth_liquid.visible=should_show
	host.broth_liquid.material_override=host.mat(liquid_color)
	var fill_ratio:=1.0
	if host.broth_servings>0:
		fill_ratio=clampf(float(host.broth_servings)/50.0,0.08,1.0)
	host.broth_liquid.scale=Vector3(host.broth_liquid_base_scale.x*fill_ratio,host.broth_liquid_base_scale.y,host.broth_liquid_base_scale.z*fill_ratio)

func play_completion_chime() -> void:
	if not is_instance_valid(host): return
	var wav:=AudioStreamWAV.new()
	wav.format=AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate=22050
	wav.stereo=false
	var sample_count:=6615
	var bytes:=PackedByteArray()
	bytes.resize(sample_count*2)
	for i in sample_count:
		var frequency:=660.0 if i<3307 else 880.0
		var fade:=1.0-float(i)/float(sample_count)
		var sample:=int(sin(TAU*frequency*float(i)/22050.0)*6500.0*fade)
		if sample<0: sample+=65536
		bytes[i*2]=sample&255
		bytes[i*2+1]=(sample>>8)&255
	wav.data=bytes
	var player:=AudioStreamPlayer.new()
	player.stream=wav
	host.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func set_pot_filled_visual(filled:bool) -> void:
	if not is_instance_valid(host): return
	if is_instance_valid(host.broth_pot_filled_model): host.broth_pot_filled_model.visible=filled
	var liquid_parent:Node3D=host.broth_pot_filled_model if filled and is_instance_valid(host.broth_pot_filled_model) else host.broth_pot_model
	if is_instance_valid(host.broth_liquid) and is_instance_valid(liquid_parent):
		if host.broth_liquid.get_parent()!=liquid_parent: host.broth_liquid.reparent(liquid_parent)
		host.broth_liquid.position=Vector3(0,0.45,0)
		host.broth_liquid.rotation=Vector3.ZERO
		update_liquid_visual()
	if is_instance_valid(host.broth_pot_model): host.broth_pot_model.visible=not filled
	if is_instance_valid(host.broth_pot_interaction): host.broth_pot_interaction.set_meta("highlight_target",host.broth_pot_filled_model if filled and is_instance_valid(host.broth_pot_filled_model) else host.broth_pot_model)

func add_water(use_sink_stream: bool=false) -> void:
	if not is_instance_valid(host): return
	if not can_prepare(): return
	if host.broth_water_added:
		host.result_label.text="육수 냄비에 이미 물을 받았습니다."
		return
	host.broth_water_added=true
	if is_instance_valid(host.broth_pot_interaction): host.broth_pot_interaction.set_meta("interaction", "육수 냄비 조리하기")
	update_liquid_visual()
	var stream:MeshInstance3D=host.sink_water_stream if use_sink_stream else host.broth_water_stream
	var stream_tween:Tween=host.sink_water_stream_tween if use_sink_stream else host.broth_water_stream_tween
	if is_instance_valid(stream):
		if is_instance_valid(stream_tween): stream_tween.kill()
		stream.visible=true
		stream.scale=Vector3(1.0,0.2,1.0)
		if use_sink_stream and is_instance_valid(host.sink_water_particles):
			host.sink_water_particles.visible=true
			host.sink_water_particles.restart()
		stream_tween=host.create_tween()
		stream_tween.tween_property(stream,"scale",Vector3.ONE,0.25)
		stream_tween.tween_interval(0.9)
		stream_tween.tween_callback(func():
			stream.visible=false
			if use_sink_stream and is_instance_valid(host.sink_water_particles): host.sink_water_particles.visible=false
		)
		if use_sink_stream: host.sink_water_stream_tween=stream_tween
		else: host.broth_water_stream_tween=stream_tween
	host.result_label.text="육수 냄비에 물을 받았습니다. 이제 사골 육수를 넣으세요."
	host._save_game(false)
	host._refresh_hud()

func run_sink_water() -> void:
	if not is_instance_valid(host): return
	if host.has_broth_pot:
		add_water(true)
		return
	if not is_instance_valid(host.sink_water_stream): return
	if is_instance_valid(host.sink_water_stream_tween): host.sink_water_stream_tween.kill()
	host.sink_water_stream.visible=true
	host.sink_water_stream.scale=Vector3(1.0,0.15,1.0)
	if is_instance_valid(host.sink_water_particles):
		host.sink_water_particles.visible=true
		host.sink_water_particles.restart()
	host.sink_water_stream_tween=host.create_tween()
	host.sink_water_stream_tween.tween_property(host.sink_water_stream,"scale",Vector3.ONE,0.25)
	host.sink_water_stream_tween.tween_interval(1.1)
	host.sink_water_stream_tween.tween_callback(func():
		host.sink_water_stream.visible=false
		if is_instance_valid(host.sink_water_particles): host.sink_water_particles.visible=false
	)
	host.result_label.text="싱크대 수도꼭지에서 물이 나옵니다."

func add_stock_from_held_pack() -> void:
	if not is_instance_valid(host) or not can_prepare(): return
	host._sync_held_broth_stock_state()
	if not host.broth_stock_pack_open:
		host.result_label.text="먼저 E키로 육수팩 절취선을 뜯어주세요."
		return
	if not host.broth_water_added:
		host.result_label.text="먼저 육수 냄비에 물을 받아주세요."
		return
	if host.broth_stock_added:
		host.result_label.text="사골 육수를 이미 넣었습니다."
		return
	host.broth_stock_added=true
	host.broth_base_added=true
	host.has_broth_stock_pack=false
	host.broth_stock_pack_open=false
	host._update_held_tool_visibility()
	host._play_broth_pour(Color("#d7c18a"))
	host._set_broth_pot_filled_visual(true)
	if is_instance_valid(host.broth_pot_interaction): host.broth_pot_interaction.set_meta("interaction", "육수 냄비 끓이기")
	update_liquid_visual()
	host.result_label.text="뜯은 사골 육수를 냄비에 넣었습니다. 이제 끓이세요."
	host._save_game(false)
	host._refresh_hud()

func add_stock_from_source() -> void:
	if not is_instance_valid(host): return
	if host.broth_stock_packs<=0:
		host.result_label.text="사골 육수팩이 없습니다. 재료 구매칸에서 구매하세요."
		return
	if not can_prepare(): return
	if not host.broth_water_added:
		host.result_label.text="먼저 육수 냄비에 물을 받아주세요."
		return
	if host.broth_stock_added:
		host.result_label.text="사골 육수를 이미 넣었습니다."
		return
	host.broth_stock_packs-=1
	host.broth_stock_added=true
	if is_instance_valid(host.broth_stock_model): host.broth_stock_model.visible=false
	if is_instance_valid(host.broth_stock_open_model): host.broth_stock_open_model.visible=true
	var stock_pack_tween:Tween=host.create_tween()
	stock_pack_tween.tween_interval(0.9)
	stock_pack_tween.tween_callback(func():
		if is_instance_valid(host.broth_stock_open_model): host.broth_stock_open_model.visible=false
		if is_instance_valid(host.broth_stock_model): host.broth_stock_model.visible=host.broth_stock_packs>0
	)
	# 마라 베이스는 음식 조리 단계에서 자동으로 반영합니다.
	host.broth_base_added=true
	host._play_broth_pour(Color("#d7c18a"))
	host._set_broth_pot_filled_visual(true)
	if is_instance_valid(host.broth_pot_interaction): host.broth_pot_interaction.set_meta("interaction", "육수 냄비 조리하기")
	update_liquid_visual()
	host.result_label.text="사골 육수를 넣었습니다. 이제 육수를 끓이세요."
	host._save_game(false)
	host._refresh_hud()

func add_base() -> void:
	if not is_instance_valid(host) or not can_prepare(): return
	if not host.broth_water_added:
		host.result_label.text="먼저 육수 냄비에 물을 받아주세요."
		return
	if not host.broth_stock_added:
		host.result_label.text="먼저 사골 육수를 넣어주세요."
		return
	if host.broth_base_added:
		host.result_label.text="마라 육수 소스를 이미 넣었습니다."
		return
	host.broth_base_added=true
	host._play_broth_pour(Color("#a92e27"))
	update_liquid_visual()
	if is_instance_valid(host.broth_pot_interaction): host.broth_pot_interaction.set_meta("interaction", "육수 냄비 끓이기")
	host.result_label.text="마라 육수 소스를 넣었습니다. 육수 냄비를 눌러 끓이세요."
	host._save_game(false)
	host._refresh_hud()

func make_broth() -> void:
	if not is_instance_valid(host) or not can_prepare(): return
	# 마라 베이스는 음식 조리 단계에서 자동으로 반영합니다.
	host.broth_base_added=true
	if not host.broth_water_added:
		host.result_label.text="먼저 왼쪽 수도에서 물을 받아주세요."
		return
	if not host.broth_stock_added:
		host.result_label.text="사골 육수통에서 육수를 넣어주세요."
		return
	if not host.broth_base_added:
		host.result_label.text="마라 베이스 통에서 소스를 넣어주세요."
		return
	host.broth_making=true
	host._start_broth_boil_effect()
	if is_instance_valid(host.broth_pot_interaction): host.broth_pot_interaction.set_meta("interaction", "육수 냄비 끓이는 중")
	if is_instance_valid(host.broth_steam): host.broth_steam.emitting=true
	if is_instance_valid(host.broth_progress_bar): host.broth_progress_bar.value=0; host.broth_progress_bar.visible=false
	if is_instance_valid(host.broth_progress_label): host.broth_progress_label.visible=false
	if is_instance_valid(host.broth_world_progress_label): host.broth_world_progress_label.text="0%"; host.broth_world_progress_label.visible=true
	host.result_label.text="마라 육수 50인분을 끓이는 중..."
	var duration:=8.0
	var elapsed:=0.0
	while elapsed<duration:
		await host.get_tree().create_timer(0.1).timeout
		elapsed+=0.1
		var percent:=clampf(elapsed/duration*100.0,0.0,100.0)
		if is_instance_valid(host.broth_progress_bar): host.broth_progress_bar.value=percent; host.broth_progress_bar.visible=false
		if is_instance_valid(host.broth_progress_label): host.broth_progress_label.visible=false
		if is_instance_valid(host.broth_world_progress_label): host.broth_world_progress_label.text="%d%%"%roundi(percent); host.broth_world_progress_label.visible=true
	host.broth_servings=50
	host.broth_water_added=false
	host.broth_stock_added=false
	host.broth_base_added=false
	host.broth_making=false
	host._stop_broth_boil_effect()
	if is_instance_valid(host.broth_pot_interaction): host.broth_pot_interaction.set_meta("interaction", "국자로 육수 뜨기")
	if is_instance_valid(host.broth_steam): host.broth_steam.emitting=false
	if is_instance_valid(host.broth_progress_bar): host.broth_progress_bar.visible=false
	if is_instance_valid(host.broth_progress_label): host.broth_progress_label.visible=false
	if is_instance_valid(host.broth_world_progress_label): host.broth_world_progress_label.text="육수 완성!"; host.broth_world_progress_label.visible=false
	update_liquid_visual()
	host.result_label.text="마라 육수 50인분 완성!"
	play_completion_chime()
	host._save_game(false)
	host._refresh_hud()
func toggle_broth_pot() -> void:
	if not is_instance_valid(host.broth_pot_model) or not is_instance_valid(host.held_tools): return
	if not host.has_broth_pot:
		if host._has_any_held_object():
			host.result_label.text="물건은 한 번에 하나만 들 수 있습니다. 먼저 들고 있는 물건을 내려놓으세요."
			host._refresh_hud()
			return
		if host.broth_making or host.broth_servings>0:
			host.result_label.text="끓인 육수 냄비는 뜨거워서 들 수 없습니다. 국자로 육수를 퍼주세요."
			return
		if host.broth_water_added or host.broth_stock_added or host.broth_base_added:
			host.result_label.text="내용물이 있는 육수 냄비는 비울 때까지 집을 수 없습니다."
			return
		host.has_broth_pot=true
		host.carried_broth_pot_model=host.broth_pot_filled_model if is_instance_valid(host.broth_pot_filled_model) and host.broth_pot_filled_model.visible else host.broth_pot_model
		host._set_broth_pot_carried_collision(true)
		if is_instance_valid(host.carried_broth_pot_model):
			host.carried_broth_pot_model.visible=true
			host.carried_broth_pot_model.reparent(host.held_tools)
			host.carried_broth_pot_model.position=Vector3(-0.30,-0.34,-0.82)
			host.carried_broth_pot_model.rotation_degrees=Vector3(8,-18,0)
			host.carried_broth_pot_model.scale=Vector3.ONE*0.45
		host.result_label.text="육수 냄비를 들었습니다. 싱크대 수도꼭지에 가져가세요."
	else:
		host.has_broth_pot=false
		if is_instance_valid(host.carried_broth_pot_model):
			# Keep the pot at the release position instead of teleporting it back
			# to the original editor position.
			host.carried_broth_pot_model.reparent(host,true)
			host.broth_pot_home_transform=host.carried_broth_pot_model.global_transform
		host._set_broth_pot_carried_collision(false)
		host._set_broth_pot_filled_visual(is_instance_valid(host.broth_pot_filled_model) and host.broth_pot_filled_model==host.carried_broth_pot_model)
		host.carried_broth_pot_model=null
		if is_instance_valid(host.broth_pot_drop_zone): host.broth_pot_drop_zone.set_meta("interaction_disabled",true)
		host.result_label.text="육수 냄비를 내려놓았습니다."

func open_broth_stock_at_source(source: Node) -> void:
	if host.has_broth_stock_pack:
		host.result_label.text="육수팩을 이미 들고 있습니다."
		return
	if host.broth_stock_open_in_world:
		host.result_label.text="이미 뜯은 육수팩입니다. 왼쪽 클릭으로 집으세요."
		return
	if host.broth_stock_packs<=0:
		host.result_label.text="사골 육수팩 재고가 없습니다."
		return
	host.broth_stock_open_in_world=true
	# The unopened source is only a logical interaction proxy. Disable its
	# collider after opening so E cannot keep targeting the old location.
	host._set_broth_stock_source_enabled(false)
	if is_instance_valid(host.broth_stock_model): host.broth_stock_model.visible=false
	if is_instance_valid(host.broth_stock_open_model):
		if is_instance_valid(host.broth_stock_model): host.broth_stock_open_model.global_transform=host.broth_stock_model.global_transform
		host.broth_stock_open_model.visible=true
		var open_body:=host.broth_stock_open_model.get_node_or_null("BrothStockOpenCollision") as StaticBody3D
		if is_instance_valid(open_body):
			open_body.collision_layer=1
			open_body.collision_mask=1
	if is_instance_valid(source):
		source.set_meta("interaction", "뜯은 사골 육수팩 집기")
		source.set_meta("highlight_target", host.broth_stock_open_model)
		source.set_meta("broth_stock_open", true)
	if is_instance_valid(host.broth_stock_open_model):
		host.broth_stock_open_model.set_meta("broth_stock_open", true)
	host.result_label.text="절취선을 뜯었습니다. 왼쪽 클릭으로 집으세요."
	host._refresh_hud()

