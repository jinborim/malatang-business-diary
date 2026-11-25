extends Node

# UI??????????????????????????泥???????븐뼐???????????????留⑶뜮??????猷몄굡????????????ㅻ깹?????????釉먮폁?????????????????嶺??
var host
var start_menu_layer: CanvasLayer
var start_menu_panel: Control

func setup(game_host) -> void:
	host=game_host

func korean_order_name(order_id: int) -> String:
	return "주문 #%03d" % order_id

func korean_ingredient_name(name: String) -> String:
	return name

func korean_spice_name(level: int) -> String:
	return "맵기 %d단계" % level

func format_receipt_items(items: Array) -> String:
	var counts: Dictionary={}
	for item in items:
		var item_name:=str(item)
		counts[item_name]=int(counts.get(item_name,0))+1
	var lines: Array[String]=[]
	for item_name in counts:
		var short_name:=str(item_name)
		if short_name.length()>12: short_name=short_name.left(12)
		lines.append("%-14s  x %d"%[short_name,int(counts[item_name])])
	return "\n".join(lines)

func finish_monitor_return() -> void:
	if not is_instance_valid(host): return
	var player:Node=host.get_node_or_null("Player")
	if player: player.set("input_locked",false)
	if is_instance_valid(host.held_tools): host.held_tools.visible=true
	set_gameplay_hud_visible(true)

func set_gameplay_hud_visible(show_hud: bool) -> void:
	if not is_instance_valid(host): return
	if is_instance_valid(host.info_label): host.info_label.visible=show_hud
	if is_instance_valid(host.prompt_label): host.prompt_label.visible=show_hud
	if is_instance_valid(host.prompt_background): host.prompt_background.visible=show_hud and host.prompt_label.text!=""
	if is_instance_valid(host.order_receipt): host.order_receipt.visible=show_hud
	if is_instance_valid(host.receipt_toggle_button): host.receipt_toggle_button.visible=false
	if is_instance_valid(host.basket_label): host.basket_label.visible=show_hud
	if is_instance_valid(host.result_label): host.result_label.visible=show_hud
	if is_instance_valid(host.monitor_message_label): host.monitor_message_label.visible=show_hud and not host.monitor_message_label.text.is_empty()
	if is_instance_valid(host.customer_status_label): host.customer_status_label.visible=show_hud
	if is_instance_valid(host.broth_progress_bar): host.broth_progress_bar.visible=false
	if is_instance_valid(host.broth_progress_label): host.broth_progress_label.visible=false
	if is_instance_valid(host.broth_world_progress_label): host.broth_world_progress_label.visible=false
	if is_instance_valid(host.tutorial_quest_panel) and not host.tutorial_seen:
		host.tutorial_quest_panel.visible=show_hud and not host.tutorial_active and not host.monitor_camera_focused

func show_start_menu() -> void:
	if is_instance_valid(start_menu_layer): return
	var player: Node = host.get_node_or_null("Player")
	if is_instance_valid(player): player.set("input_locked",true)
	set_gameplay_hud_visible(false)
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	start_menu_layer=CanvasLayer.new()
	start_menu_layer.name="StartMenuLayer"
	start_menu_layer.layer=50
	host.add_child(start_menu_layer)
	var viewport_container:=SubViewportContainer.new()
	viewport_container.name="StartExteriorViewportContainer"
	viewport_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport_container.mouse_filter=Control.MOUSE_FILTER_IGNORE
	viewport_container.stretch=true
	start_menu_layer.add_child(viewport_container)
	var viewport:=SubViewport.new()
	viewport.name="StartExteriorViewport"
	viewport.size=Vector2i(1280,720)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg=false
	viewport.own_world_3d=true
	viewport_container.add_child(viewport)
	_build_start_exterior(viewport)
	var backdrop:=ColorRect.new()
	backdrop.name="StartMenuBackdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color=Color(0.02,0.05,0.07,0.34)
	backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE
	start_menu_layer.add_child(backdrop)
	var glow:=Panel.new()
	glow.position=Vector2(770,92)
	glow.size=Vector2(420,536)
	var glow_style:=StyleBoxFlat.new()
	glow_style.bg_color=Color(0.08,0.12,0.15,0.92)
	glow_style.border_color=Color("#a9823d")
	glow_style.set_border_width_all(2)
	glow_style.set_corner_radius_all(18)
	glow_style.shadow_color=Color(0,0,0,0.45)
	glow_style.shadow_size=28
	glow.add_theme_stylebox_override("panel",glow_style)
	start_menu_layer.add_child(glow)
	start_menu_panel=glow
	var content:=VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("separation",12)
	content.add_theme_constant_override("margin_left",96)
	content.add_theme_constant_override("margin_right",96)
	content.add_theme_constant_override("margin_top",48)
	content.add_theme_constant_override("margin_bottom",42)
	glow.add_child(content)
	var eyebrow:=Label.new()
	eyebrow.text="KOREAN MALATANG SHOP"
	eyebrow.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_font_size_override("font_size",14)
	eyebrow.add_theme_color_override("font_color",Color("#dcb979"))
	content.add_child(eyebrow)
	var title:=Label.new()
	title.text="마라탕 가게"
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",48)
	title.add_theme_color_override("font_color",Color("#fff8e6"))
	content.add_child(title)
	var subtitle:=Label.new()
	subtitle.text="재료를 고르고, 끓이고, 손님을 맞이하세요"
	subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size",18)
	subtitle.add_theme_color_override("font_color",Color("#d7e6ee"))
	content.add_child(subtitle)
	var spacer:=Control.new()
	spacer.custom_minimum_size=Vector2(0,28)
	content.add_child(spacer)
	var start_button:=Button.new()
	start_button.name="StartGameButton"
	start_button.text="게임 시작"
	start_button.custom_minimum_size=Vector2(0,62)
	start_button.add_theme_font_size_override("font_size",22)
	start_button.pressed.connect(hide_start_menu)
	content.add_child(start_button)
	var continue_hint:=Label.new()
	continue_hint.text="저장된 가게 진행 상황은 자동으로 불러옵니다."
	continue_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	continue_hint.add_theme_font_size_override("font_size",14)
	continue_hint.add_theme_color_override("font_color",Color("#b9cbd2"))
	content.add_child(continue_hint)
	var quit_button:=Button.new()
	quit_button.name="QuitGameButton"
	quit_button.text="게임 종료"
	quit_button.custom_minimum_size=Vector2(0,48)
	quit_button.add_theme_font_size_override("font_size",17)
	quit_button.pressed.connect(func(): get_tree().quit())
	content.add_child(quit_button)
	style_start_menu()

func _start_box(parent: Node3D, position: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance:=MeshInstance3D.new()
	var box:=BoxMesh.new()
	box.size=size
	mesh_instance.mesh=box
	mesh_instance.position=position
	var material:=StandardMaterial3D.new()
	material.albedo_color=color
	material.roughness=0.78
	mesh_instance.material_override=material
	parent.add_child(mesh_instance)
	return mesh_instance

func _start_quad(parent: Node3D, position: Vector3, size: Vector2, color: Color, texture_path: String="") -> MeshInstance3D:
	var mesh_instance:=MeshInstance3D.new()
	var quad:=QuadMesh.new()
	quad.size=size
	mesh_instance.mesh=quad
	mesh_instance.position=position
	var material:=StandardMaterial3D.new()
	material.albedo_color=color
	material.roughness=0.62
	if not texture_path.is_empty(): material.albedo_texture=load(texture_path) as Texture2D
	mesh_instance.material_override=material
	parent.add_child(mesh_instance)
	return mesh_instance

func _build_start_exterior(viewport: SubViewport) -> void:
	var scene:=Node3D.new()
	scene.name="MalatangShopExterior"
	viewport.add_child(scene)
	var environment:=WorldEnvironment.new()
	var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR
	env.background_color=Color("#14232d")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("#9bb2bd")
	env.ambient_light_energy=0.65
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	environment.environment=env
	scene.add_child(environment)
	var sun:=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-52,-28,0)
	sun.light_color=Color("#f6d6aa")
	sun.light_energy=1.1
	sun.shadow_enabled=true
	scene.add_child(sun)
	var camera:=Camera3D.new()
	camera.name="StartExteriorCamera"
	camera.position=Vector3(0,3.3,11.5)
	camera.fov=48.0
	scene.add_child(camera)
	camera.look_at(Vector3(0,2.55,0),Vector3.UP)
	_start_box(scene,Vector3(0,-0.06,-3.0),Vector3(30.0,0.18,22.0),Color("#242a30"))
	_start_box(scene,Vector3(-10.0,4.5,-6.0),Vector3(5.5,9.0,2.4),Color("#263843"))
	_start_box(scene,Vector3(10.0,5.2,-7.5),Vector3(6.5,10.4,2.6),Color("#303c48"))
	_start_box(scene,Vector3(-15.0,3.4,-8.5),Vector3(4.0,6.8,2.2),Color("#3d4650"))
	_start_box(scene,Vector3(15.0,4.1,-9.0),Vector3(4.2,8.2,2.2),Color("#38444d"))
	for window_x in [-11.7,-10.0,-8.3,8.2,10.0,11.8]:
		for window_y in [3.0,5.0,7.0]:
			_start_box(scene,Vector3(window_x,window_y,-4.72 if window_x<0 else -6.18),Vector3(0.72,0.42,0.06),Color("#e2b66b"))
	for lamp_x in [-7.2,7.2]:
		_start_box(scene,Vector3(lamp_x,2.4,2.0),Vector3(0.10,4.8,0.10),Color("#1b2024"))
		_start_box(scene,Vector3(lamp_x,4.75,2.0),Vector3(0.8,0.10,0.10),Color("#1b2024"))
		var lamp:=OmniLight3D.new()
		lamp.position=Vector3(lamp_x,4.55,1.85)
		lamp.light_color=Color("#ffd889")
		lamp.light_energy=1.8
		lamp.omni_range=5.0
		scene.add_child(lamp)
	var facade:=_start_box(scene,Vector3(0,2.75,0),Vector3(13.5,5.5,0.75),Color("#55423d"))
	_start_box(scene,Vector3(0,0.62,0.02),Vector3(14.2,0.35,1.15),Color("#252b31"))
	_start_box(scene,Vector3(0,5.45,0.02),Vector3(14.2,0.35,1.15),Color("#272c30"))
	_start_box(scene,Vector3(0,4.15,0.68),Vector3(14.0,0.28,1.25),Color("#a64032"))
	_start_box(scene,Vector3(0,4.04,1.02),Vector3(14.0,0.14,0.55),Color("#d5b066"))
	_start_quad(scene,Vector3(-3.8,2.75,0.42),Vector2(4.8,2.6),Color("#315465"))
	_start_quad(scene,Vector3(3.25,2.75,0.42),Vector2(3.1,2.6),Color("#315465"))
	_start_quad(scene,Vector3(-3.8,2.75,0.47),Vector2(4.45,2.25),Color("#e7bd77"))
	_start_quad(scene,Vector3(3.25,2.75,0.47),Vector2(2.75,2.25),Color("#e7bd77"))
	_start_box(scene,Vector3(0.0,2.05,0.48),Vector3(1.65,3.5,0.48),Color("#1d252b"))
	_start_quad(scene,Vector3(0.0,2.18,0.74),Vector2(1.28,2.75),Color("#172c38"))
	_start_box(scene,Vector3(0,1.02,0.62),Vector3(14.3,0.28,1.2),Color("#33383a"))
	_start_box(scene,Vector3(-5.25,1.75,0.72),Vector3(1.25,0.95,0.18),Color("#d8bd83"))
	_start_box(scene,Vector3(-5.25,1.12,0.72),Vector3(1.15,0.12,0.82),Color("#314e63"))
	_start_box(scene,Vector3(5.25,1.3,0.72),Vector3(1.0,0.72,0.25),Color("#58745b"))
	_start_box(scene,Vector3(5.25,0.78,0.72),Vector3(1.25,0.16,0.85),Color("#2e4735"))
	_start_quad(scene,Vector3(0,4.86,0.48),Vector2(7.2,1.35),Color.WHITE,"res://assets/textures/malatang_store_sign_panda.png")
	var sign_light:=OmniLight3D.new()
	sign_light.position=Vector3(0,4.4,1.8)
	sign_light.light_color=Color("#ffd27c")
	sign_light.light_energy=4.0
	sign_light.omni_range=7.0
	scene.add_child(sign_light)
	var door_light:=OmniLight3D.new()
	door_light.position=Vector3(0,2.2,2.0)
	door_light.light_color=Color("#ffc982")
	door_light.light_energy=2.2
	door_light.omni_range=5.0
	scene.add_child(door_light)

func style_start_menu() -> void:
	if not is_instance_valid(start_menu_layer): return
	for node in start_menu_layer.find_children("*","Button",true,false):
		var button:=node as Button
		var normal:=StyleBoxFlat.new()
		normal.bg_color=Color("#a64032") if button.name=="StartGameButton" else Color("#314e63")
		normal.border_color=Color("#e1c27b")
		normal.set_border_width_all(1)
		normal.set_corner_radius_all(8)
		var hover:StyleBoxFlat=normal.duplicate() as StyleBoxFlat
		hover.bg_color=Color("#c45743") if button.name=="StartGameButton" else Color("#496d82")
		button.add_theme_stylebox_override("normal",normal)
		button.add_theme_stylebox_override("hover",hover)
		button.add_theme_stylebox_override("pressed",hover)
		button.add_theme_color_override("font_color",Color("#fff8e6"))
		button.add_theme_color_override("font_hover_color",Color.WHITE)

func hide_start_menu() -> void:
	if is_instance_valid(start_menu_layer):
		start_menu_layer.queue_free()
	start_menu_layer=null
	start_menu_panel=null
	var player: Node = host.get_node_or_null("Player")
	if is_instance_valid(player): player.set("input_locked",false)
	set_gameplay_hud_visible(true)
	Input.mouse_mode=Input.MOUSE_MODE_CAPTURED

func show_monitor_message(message: String) -> void:
	if not is_instance_valid(host) or not is_instance_valid(host.monitor_message_label): return
	if is_instance_valid(host.monitor_message_tween): host.monitor_message_tween.kill()
	host.monitor_message_label.text=message
	host.monitor_message_label.visible=not message.is_empty() and host.monitor_camera_focused
	if message.is_empty(): return
	host.monitor_message_tween=host.create_tween()
	host.monitor_message_tween.tween_interval(2.5)
	host.monitor_message_tween.tween_callback(func():
		if is_instance_valid(host.monitor_message_label):
			host.monitor_message_label.text=""
			host.monitor_message_label.visible=false
	)

func toggle_order_receipt() -> void:
	set_receipt_open(not host.receipt_open)

func set_receipt_open(open_state: bool, animate: bool=true) -> void:
	if not is_instance_valid(host) or not is_instance_valid(host.order_receipt) or not is_instance_valid(host.receipt_toggle_button): return
	host.receipt_open=open_state
	if is_instance_valid(host.receipt_tween): host.receipt_tween.kill()
	var viewport_width:float=host.get_viewport().get_visible_rect().size.x
	var open_x:float=viewport_width-host.order_receipt.size.x-20.0
	var open_y:float=18.0
	var rolled_y:float=-host.order_receipt.size.y+42.0
	var target_y:float=open_y if host.receipt_open else rolled_y
	var target_toggle_x:float=open_x-host.receipt_toggle_button.size.x-8.0
	host.order_receipt.visible=true
	host.receipt_toggle_button.visible=false
	host.receipt_toggle_button.text="\uC601\uC218\uC99D"
	if not animate:
		host.order_receipt.position=Vector2(open_x,target_y)
		host.receipt_toggle_button.position=Vector2(target_toggle_x,18.0)
		return
	host.receipt_tween=host.create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	host.receipt_tween.tween_property(host.order_receipt,"position",Vector2(open_x,target_y),0.42)
	host.receipt_tween.tween_property(host.receipt_toggle_button,"position",Vector2(target_toggle_x,18.0),0.42)

func refresh_hud() -> void:
	if not is_instance_valid(host): return
	if is_instance_valid(host.game_clock_label): host.game_clock_label.text="현재 시각  %s" % host._game_clock_text()
	if host.current_order.is_empty():
		host.current_order_label.text="마라탕 주문\n현재 진행 중인 주문이 없습니다."
	else:
		host.current_order_label.text="마라탕 주문\n%s\n남은 시간: %d초\n%s\n\n재료: %s\n예상 수익: %d원" % [korean_order_name(host.current_order.id),int(ceil(host.remaining_time)),korean_spice_name(host.current_order.spice),format_receipt_items(host.current_order.ingredients),host.current_order.reward]
	host.current_order_label.text=host.current_order_label.text.replace("일일 목표","")
	if not host.tutorial_seen and host.day<=2 and is_instance_valid(host.current_order_label):
		host.current_order_label.text += "\n\n--------------------------\n일일 목표\n" + host._tutorial_quest_text_v3()
	var broth_warning: String = "" if host.broth_servings > 10 else "육수가 부족합니다."
	var broth_step: String = ""
	if host.broth_water_added and not host.broth_stock_added: broth_step="육수팩을 육수 냄비에 넣어주세요."
	elif host.broth_stock_added and not host.broth_base_added: broth_step="소스와 재료를 넣어주세요."
	elif host.broth_water_added and host.broth_stock_added and host.broth_base_added: broth_step="조리를 시작해주세요."
	if is_instance_valid(host.basket_label):
		var basket_text: String = " / ".join(host.basket) if not host.basket.is_empty() else "비어 있음"
		var spice_text: String = "%d단계" % host.selected_spice if host.selected_spice > 0 else "선택 안 함"
		host.basket_label.text = "담은 재료: %s | 맵기: %s | 육수: %d/50인분" % [basket_text,spice_text,host.broth_servings]

	if is_instance_valid(host.basket_label): host.basket_label.text += "\n들고 있는 물건: " + _carried_item_name()

func _carried_item_name() -> String:
	if not is_instance_valid(host): return "\\uC5C6\\uC74C"
	var carried:Array[String]=[]
	if host.has_steel_bowl: carried.append("\\uC1E0\\uADF8\\uB987")
	if host.has_bowl: carried.append("\\uADF8\\uB987 %d\\uAC1C" % host.held_bowl_count)
	if host.has_tongs: carried.append("\\uC9D1\\uAC8C")
	if host.has_ladle: carried.append("\\uAD6D\\uC790")
	if host.has_broth_stock_pack: carried.append("\\uC721\\uC218 \\uD329")
	if host.has_broth_pot: carried.append("\\uB0C4\\uBE44")
	return " + ".join(carried) if not carried.is_empty() else "\\uBE44\\uC5B4 \\uC788\\uC74C"

func place_interaction_prompt_near(target: Node) -> void:
	if not is_instance_valid(host) or not is_instance_valid(host.camera) or not is_instance_valid(target): return
	var target_3d:=target as Node3D
	if not is_instance_valid(target_3d): target_3d=target.get_parent() as Node3D
	if not is_instance_valid(target_3d): return
	var screen_position:Vector2=host.camera.unproject_position(target_3d.global_position+Vector3(0,0.30,0))
	var viewport_size:Vector2=host.get_viewport().get_visible_rect().size
	var panel_size:Vector2=host.prompt_background.size if is_instance_valid(host.prompt_background) else Vector2(260,58)
	var x:float=screen_position.x+20.0
	var y:float=screen_position.y-panel_size.y-12.0
	if x+panel_size.x>viewport_size.x-12.0: x=screen_position.x-panel_size.x-20.0
	if x<12.0: x=12.0
	if y<12.0: y=screen_position.y+20.0
	y=clampf(y,12.0,maxf(12.0,viewport_size.y-panel_size.y-12.0))
	if is_instance_valid(host.prompt_background): host.prompt_background.position=Vector2(x,y)
	if is_instance_valid(host.prompt_mouse_icon): host.prompt_mouse_icon.position=Vector2(x+8.0,y+13.0)
	if is_instance_valid(host.prompt_label): host.prompt_label.position=Vector2(x+36.0,y+5.0)

func _configure_monitor_tab(button: Button, label_text: String, icon_path: String) -> void:
	button.text = ""
	button.custom_minimum_size = Vector2(160, 92)
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_constant_override("h_separation", 0)
	var content:=VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("separation", 4)
	content.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var icon:=TextureRect.new()
	icon.name="MonitorTabIcon"
	icon.custom_minimum_size=Vector2(42,42)
	icon.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture=load(icon_path) as Texture2D
	icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
	content.add_child(icon)
	var label:=Label.new()
	label.name="MonitorTabLabel"
	label.text=label_text
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size",14)
	label.add_theme_color_override("font_color",Color("#f5f0df"))
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	content.add_child(label)
	button.add_child(content)

func style_monitor_controls() -> void:
	if not is_instance_valid(host) or not is_instance_valid(host.order_panel): return
	for node in host.order_panel.find_children("*","Button",true,false):
		var button:Button=node as Button
		if not is_instance_valid(button): continue
		var normal:=StyleBoxFlat.new()
		var is_monitor_tab:bool=button.name in ["OrdersTab","ShopTab","UpgradeTab","ManagementTab"]
		normal.bg_color=Color("#435f73") if is_monitor_tab else Color("#fffaf0")
		normal.border_color=Color("#789aae") if is_monitor_tab else Color("#d2b98e")
		normal.set_border_width_all(1)
		normal.set_corner_radius_all(7)
		normal.content_margin_left=12.0
		normal.content_margin_right=12.0
		var hover:StyleBoxFlat=normal.duplicate() as StyleBoxFlat
		hover.bg_color=Color("#587c91") if is_monitor_tab else Color("#fff0cd")
		hover.border_color=Color("#b9d6e3") if is_monitor_tab else Color("#b94b32")
		var pressed:StyleBoxFlat=normal.duplicate() as StyleBoxFlat
		pressed.bg_color=Color("#ead7b7")
		button.add_theme_stylebox_override("normal",normal)
		button.add_theme_stylebox_override("hover",hover)
		button.add_theme_stylebox_override("pressed",pressed)
		button.add_theme_color_override("font_color",Color("#f5f0df") if is_monitor_tab else Color("#33251e"))
		button.add_theme_color_override("font_hover_color",Color("#ffffff") if is_monitor_tab else Color("#7d2e22"))
		button.add_theme_font_size_override("font_size",16)
	for node in host.order_panel.find_children("*","Label",true,false):
		var label:Label=node as Label
		if is_instance_valid(label) and label.name not in ["MonitorTabLabel","MonitorTitle","StoreStatus"]: label.add_theme_color_override("font_color",Color("#33251e"))

func show_orders() -> void:
	if not is_instance_valid(host): return
	host.monitor_mode="orders"
	host._refresh_order_panel()

func show_shop() -> void:
	if not is_instance_valid(host): return
	host.monitor_mode="shop"
	host._refresh_order_panel()

func show_upgrades() -> void:
	if not is_instance_valid(host): return
	host.monitor_mode="upgrades"
	host._refresh_order_panel()

func show_management() -> void:
	if not is_instance_valid(host): return
	host.monitor_mode="management"
	host._refresh_order_panel()

func show_settlement_after_transition() -> void:
	if not is_instance_valid(host): return
	host.monitor_mode="settlement"
	host._save_game(false)
	host._refresh_order_panel()
func build_ui() -> void:
	var layer:=CanvasLayer.new(); host.add_child(layer)
	var top_bar:=ColorRect.new(); top_bar.name="HudTopBar"; top_bar.color=Color(0,0,0,0); top_bar.mouse_filter=Control.MOUSE_FILTER_IGNORE; top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE); top_bar.size.y=76; top_bar.visible=false; layer.add_child(top_bar)
	var bottom_bar:=ColorRect.new(); bottom_bar.name="HudBottomBar"; bottom_bar.color=Color(0,0,0,0); bottom_bar.mouse_filter=Control.MOUSE_FILTER_IGNORE; bottom_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE); bottom_bar.position.y=-125; bottom_bar.size.y=125; bottom_bar.visible=false; layer.add_child(bottom_bar)
	host.game_clock_label=Label.new(); host.game_clock_label.position=Vector2(24,88); host.game_clock_label.size=Vector2(260,42); host.game_clock_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT; host.game_clock_label.add_theme_font_size_override("font_size",22); host.game_clock_label.add_theme_color_override("font_color",Color.WHITE); host.game_clock_label.add_theme_color_override("font_shadow_color",Color(0,0,0,0.75)); host.game_clock_label.add_theme_constant_override("shadow_offset_x",2); host.game_clock_label.add_theme_constant_override("shadow_offset_y",2); layer.add_child(host.game_clock_label)
	host.fade_overlay=ColorRect.new(); host.fade_overlay.name="DayTransitionFade"; host.fade_overlay.color=Color(0,0,0,0); host.fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); host.fade_overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE; host.fade_overlay.z_index=100; layer.add_child(host.fade_overlay)
	var cross:=Label.new()
	cross.name="CenterCrosshair"
	cross.text="+"
	cross.add_theme_font_size_override("font_size",24)
	cross.add_theme_color_override("font_color",Color.WHITE)
	cross.add_theme_color_override("font_outline_color",Color(0.02,0.02,0.02,0.95))
	cross.add_theme_constant_override("outline_size",4)
	cross.set_anchors_preset(Control.PRESET_CENTER)
	cross.position=Vector2(-16,-18)
	cross.size=Vector2(32,36)
	cross.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	cross.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	cross.mouse_filter=Control.MOUSE_FILTER_IGNORE
	cross.z_index=20
	layer.add_child(cross)
	host.info_label=Label.new(); host.info_label.text="WASD Move | Mouse Look | E Interact"; host.info_label.position=Vector2(24,20); host.info_label.add_theme_font_size_override("font_size",18); layer.add_child(host.info_label)
	# Keep the interaction hint compact and attach it to the object being looked at.
	# A large centered panel hides the work surface and makes it hard to see what
	# will be picked up, especially when several items are close together.
	host.prompt_background=Panel.new(); host.prompt_background.name="InteractionPromptBackground"; host.prompt_background.set_anchors_preset(Control.PRESET_TOP_LEFT); host.prompt_background.position=Vector2.ZERO; host.prompt_background.size=Vector2(260,58); host.prompt_background.mouse_filter=Control.MOUSE_FILTER_IGNORE; host.prompt_background.visible=false; layer.add_child(host.prompt_background)
	var prompt_background_style:=StyleBoxFlat.new(); prompt_background_style.bg_color=Color(0.02,0.025,0.03,0.78); prompt_background_style.border_color=Color(1.0,0.88,0.45,0.75); prompt_background_style.set_border_width_all(1); prompt_background_style.set_corner_radius_all(7); host.prompt_background.add_theme_stylebox_override("panel",prompt_background_style)
	host.prompt_mouse_icon=TextureRect.new(); host.prompt_mouse_icon.name="InteractionMouseIcon"; host.prompt_mouse_icon.texture=load("res://assets/ui/mouse_left.svg"); host.prompt_mouse_icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; host.prompt_mouse_icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; host.prompt_mouse_icon.set_anchors_preset(Control.PRESET_TOP_LEFT); host.prompt_mouse_icon.position=Vector2(8,13); host.prompt_mouse_icon.size=Vector2(24,24); host.prompt_mouse_icon.visible=false; layer.add_child(host.prompt_mouse_icon)
	host.prompt_label=Label.new(); host.prompt_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT; host.prompt_label.add_theme_font_size_override("font_size",14); host.prompt_label.set_anchors_preset(Control.PRESET_TOP_LEFT); host.prompt_label.position=Vector2(36,5); host.prompt_label.size=Vector2(216,50); host.prompt_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; layer.add_child(host.prompt_label)
	host.order_receipt=PanelContainer.new(); host.order_receipt.position=Vector2(955,18); host.order_receipt.size=Vector2(305,535); layer.add_child(host.order_receipt)
	host.receipt_toggle_button=Button.new(); host.receipt_toggle_button.name="ReceiptToggle"; host.receipt_toggle_button.position=Vector2(875,18); host.receipt_toggle_button.size=Vector2(72,38); host.receipt_toggle_button.text="\\uC601\\uC218\\uC99D"; host.receipt_toggle_button.z_index=10; host.receipt_toggle_button.pressed.connect(host._toggle_order_receipt); layer.add_child(host.receipt_toggle_button)
	var receipt_style:=StyleBoxFlat.new(); receipt_style.bg_color=Color("#f8f1df"); receipt_style.border_color=Color("#4a443b"); receipt_style.set_border_width_all(2); receipt_style.set_corner_radius_all(3); receipt_style.shadow_color=Color(0,0,0,0.28); receipt_style.shadow_size=8; receipt_style.shadow_offset=Vector2(4,5); host.order_receipt.add_theme_stylebox_override("panel",receipt_style)
	var receipt_margin:=MarginContainer.new(); receipt_margin.add_theme_constant_override("margin_left",18); receipt_margin.add_theme_constant_override("margin_right",18); receipt_margin.add_theme_constant_override("margin_top",16); receipt_margin.add_theme_constant_override("margin_bottom",18); host.order_receipt.add_child(receipt_margin)
	host.current_order_label=Label.new(); host.current_order_label.add_theme_font_size_override("font_size",16); host.current_order_label.add_theme_color_override("font_color",Color("#29251f")); host.current_order_label.add_theme_color_override("font_shadow_color",Color(1,1,1,0.4)); host.current_order_label.add_theme_constant_override("line_spacing",3); host.current_order_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; host.current_order_label.vertical_alignment=VERTICAL_ALIGNMENT_TOP; receipt_margin.add_child(host.current_order_label)
	host._set_receipt_open(false, false)
	host.basket_label=Label.new(); host.basket_label.position=Vector2(24,646); host.basket_label.size=Vector2(450,54); host.basket_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; host.basket_label.clip_text=true; host.basket_label.add_theme_constant_override("line_spacing",1); host.basket_label.add_theme_font_size_override("font_size",14); host.basket_label.z_index=5; layer.add_child(host.basket_label)
	host.result_label=Label.new(); host.result_label.position=Vector2(350,108); host.result_label.size=Vector2(580,30); host.result_label.autowrap_mode=TextServer.AUTOWRAP_OFF; host.result_label.clip_text=true; host.result_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; host.result_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; host.result_label.add_theme_color_override("font_outline_color",Color(0,0,0,0.9)); host.result_label.add_theme_constant_override("outline_size",4); host.result_label.add_theme_font_size_override("font_size",14); host.result_label.z_index=10; layer.add_child(host.result_label)
	host.broth_progress_bar=ProgressBar.new(); host.broth_progress_bar.position=Vector2(390,555); host.broth_progress_bar.size=Vector2(500,26); host.broth_progress_bar.min_value=0; host.broth_progress_bar.max_value=100; host.broth_progress_bar.value=0; host.broth_progress_bar.visible=false; layer.add_child(host.broth_progress_bar)
	host.broth_progress_label=Label.new(); host.broth_progress_label.position=Vector2(390,525); host.broth_progress_label.size=Vector2(500,28); host.broth_progress_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; host.broth_progress_label.add_theme_font_size_override("font_size",17); host.broth_progress_label.visible=false; layer.add_child(host.broth_progress_label)
	host.customer_status_label=Label.new(); host.customer_status_label.position=Vector2(420,20); host.customer_status_label.size=Vector2(450,80); host.customer_status_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; host.customer_status_label.add_theme_font_size_override("font_size",18); layer.add_child(host.customer_status_label)
	host._build_order_panel(layer)
	host._apply_ui_theme()
	host._generate_orders()
	host._refresh_hud()

func build_order_panel(layer: CanvasLayer) -> void:
	host.monitor_backdrop=ColorRect.new()
	host.monitor_backdrop.name="MonitorBackdrop"
	host.monitor_backdrop.color=Color("#182633")
	host.monitor_backdrop.mouse_filter=Control.MOUSE_FILTER_STOP
	host.monitor_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.monitor_backdrop.visible=false
	layer.add_child(host.monitor_backdrop)
	host.order_panel=PanelContainer.new()
	host.order_panel.name="MonitorScreen"
	host.order_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.order_panel.visible=false
	host.order_panel.mouse_filter=Control.MOUSE_FILTER_STOP
	layer.add_child(host.order_panel)
	var panel_style:=StyleBoxFlat.new()
	panel_style.bg_color=Color("#f4eddd")
	host.order_panel.add_theme_stylebox_override("panel",panel_style)
	var root:=VBoxContainer.new()
	root.add_theme_constant_override("separation",12)
	root.add_theme_constant_override("margin_left",22)
	root.add_theme_constant_override("margin_right",22)
	root.add_theme_constant_override("margin_top",18)
	root.add_theme_constant_override("margin_bottom",18)
	host.order_panel.add_child(root)
	var header:=PanelContainer.new()
	header.name="MonitorHeader"
	header.custom_minimum_size=Vector2(0,88)
	var header_style:=StyleBoxFlat.new()
	header_style.bg_color=Color("#314e63")
	header_style.border_color=Color("#6f91a6")
	header_style.set_border_width_all(2)
	header_style.set_corner_radius_all(10)
	header.add_theme_stylebox_override("panel",header_style)
	root.add_child(header)
	var header_content:=HBoxContainer.new()
	header_content.add_theme_constant_override("separation",18)
	header.add_child(header_content)
	var title:=Label.new()
	title.name="MonitorTitle"
	title.text="\uB9C8\uB77C\uD0D5 \uAC00\uAC8C"
	title.custom_minimum_size=Vector2(250,0)
	title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",26)
	title.add_theme_color_override("font_color",Color("#f5f0df"))
	header_content.add_child(title)
	host.store_status_label=Label.new()
	host.store_status_label.name="StoreStatus"
	host.store_status_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	host.store_status_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	host.store_status_label.add_theme_font_size_override("font_size",15)
	host.store_status_label.add_theme_color_override("font_color",Color("#d7e6ee"))
	header_content.add_child(host.store_status_label)
	var monitor_close:=Button.new()
	monitor_close.name="MonitorCloseButton"
	monitor_close.text="×"
	monitor_close.custom_minimum_size=Vector2(52,52)
	monitor_close.add_theme_font_size_override("font_size",30)
	monitor_close.pressed.connect(host._close_monitor)
	header_content.add_child(monitor_close)
	host.next_day_button=Button.new()
	host.next_day_button.name="NextDayTopButton"
	host.next_day_button.text="\uB2E4\uC74C \uB0A0 \uC2DC\uC791\uD558\uAE30"
	host.next_day_button.custom_minimum_size=Vector2(0,52)
	host.next_day_button.visible=false
	host.next_day_button.pressed.connect(host._show_next_day_confirmation)
	root.add_child(host.next_day_button)
	var tabs:=HBoxContainer.new()
	tabs.add_theme_constant_override("separation",10)
	root.add_child(tabs)
	var orders_tab:=Button.new()
	orders_tab.name="OrdersTab"
	_configure_monitor_tab(orders_tab,"\uC8FC\uBB38 \uAD00\uB9AC","res://assets/ui/ingredients/sukju.svg")
	orders_tab.pressed.connect(host._show_orders)
	tabs.add_child(orders_tab)
	var shop_tab:=Button.new()
	shop_tab.name="ShopTab"
	_configure_monitor_tab(shop_tab,"\uC7AC\uB8CC \uAD6C\uB9E4","res://assets/ui/ingredients/jung_guk.svg")
	shop_tab.pressed.connect(host._show_shop)
	tabs.add_child(shop_tab)
	var upgrade_tab:=Button.new()
	upgrade_tab.name="UpgradeTab"
	_configure_monitor_tab(upgrade_tab,"\uAC00\uAC8C \uC5C5\uADF8\uB808\uC774\uB4DC","res://assets/ui/ingredients/gan_doufu.svg")
	upgrade_tab.pressed.connect(host._show_upgrades)
	tabs.add_child(upgrade_tab)
	var management_tab:=Button.new()
	management_tab.name="ManagementTab"
	_configure_monitor_tab(management_tab,"\uAC00\uAC8C \uAD00\uB9AC","res://assets/ui/ingredients/cheonggyeongchae.svg")
	management_tab.pressed.connect(host._show_management)
	tabs.add_child(management_tab)
	host.monitor_message_label=Label.new()
	host.monitor_message_label.name="MonitorMessage"
	host.monitor_message_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	host.monitor_message_label.visible=false
	root.add_child(host.monitor_message_label)
	var order_scroll:=ScrollContainer.new()
	order_scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	order_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	root.add_child(order_scroll)
	host.order_list=VBoxContainer.new()
	host.order_list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	order_scroll.add_child(host.order_list)
	host.reset_confirmation=ConfirmationDialog.new()
	host.reset_confirmation.name="ResetConfirmation"
	host.reset_confirmation.title="\uAC8C\uC784 \uCD08\uAE30\uD654 \uD655\uC778"
	host.reset_confirmation.ok_button_text="\uCD08\uAE30\uD654"
	host.reset_confirmation.cancel_button_text="\uCDE8\uC18C"
	host.reset_confirmation.confirmed.connect(host._reset_game)
	layer.add_child(host.reset_confirmation)
	host.next_day_confirmation=ConfirmationDialog.new()
	host.next_day_confirmation.name="NextDayConfirmation"
	host.next_day_confirmation.title="\uB2E4\uC74C \uB0A0 \uC2DC\uC791 \uD655\uC778"
	host.next_day_confirmation.ok_button_text="\uB2E4\uC74C \uB0A0 \uC2DC\uC791"
	host.next_day_confirmation.cancel_button_text="\uCDE8\uC18C"
	host.next_day_confirmation.confirmed.connect(host._start_next_day)
	layer.add_child(host.next_day_confirmation)

func apply_ui_theme() -> void:
	var button_normal:=StyleBoxFlat.new()
	button_normal.bg_color=Color("#26313b")
	button_normal.border_color=Color("#536575")
	button_normal.set_border_width_all(1)
	button_normal.set_corner_radius_all(5)
	button_normal.content_margin_left=14
	button_normal.content_margin_right=14
	var button_hover:=button_normal.duplicate()
	button_hover.bg_color=Color("#37566a")
	button_hover.border_color=Color("#69c6d8")
	var button_pressed:=button_normal.duplicate()
	button_pressed.bg_color=Color("#1a8292")
	button_pressed.border_color=Color("#92efff")
	for button in [host.receipt_toggle_button]:
		if is_instance_valid(button):
			button.add_theme_stylebox_override("normal",button_normal)
			button.add_theme_stylebox_override("hover",button_hover)
			button.add_theme_stylebox_override("pressed",button_pressed)
			button.add_theme_color_override("font_color",Color("#e8f5f7"))
			button.add_theme_color_override("font_hover_color",Color.WHITE)
	for button in host.order_panel.find_children("", "Button", true, false):
		button.add_theme_stylebox_override("normal",button_normal)
		button.add_theme_stylebox_override("hover",button_hover)
		button.add_theme_stylebox_override("pressed",button_pressed)
		button.add_theme_color_override("font_color",Color("#e8f5f7"))
		button.add_theme_color_override("font_hover_color",Color.WHITE)
		button.add_theme_font_size_override("font_size",16)
	if is_instance_valid(host.prompt_label):
		host.prompt_label.add_theme_color_override("font_color",Color("#ffe082"))
		host.prompt_label.add_theme_color_override("font_shadow_color",Color(0,0,0,0.85))
		host.prompt_label.add_theme_constant_override("shadow_offset_x",2)
		host.prompt_label.add_theme_constant_override("shadow_offset_y",2)

func refresh_upgrade_panel() -> void:
	var description:=Label.new()
	description.text="가게 업그레이드"
	description.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	host.order_list.add_child(description)
	_add_upgrade_button("재료 보관량", "stock", 50000, "재료 보관량 +5")
	_add_upgrade_button("조리 속도", "cooking", 65000, "조리 시간 단축")
	_add_upgrade_button("이동 속도", "movement", 60000, "이동 속도 증가")
	if host.store_stage==1 and not host.pending_upgrades.has("stage2"):
		_add_upgrade_button("가게 2단계 확장", "stage2", 350000, "매장 손님 공간 잠금 해제")
	elif host.store_stage==2 and not host.pending_upgrades.has("stage3"):
		_add_upgrade_button("가게 3단계 확장", "stage3", 700000, "테이블 공간 확장")
	var day_button:=Button.new()
	day_button.text="영업 종료 및 정산"
	day_button.custom_minimum_size=Vector2(0,58)
	day_button.pressed.connect(host._end_day)
	host.order_list.add_child(day_button)

func _add_upgrade_button(title: String, key: String, price: int, detail: String) -> void:
	var button:=Button.new()
	button.text="%s · %d원\\n%s | 현재 레벨 %d" % [title,price,detail,int(host.upgrade_levels.get(key,0))]
	button.custom_minimum_size=Vector2(0,65)
	button.pressed.connect(host._purchase_upgrade.bind(key,price,title))
	host.order_list.add_child(button)

func refresh_settlement_panel() -> void:
	var average_rating:float=host.daily_rating_total/float(host.daily_completed_orders) if host.daily_completed_orders>0 else host.rating
	var net_profit:int=host.daily_sales-host.daily_material_cost
	var title:=Label.new()
	title.text="\\uC601\\uC5C5 \\uC815\\uC0B0"
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",28)
	title.add_theme_color_override("font_color",Color("#294052"))
	host.order_list.add_child(title)
	var subtitle:=Label.new()
	subtitle.text="\\uC624\\uB298\\uC758 \\uC601\\uC5C5 \\uACB0\\uACFC\\uC640 \\uB2E4\\uC74C \\uB0A0 \\uC900\\uBE44 \\uC0C1\\uD0DC\\uC785\\uB2C8\\uB2E4."
	subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	host.order_list.add_child(subtitle)
	var stats:=GridContainer.new()
	stats.columns=3
	stats.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	stats.add_theme_constant_override("h_separation",12)
	stats.add_theme_constant_override("v_separation",12)
	host.order_list.add_child(stats)
	var values:Array=[["\\uC624\\uB298 \\uB9E4\\uCD9C",str(host.daily_sales)+"\\uC6D0"],["\\uC7AC\\uB8CC\\uBE44",str(host.daily_material_cost)+"\\uC6D0"],["\\uC21C\\uC774\\uC775",str(net_profit)+"\\uC6D0"],["\\uBCF4\\uC720\\uAE08",str(host.money)+"\\uC6D0"],["\\uC644\\uB8CC \\uC8FC\\uBB38",str(host.daily_completed_orders)+"\\uAC74"],["\\uD3C9\\uC810",("%.1f" % average_rating)+"\\uC810"]]
	for item in values:
		var card:=PanelContainer.new()
		card.custom_minimum_size=Vector2(0,112)
		var card_style:=StyleBoxFlat.new()
		card_style.bg_color=Color("#ffffff")
		card_style.border_color=Color("#d2b98e")
		card_style.set_border_width_all(1)
		card_style.set_corner_radius_all(8)
		card.add_theme_stylebox_override("panel",card_style)
		var content:=VBoxContainer.new()
		content.alignment=BoxContainer.ALIGNMENT_CENTER
		card.add_child(content)
		var key_label:=Label.new()
		key_label.text=item[0]
		key_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(key_label)
		var value_label:=Label.new()
		value_label.text=item[1]
		value_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		value_label.add_theme_font_size_override("font_size",24)
		value_label.add_theme_color_override("font_color",Color("#294052"))
		content.add_child(value_label)
		stats.add_child(card)
	var pending:=Label.new()
	pending.text="\\uB2E4\\uC74C \\uB0A0 \\uC5C5\\uADF8\\uB808\\uC774\\uB4DC: "+("\\uC5C6\\uC74C" if host.pending_upgrades.is_empty() else ", ".join(host.pending_upgrades))
	pending.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	pending.add_theme_font_size_override("font_size",17)
	host.order_list.add_child(pending)
	var next_day:=Button.new()
	next_day.text="Confirm - %d day start" % (host.day+1)
	next_day.custom_minimum_size=Vector2(0,58)
	next_day.pressed.connect(host._start_next_day)
	host.order_list.add_child(next_day)

func refresh_order_panel() -> void:
	if not host.order_list: return
	host.call_deferred("_style_monitor_controls")
	for child in host.order_list.get_children(): child.queue_free()
	if is_instance_valid(host.store_status_label):
		var current_time: String=host._game_clock_text()
		host.store_status_label.text="영업 %d일차  |  매출 %d건  |  보유금 %d원  |  평점 %.1f" % [host.day,host.daily_sales,host.money,host.rating]
	if is_instance_valid(host.next_day_button): host.next_day_button.visible=host.monitor_mode=="settlement"
	if host.monitor_mode == "shop":
		host._refresh_shop_panel()
		return
	if host.monitor_mode == "upgrades":
		refresh_upgrade_panel()
		return
	if host.monitor_mode == "settlement":
		refresh_settlement_panel()
		return
	if host.monitor_mode == "management":
		refresh_management_panel()
		return
	if not host._is_shop_open():
		var closed_hint:=Label.new()
		closed_hint.text="현재 영업 시간이 아닙니다. 영업 시간: 10:00 - 22:00"
		if host.game_clock_minutes>=float(host.CLOSING_HOUR*60):
			closed_hint.text="오늘 영업이 종료되었습니다. 다음 영업일을 시작해주세요."
		closed_hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		closed_hint.add_theme_font_size_override("font_size",22)
		host.order_list.add_child(closed_hint)
		return
	if host.orders.is_empty():
		var empty:=Label.new(); empty.text="현재 들어온 주문이 없습니다."; empty.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; host.order_list.add_child(empty); return
	var order_grid:=GridContainer.new()
	order_grid.columns=2
	order_grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	order_grid.add_theme_constant_override("h_separation",14)
	order_grid.add_theme_constant_override("v_separation",14)
	host.order_list.add_child(order_grid)
	for order in host.orders:
		var button:=Button.new()
		button.text="%s | %s | 조리 %d초 | 보상 %d원" % [korean_order_name(order.id),korean_spice_name(order.spice),order.time,order.reward]
		button.text=""
		# GridContainer??????????? ?????????????븐뼐??????????⑥ル럵傭??????釉먮폁????????????釉먮폁????????????꿔꺂???猷명ц땻?????????ш끽紐?????? ???????꿔꺂???????????嶺뚮ㅎ?볠꽴?????????????癲?????????????遺얘턁????????
		button.custom_minimum_size=Vector2(520,190)
		var row:=HBoxContainer.new()
		row.set_anchors_preset(Control.PRESET_FULL_RECT)
		row.offset_left=12; row.offset_top=8; row.offset_right=-12; row.offset_bottom=-8
		row.add_theme_constant_override("separation",14)
		row.mouse_filter=Control.MOUSE_FILTER_IGNORE
		button.add_child(row)
		var order_info:=Label.new()
		order_info.custom_minimum_size=Vector2(175,0)
		order_info.text="%s\n%s\n조리 시간: %d초\n남은 시간: %d초\n보상: %d원" % [korean_order_name(order.id),korean_spice_name(order.spice),order.time,int(ceil(float(order.get("accept_time",0.0)))),order.reward]
		order_info.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		order_info.mouse_filter=Control.MOUSE_FILTER_IGNORE
		row.add_child(order_info)
		var ingredient_grid:=GridContainer.new()
		ingredient_grid.columns=2
		ingredient_grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		ingredient_grid.add_theme_constant_override("h_separation",10)
		ingredient_grid.add_theme_constant_override("v_separation",5)
		ingredient_grid.mouse_filter=Control.MOUSE_FILTER_IGNORE
		var ingredient_counts: Dictionary={}
		for ingredient in order.ingredients:
			var ingredient_name:=str(ingredient)
			ingredient_counts[ingredient_name]=int(ingredient_counts.get(ingredient_name,0))+1
		for ingredient_name in ingredient_counts:
			var ingredient_row:=HBoxContainer.new()
			ingredient_row.custom_minimum_size=Vector2(0,78)
			ingredient_row.mouse_filter=Control.MOUSE_FILTER_IGNORE
			var ingredient_icon:=TextureRect.new()
			ingredient_icon.custom_minimum_size=Vector2(68,68)
			ingredient_icon.custom_maximum_size=Vector2(68,68)
			ingredient_icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			ingredient_icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ingredient_icon.texture=load(host._ingredient_order_icon_path(ingredient_name)) as Texture2D
			ingredient_icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
			var model_preview:Control=host._make_ingredient_model_preview(ingredient_name,68)
			if is_instance_valid(model_preview):
				ingredient_row.add_child(model_preview)
				ingredient_icon.visible=false
			else:
				ingredient_row.add_child(ingredient_icon)
			var ingredient_label:=Label.new()
			ingredient_label.text="%s  × %d" % [korean_ingredient_name(ingredient_name),int(ingredient_counts[ingredient_name])]
			ingredient_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
			ingredient_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			ingredient_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
			ingredient_row.add_child(ingredient_label)
			ingredient_grid.add_child(ingredient_row)
		row.add_child(ingredient_grid)
		button.pressed.connect(host._accept_order.bind(order)); order_grid.add_child(button)

func refresh_management_panel() -> void:
	var title:=Label.new()
	title.text="\uAC00\uAC8C \uAD00\uB9AC"
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",24)
	host.order_list.add_child(title)
	var hint:=Label.new()
	hint.text="\uC800\uC7A5, \uC885\uB8CC, \uAC8C\uC784 \uC124\uC815\uC744 \uAD00\uB9AC\uD558\uB294 \uBA54\uB274\uC785\uB2C8\uB2E4."
	hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size",16)
	host.order_list.add_child(hint)
	var close:=Button.new()
	close.text="\uB2EB\uAE30 (ESC)"
	close.custom_minimum_size=Vector2(0,64)
	close.pressed.connect(host._close_monitor)
	host.order_list.add_child(close)
	var save_button:=Button.new()
	save_button.text="\uD604\uC7AC \uC9C4\uD589 \uC0C1\uD669 \uC800\uC7A5"
	save_button.custom_minimum_size=Vector2(0,64)
	save_button.pressed.connect(host._save_game.bind(true))
	host.order_list.add_child(save_button)
	var reset_button:=Button.new()
	reset_button.text="\uAC8C\uC784 \uCD08\uAE30\uD654"
	reset_button.custom_minimum_size=Vector2(0,64)
	reset_button.pressed.connect(host._show_reset_confirmation)
	host.order_list.add_child(reset_button)

func refresh_shop_panel() -> void:
	var hint:=Label.new(); hint.text="Select ingredients to purchase."; hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; host.order_list.add_child(hint)
	var grid:=GridContainer.new(); grid.columns=4; grid.add_theme_constant_override("h_separation",10); grid.add_theme_constant_override("v_separation",8); host.order_list.add_child(grid)
	for ingredient in host.INGREDIENTS:
		var ingredient_name:=str(ingredient[0])
		var buy_amount: int=5+int(host.upgrade_levels["stock"])*5
		var button:=Button.new(); button.text=""; button.custom_minimum_size=Vector2(220,88); button.pressed.connect(host._add_ingredient_to_cart.bind(ingredient_name)); grid.add_child(button)
		var row:=HBoxContainer.new(); row.set_anchors_preset(Control.PRESET_FULL_RECT); row.offset_left=8; row.offset_top=6; row.offset_right=-8; row.offset_bottom=-6; row.alignment=BoxContainer.ALIGNMENT_CENTER; row.add_theme_constant_override("separation",8); row.mouse_filter=Control.MOUSE_FILTER_IGNORE; button.add_child(row)
		var icon:=TextureRect.new(); icon.custom_minimum_size=Vector2(52,52); icon.custom_maximum_size=Vector2(52,52); icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; icon.texture=load(host._ingredient_order_icon_path(ingredient_name)); icon.mouse_filter=Control.MOUSE_FILTER_IGNORE; row.add_child(icon)
		var model_preview:Control=host._make_ingredient_model_preview(ingredient_name,52)
		if is_instance_valid(model_preview):
			row.add_child(model_preview)
			icon.visible=false
		var details:=Label.new(); details.size_flags_horizontal=Control.SIZE_EXPAND_FILL; details.text="%s\\nStock %d\\nBuy +%d" % [ingredient_name,int(host.stock.get(ingredient_name,0)),buy_amount]; details.vertical_alignment=VERTICAL_ALIGNMENT_CENTER; details.mouse_filter=Control.MOUSE_FILTER_IGNORE; row.add_child(details)
	var package_button:=Button.new(); package_button.text="Packaging\\n%d 쨌 Buy +10" % host.packaging; package_button.custom_minimum_size=Vector2(0,72); package_button.pressed.connect(host._buy_packaging); host.order_list.add_child(package_button)

	var broth_button:=Button.new()
	broth_button.text="Broth packs\\n%d 쨌 Buy +5" % host.broth_stock_packs
	broth_button.icon=load("res://assets/models/broth_stock/stock_pack.png") as Texture2D
	broth_button.expand_icon=true
	broth_button.custom_minimum_size=Vector2(0,58)
	broth_button.pressed.connect(host._add_broth_to_cart)
	host.order_list.add_child(broth_button)
	var cart_label:=Label.new()
	cart_label.text=host._purchase_cart_summary()
	cart_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	cart_label.add_theme_font_size_override("font_size",17)
	host.order_list.add_child(cart_label)
	var checkout_button:=Button.new()
	checkout_button.text="Checkout 쨌 %d won" % host._purchase_cart_total()
	checkout_button.custom_minimum_size=Vector2(0,58)
	checkout_button.disabled=host._purchase_cart_total()<=0
	checkout_button.pressed.connect(host._checkout_purchase_cart)
	host.order_list.add_child(checkout_button)

func refresh_shop_panel_korean() -> void:
	var hint:=Label.new()
	hint.text="필요한 재료와 소모품을 선택해 구매하세요."
	hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size",18)
	host.order_list.add_child(hint)
	var grid:=GridContainer.new()
	grid.columns=3
	grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",12)
	grid.add_theme_constant_override("v_separation",12)
	host.order_list.add_child(grid)
	for ingredient in host.INGREDIENTS:
		var ingredient_name:=str(ingredient[0])
		var buy_amount: int=5+int(host.upgrade_levels["stock"])*5
		var card:=PanelContainer.new()
		card.custom_minimum_size=Vector2(0,220)
		var card_style:=StyleBoxFlat.new()
		card_style.bg_color=Color("#fffdf7")
		card_style.border_color=Color("#d2b98e")
		card_style.set_border_width_all(1)
		card_style.set_corner_radius_all(8)
		card.add_theme_stylebox_override("panel",card_style)
		grid.add_child(card)
		var card_box:=VBoxContainer.new()
		card_box.add_theme_constant_override("separation",5)
		card_box.add_theme_constant_override("margin_left",10)
		card_box.add_theme_constant_override("margin_right",10)
		card_box.add_theme_constant_override("margin_top",8)
		card_box.add_theme_constant_override("margin_bottom",8)
		card.add_child(card_box)
		var model_preview:Control=host._make_ingredient_model_preview(ingredient_name,104)
		if is_instance_valid(model_preview):
			model_preview.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			card_box.add_child(model_preview)
		else:
			var icon:=TextureRect.new()
			icon.custom_minimum_size=Vector2(0,104)
			icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.texture=load(host._ingredient_order_icon_path(ingredient_name))
			card_box.add_child(icon)
		var name_label:=Label.new()
		name_label.text=korean_ingredient_name(ingredient_name)
		name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size",18)
		card_box.add_child(name_label)
		var price_label:=Label.new()
		price_label.text="보유 %d개  ·  구매 +%d개" % [int(host.stock.get(ingredient_name,0)),buy_amount]
		price_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		price_label.add_theme_font_size_override("font_size",14)
		card_box.add_child(price_label)
		var buy_button:=Button.new()
		buy_button.name="ShopBuyButton"
		buy_button.text="담기"
		buy_button.custom_minimum_size=Vector2(0,36)
		buy_button.pressed.connect(host._add_ingredient_to_cart.bind(ingredient_name))
		card_box.add_child(buy_button)
	var utility_row:=HBoxContainer.new()
	utility_row.add_theme_constant_override("separation",12)
	host.order_list.add_child(utility_row)
	var package_button:=Button.new()
	package_button.text="포장 용기\n현재 %d개 · +10개 구매" % host.packaging
	package_button.custom_minimum_size=Vector2(0,64)
	package_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	package_button.pressed.connect(host._buy_packaging)
	utility_row.add_child(package_button)
	var broth_button:=Button.new()
	broth_button.text="육수팩\n현재 %d개 · +5개 구매" % host.broth_stock_packs
	broth_button.custom_minimum_size=Vector2(0,64)
	broth_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	broth_button.pressed.connect(host._add_broth_to_cart)
	utility_row.add_child(broth_button)
	var cart_label:=Label.new()
	cart_label.text=host._purchase_cart_summary()
	cart_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	cart_label.add_theme_font_size_override("font_size",17)
	host.order_list.add_child(cart_label)
	var checkout_button:=Button.new()
	checkout_button.text="장바구니 결제 · %d원" % host._purchase_cart_total()
	checkout_button.custom_minimum_size=Vector2(0,58)
	checkout_button.disabled=host._purchase_cart_total()<=0
	checkout_button.pressed.connect(host._checkout_purchase_cart)
	host.order_list.add_child(checkout_button)

func open_monitor() -> void:
	if host.monitor_camera_focused: return
	var player:=host.get_node_or_null("Player") as CharacterBody3D
	if not is_instance_valid(player) or not is_instance_valid(host.camera): return
	host.monitor_camera_focused=true
	host._show_monitor_message("")
	host.monitor_player_original_transform=player.global_transform
	host.monitor_camera_original_transform=host.camera.global_transform
	host.monitor_camera_original_rotation=host.camera.rotation
	host.monitor_camera_original_fov=host.camera.fov
	host._set_gameplay_hud_visible(false)
	player.input_locked=true
	if is_instance_valid(host.held_tools): host.held_tools.visible=false
	host.prompt_label.text=""
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	# Move the actual 3D host.camera toward the monitor screen. The player stays in
	# place; this is a smooth dolly-in like moving into a laptop display.
	var monitor:=host.find_child("OrderMonitorModel",true,false) as Node3D
	var monitor_position:=Vector3(6.55,1.48,-3.95)
	if is_instance_valid(monitor): monitor_position=monitor.global_position
	var monitor_basis:=Basis.IDENTITY
	if is_instance_valid(monitor): monitor_basis=monitor.global_transform.basis.orthonormalized()
	var screen_normal:Vector3=monitor_basis*Vector3(0,0,1)
	var monitor_screen:=monitor_position+screen_normal*0.10+Vector3(0,0.12,0)
	var focus_position:=monitor_screen+screen_normal*0.22
	# The player is the yaw parent of the first-person host.camera. Move that parent
	# and rotate it toward the monitor so diagonal interactions also face the
	# screen instead of keeping the old heading.
	var focus_yaw:float=atan2(-(monitor_screen.x-focus_position.x),-(monitor_screen.z-focus_position.z))
	var player_focus_position:Vector3=focus_position-Basis(Vector3.UP,focus_yaw)*host.camera.position
	player_focus_position.y=player.global_position.y
	var camera_height:float=player_focus_position.y+host.camera.position.y
	var horizontal_distance:float=Vector2(monitor_screen.x-focus_position.x,monitor_screen.z-focus_position.z).length()
	var focus_pitch:float=atan2(monitor_screen.y-camera_height,horizontal_distance)
	if is_instance_valid(host.monitor_camera_tween): host.monitor_camera_tween.kill()
	host.monitor_camera_tween=create_tween().set_parallel(true)
	host.monitor_camera_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	host.monitor_camera_tween.tween_property(player,"global_position",player_focus_position,0.70)
	var start_yaw:float=player.global_rotation.y
	var yaw_delta:float=angle_difference(start_yaw,focus_yaw)
	host.monitor_camera_tween.tween_method(func(progress: float): player.global_rotation.y=start_yaw+yaw_delta*progress,0.0,1.0,0.70)
	host.monitor_camera_tween.tween_property(host.camera,"rotation:x",focus_pitch,0.70)
	host.monitor_camera_tween.tween_property(host.camera,"fov",34.0,0.70)
	host.monitor_backdrop.visible=false
	host.order_panel.visible=false
	await host.monitor_camera_tween.finished
	if not host.monitor_camera_focused: return
	host.monitor_backdrop.modulate.a=0.0
	host.order_panel.modulate.a=0.0
	host.monitor_backdrop.visible=true
	host.order_panel.visible=true
	host._refresh_order_panel()
	var monitor_ui_tween:=create_tween().set_parallel(true)
	monitor_ui_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	monitor_ui_tween.tween_property(host.monitor_backdrop,"modulate:a",1.0,0.20)
	monitor_ui_tween.tween_property(host.order_panel,"modulate:a",1.0,0.28)

func close_monitor() -> void:
	if not host.monitor_camera_focused:
		host.monitor_backdrop.visible=false
		host.order_panel.visible=false
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
		return
	host.order_panel.visible=false
	host.monitor_backdrop.visible=false
	host.monitor_backdrop.modulate.a=1.0
	host.order_panel.modulate.a=1.0
	host.monitor_camera_focused=false
	Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	var player:=host.get_node_or_null("Player") as CharacterBody3D
	if is_instance_valid(player): player.global_transform=host.monitor_player_original_transform
	host.camera.global_transform=host.monitor_camera_original_transform
	host.camera.rotation=host.monitor_camera_original_rotation
	host.camera.fov=host.monitor_camera_original_fov
	finish_monitor_return()

func ingredient_icon_path(ingredient_name: String) -> String:
	var paths:Dictionary={
		"\\uCCAD\\uACBD\\uCC44":"res://assets/ui/ingredients/cheonggyeongchae.svg",
		"\\uC54C\\uBC30\\uAE30\\uBC30\\uCD94":"res://assets/ui/ingredients/albaechu.svg",
		"\\uAC74\\uB450\\uBD80":"res://assets/ui/ingredients/gan_doufu.svg",
		"\\uBAA9\\uC774\\uBC84\\uC12F":"res://assets/ui/ingredients/mokiboseot.svg",
		"\\uD301\\uC774\\uBC84\\uC12F":"res://assets/ui/ingredients/paengiboseot.svg",
		"\\uC219\\uC8FC":"res://assets/ui/ingredients/sukju.svg",
		"\\uC911\\uAD6D\\uB2F9\\uBA74":"res://assets/ui/ingredients/jung_guk.svg",
		"\\uBD84\\uBAA8\\uC790":"res://assets/ui/ingredients/bunmoja.svg",
		"\\uD53C\\uC26C\\uBCFC":"res://assets/ui/ingredients/fishball.svg",
		"\\uC18C\\uC2DC\\uC9C0":"res://assets/ui/ingredients/sausage.svg"
	}
	return str(paths.get(ingredient_name,"res://assets/ui/ingredients/cheonggyeongchae.svg"))
