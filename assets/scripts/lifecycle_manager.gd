extends Node

var host

func setup(game_host) -> void:
	host=game_host

func is_shop_open() -> bool:
	if is_instance_valid(host.game_clock_manager):
		return host.game_clock_manager.is_shop_open()
	return host.game_clock_minutes>=float(host.OPENING_HOUR*60) and host.game_clock_minutes<float(host.CLOSING_HOUR*60)

func clock_text() -> String:
	if is_instance_valid(host.game_clock_manager):
		return host.game_clock_manager.clock_text()
	var total_minutes: int=int(host.game_clock_minutes)
	var hour: int=posmod(floori(float(total_minutes)/60.0),24)
	var minute: int=posmod(total_minutes,60)
	return "%02d:%02d"%[hour,minute]

func handle_notification(what: int) -> void:
	if what==host.NOTIFICATION_WM_CLOSE_REQUEST or what==host.NOTIFICATION_APPLICATION_PAUSED:
		save_game(false)

func save_game(show_message: bool=true) -> void:
	if is_instance_valid(host.save_manager):
		host.save_manager.save_game(show_message)

func load_game() -> void:
	if is_instance_valid(host.save_manager):
		host.save_manager.load_game()
