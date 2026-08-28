extends Node2D

## Sprint 16 dev-only probe: prints DeviceLayout12's detection result and
## the window's actual size so it can be verified headless/via Playwright
## before any real scene depends on it. Not part of the shipped flow.

func _ready() -> void:
	var win := get_window()
	print("PROBE window.size=%s content_scale_size=%s is_portrait=%s" % [
		win.size, win.content_scale_size, DeviceLayout12.is_portrait
	])
