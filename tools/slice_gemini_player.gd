extends SceneTree

# Generates 128px strips for the player from Gemini sheets.
# Run:
#   godot --headless --script res://tools/slice_gemini_player.gd

const OUT_DIR := "res://assets/gemini_generated/characters/player/"

const KEY_THRESHOLD := 0.08

func _init() -> void:
	_make_dir_recursive(OUT_DIR)

	# 4-frame standing (1024x1024 frames, 8px gutter)
	_slice_to_strip(
		"res://assets/gemini_generated/main_character/character_standing.png",
		OUT_DIR + "player_idle.png",
		4,
		1024,
		1024,
		8
	)

	# 6-frame walking/attack (832x832 frames, 16px gutter)
	_slice_to_strip(
		"res://assets/gemini_generated/main_character/character_walking.png",
		OUT_DIR + "player_run.png",
		6,
		832,
		832,
		16
	)

	_slice_to_strip(
		"res://assets/gemini_generated/main_character/character_attack.png",
		OUT_DIR + "player_attack.png",
		6,
		832,
		832,
		16
	)

	print("slice_gemini_player: done")
	quit(0)

func _slice_to_strip(input_path: String, out_path: String, frame_count: int, frame_w: int, frame_h: int, gutter_x: int) -> void:
	var img := Image.load_from_file(input_path)
	if img == null:
		push_error("slice_gemini_player: failed to load %s" % input_path)
		return
	img.convert(Image.FORMAT_RGBA8)

	var out := Image.create(128 * frame_count, 128, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))

	for i in range(frame_count):
		var src_x := i * (frame_w + gutter_x)
		var frame := img.get_region(Rect2i(src_x, 0, frame_w, frame_h))
		if frame == null:
			continue
		# Chroma-key near-black to alpha
		for y in range(frame.get_height()):
			for x in range(frame.get_width()):
				var c := frame.get_pixel(x, y)
				if c.r < KEY_THRESHOLD and c.g < KEY_THRESHOLD and c.b < KEY_THRESHOLD:
					c.a = 0.0
					frame.set_pixel(x, y, c)
		frame.resize(128, 128, Image.INTERPOLATE_LANCZOS)
		out.blit_rect(frame, Rect2i(0, 0, 128, 128), Vector2i(i * 128, 0))

	var err := out.save_png(out_path)
	if err != OK:
		push_error("slice_gemini_player: failed saving %s (err=%s)" % [out_path, str(err)])
	else:
		print("slice_gemini_player: wrote ", out_path)

func _make_dir_recursive(dir_path: String) -> void:
	var abs := ProjectSettings.globalize_path(dir_path)
	DirAccess.make_dir_recursive_absolute(abs)
