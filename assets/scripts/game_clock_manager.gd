extends Node

## Owns clock formatting and opening-hours rules.

var host: Node

func setup(game_host: Node) -> void:
	host = game_host

func is_shop_open() -> bool:
	return host.game_clock_minutes >= float(host.OPENING_HOUR * 60) and host.game_clock_minutes < float(host.CLOSING_HOUR * 60)

func clock_text() -> String:
	var total_minutes := int(host.game_clock_minutes)
	var hour := posmod(floori(float(total_minutes) / 60.0), 24)
	var minute := posmod(total_minutes, 60)
	return "%02d:%02d" % [hour, minute]
