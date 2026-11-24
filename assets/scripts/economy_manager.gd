extends Node

var host

func setup(game_host) -> void:
	host=game_host

func delivery_reward(base_reward: int, score: float) -> int:
	return int(base_reward*(0.35+score*0.65))

func dine_in_reward(base_reward: int, score: float, bonus: int = 300) -> int:
	return int(base_reward*(0.35+score*0.65))+bonus

func average_rating(current_rating: float, completed_orders: int, stars: float) -> float:
	return clampf((current_rating*completed_orders+stars)/float(completed_orders+1),1.0,5.0)

func purchase_cart_total() -> int:
	if not is_instance_valid(host): return 0
	var total:int=host.purchase_cart_packaging*1500+host.purchase_cart_broth*2000
	for ingredient_name in host.purchase_cart:
		total+=int(host.purchase_cart[ingredient_name])*1000
	return total

func _legacy_purchase_cart_summary() -> String:
	if not is_instance_valid(host): return "장바구니: 비어 있음"
	var lines:Array[String]=[]
	for ingredient_name in host.purchase_cart:
		lines.append("%s x%d"%[ingredient_name,int(host.purchase_cart[ingredient_name])])
	if host.purchase_cart_broth>0: lines.append("사골 육수팩 x%d"%host.purchase_cart_broth)
	if host.purchase_cart_packaging>0: lines.append("포장 용기 x%d"%host.purchase_cart_packaging)
	return "장바구니: 비어 있음" if lines.is_empty() else "장바구니: " + " · ".join(lines)

func purchase_cart_summary() -> String:
	if not is_instance_valid(host): return "장바구니: 비어 있음"
	var lines:Array[String]=[]
	for ingredient_name in host.purchase_cart:
		lines.append("%s x%d"%[ingredient_name,int(host.purchase_cart[ingredient_name])])
	if host.purchase_cart_broth>0: lines.append("육수팩 x%d"%host.purchase_cart_broth)
	if host.purchase_cart_packaging>0: lines.append("포장 용기 x%d"%host.purchase_cart_packaging)
	return "장바구니: 비어 있음" if lines.is_empty() else "장바구니: " + " · ".join(lines)

func add_ingredient_to_cart(ingredient_name: String) -> void:
	if not is_instance_valid(host): return
	host.purchase_cart[ingredient_name]=int(host.purchase_cart.get(ingredient_name,0))+1
	host.result_label.text="%s를 장바구니에 담았습니다."%ingredient_name
	host._refresh_order_panel()

func add_packaging_to_cart() -> void:
	if not is_instance_valid(host): return
	host.purchase_cart_packaging+=1
	host.result_label.text="포장 용기 10개를 장바구니에 담았습니다."
	host._refresh_order_panel()

func add_broth_to_cart() -> void:
	if not is_instance_valid(host): return
	host.purchase_cart_broth+=1
	host.result_label.text="사골 육수팩을 장바구니에 담았습니다."
	host._refresh_order_panel()

func checkout_purchase_cart() -> void:
	if not is_instance_valid(host): return
	var total:int=purchase_cart_total()
	if total<=0:
		host.result_label.text="장바구니가 비어 있습니다."
		return
	if host.money<total:
		host._show_monitor_message("장바구니를 구매하기 위한 보유금이 부족합니다.")
		return
	host.money-=total
	host.daily_material_cost+=total
	for ingredient_name in host.purchase_cart:
		var buy_amount:int=5+int(host.upgrade_levels["stock"])*5
		host.stock[ingredient_name]=int(host.stock.get(ingredient_name,0))+buy_amount*int(host.purchase_cart[ingredient_name])
	host.broth_stock_packs+=5*host.purchase_cart_broth
	if host.purchase_cart_broth>0 and is_instance_valid(host.broth_stock_model):
		host.broth_stock_model.visible=true
		host._set_broth_stock_source_enabled(true)
	host.packaging+=10*host.purchase_cart_packaging
	host.purchase_cart.clear()
	host.purchase_cart_packaging=0
	host.purchase_cart_broth=0
	host.result_label.text="장바구니 구매를 완료했습니다."
	host._save_game(false)
	host._refresh_order_panel()
	host._refresh_hud()
