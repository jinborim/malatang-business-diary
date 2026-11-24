extends Node

var host:Node

func setup(game_host: Node) -> void:
	host=game_host

func build_quest_ui() -> void:
	if not is_instance_valid(host): return
	var layer:=CanvasLayer.new()
	layer.name="TutorialQuestLayer"
	layer.layer=30
	host.add_child(layer)
	host.tutorial_quest_panel=PanelContainer.new()
	host.tutorial_quest_panel.name="TutorialQuestPanel"
	host.tutorial_quest_panel.position=Vector2(24,92)
	host.tutorial_quest_panel.size=Vector2(300,108)
	var style:=StyleBoxFlat.new()
	style.bg_color=Color(0.04,0.08,0.10,0.72)
	style.border_color=Color("#35ff75")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	host.tutorial_quest_panel.add_theme_stylebox_override("panel",style)
	layer.add_child(host.tutorial_quest_panel)
	var margin:=MarginContainer.new()
	margin.add_theme_constant_override("margin_left",12)
	margin.add_theme_constant_override("margin_right",12)
	margin.add_theme_constant_override("margin_top",9)
	margin.add_theme_constant_override("margin_bottom",9)
	host.tutorial_quest_panel.add_child(margin)
	var content:=VBoxContainer.new()
	content.add_theme_constant_override("separation",3)
	margin.add_child(content)
	var title:=Label.new()
	title.text="튜토리얼"
	title.add_theme_color_override("font_color",Color("#35ff75"))
	title.add_theme_font_size_override("font_size",16)
	content.add_child(title)
	host.tutorial_quest_label=Label.new()
	host.tutorial_quest_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	host.tutorial_quest_label.add_theme_font_size_override("font_size",13)
	content.add_child(host.tutorial_quest_label)
	host.tutorial_quest_panel.visible=false

func start_quests() -> void:
	if not is_instance_valid(host) or host.tutorial_seen or host.day>2: return
	host.tutorial_active=false
	host.tutorial_quest_panel.visible=true
	update_quest(true)

func update_quest(force: bool=false) -> void:
	if not is_instance_valid(host) or host.tutorial_seen or not is_instance_valid(host.tutorial_quest_panel): return
	if host.day>2:
		host.tutorial_seen=true
		host.tutorial_quest_panel.visible=false
		host._save_game(false)
		return
	var completed:bool=false
	match host.tutorial_step:
		0: completed=host.broth_water_added
		1: completed=host.broth_stock_added
		2: completed=host.broth_servings>0
		3: completed=not host.current_order.is_empty()
		4: completed=not host.current_order.is_empty() and host.has_tongs and host.has_bowl
		5: completed=not host.current_order.is_empty() and host.basket.size()>=host.current_order.ingredients.size()
		6: completed=host.selected_spice>0
		7: completed=host.has_ladle and host.ladle_state=="broth"
		8: completed=host.cooking_pot_broth_added
		9: completed=not host.cooked_food.is_empty()
		10: completed=host.tutorial_delivery_done
	if completed:
		host.tutorial_step+=1
		if host.tutorial_step>=11:
			host.tutorial_seen=true
			host.tutorial_quest_panel.visible=false
			host._save_game(false)
			return
	var goal:String=quest_text_v3()
	if force or goal!=host.tutorial_quest_last_text:
		host.tutorial_quest_last_text=goal
		host.tutorial_quest_label.text=goal
		host.tutorial_quest_panel.visible=not host.monitor_camera_focused

func quest_text_v3() -> String:
	if not is_instance_valid(host): return "튜토리얼 완료"
	match host.tutorial_step:
		0: return "1/11  육수 냄비에 물을 넣으세요.\n육수 냄비 옆 수도꼭지에서 E키를 누르세요."
		1:
			if host.broth_stock_pack_open: return "2/11  사골 육수를 냄비에 넣으세요.\n뜯은 육수팩을 들고 냄비에서 E키를 누르세요."
			if host.broth_stock_open_in_world: return "2/11  뜯은 사골 육수팩을 집으세요.\n팩을 바라보고 왼쪽 클릭 또는 E키를 누르세요."
			return "2/11  사골 육수팩을 뜯으세요.\n육수팩을 바라보고 E키로 절취선을 뜯으세요."
		2: return "3/11  육수를 끓이세요.\n육수 냄비에서 E키를 눌러 끓이기를 시작하세요."
		3: return "4/11  주문을 수락하세요.\n주문 모니터에 다가가 E키로 주문을 확인하세요."
		4: return "5/11  집게와 재료 그릇을 챙기세요.\n도구 거치대에서 각각 E키로 집으세요."
		5: return "6/11  주문 재료를 모두 담으세요.\n재료 진열대에서 주문 수량만큼 집으세요."
		6: return "7/11  맵기를 선택하세요.\n맵기 소스에서 1·2·3단계 중 하나를 선택하세요."
		7: return "8/11  완성된 육수를 국자에 담으세요.\n국자를 들고 육수 냄비에서 E키를 누르세요."
		8: return "9/11  육수를 조리 냄비에 부으세요.\n국자를 들고 조리 냄비에서 E키를 누르세요."
		9: return "10/11  마라탕을 조리하세요.\n재료와 맵기가 준비되면 조리 냄비에서 E키를 누르세요."
		10: return "11/11  완성된 주문을 배달하세요.\n완성된 음식을 배달대에 전달하세요."
	return "튜토리얼 완료"

func update_tutorial_page() -> void:
	var pages:Array[Array]=[
		["Move with W A S D", "Look around with the mouse and press E to interact."],
		["Accept an order", "Open the order monitor and accept a delivery order."],
		["Prepare ingredients", "Pick up ingredients one at a time and place them in the bowl."],
		["Finish the meal", "Cook the broth, complete the order, and deliver it."]
	]
	var page:=pages[clampi(host.tutorial_step,0,pages.size()-1)]
	host.tutorial_title.text=str(page[0])
	host.tutorial_body.text=str(page[1])
	host.tutorial_button.text="Next" if host.tutorial_step<pages.size()-1 else "Finish (Enter)"

func advance_tutorial() -> void:
	if not host.tutorial_active: return
	if host.tutorial_step<3:
		host.tutorial_step+=1
		update_tutorial_page()
		return
	host.tutorial_active=false
	host.tutorial_seen=true
	if is_instance_valid(host.tutorial_overlay): host.tutorial_overlay.visible=false
	var player:=host.get_node_or_null("Player") as CharacterBody3D
	if is_instance_valid(player): player.input_locked=false
	if is_instance_valid(host.held_tools): host.held_tools.visible=true
	host._set_gameplay_hud_visible(true)
	Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	host._save_game(false)
