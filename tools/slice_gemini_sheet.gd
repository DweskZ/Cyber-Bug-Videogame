extends SceneTree

# Slice a wide Gemini spritesheet with gutters into a compact strip (e.g., 4x 128x128).
# Run:
#   godot --headless --script res://tools/slice_gemini_sheet.gd

const INPUT_PATH := "res://assets/gemini_generated/main_character/character_standing.png"
const OUTPUT_STRIP_PATH := "res://assets/gemini_generated/characters/player/player_idle.png"

const FRAME_COUNT := 4
const SOURCE_FRAME_W := 1024
const SOURCE_FRAME_H := 1024
const SOURCE_GUTTER_X := 8

const OUT_FRAME_W := 128
const OUT_FRAME_H := 128

# Treat near-black as transparent (helps when the generator bakes a black background).
const KEY_THRESHOLD := 0.06

func _init() -> void:
	var img := Image.load_from_file(INPUT_PATH)
	if img == null:
		push_error("slice_gemini_sheet: failed to load %s" % INPUT_PATH)
		quit(1)
		return
	img.convert(Image.FORMAT_RGBA8)

	var out := Image.create(OUT_FRAME_W * FRAME_COUNT, OUT_FRAME_H, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))

	for i in range(FRAME_COUNT):
		var src_x := i * (SOURCE_FRAME_W + SOURCE_GUTTER_X)
		var src_rect := Rect2i(src_x, 0, SOURCE_FRAME_W, SOURCE_FRAME_H)
		var frame := img.get_region(src_rect)
		if frame == null:
			continue
		# Chroma-key black to alpha
		for y in range(frame.get_height()):
			for x in range(frame.get_width()):
				var c := frame.get_pixel(x, y)
				if c.r < KEY_THRESHOLD and c.g < KEY_THRESHOLD and c.b < KEY_THRESHOLD:
					c.a = 0.0
					frame.set_pixel(x, y, c)

		frame.resize(OUT_FRAME_W, OUT_FRAME_H, Image.INTERPOLATE_LANCZOS)
		out.blit_rect(frame, Rect2i(0, 0, OUT_FRAME_W, OUT_FRAME_H), Vector2i(i * OUT_FRAME_W, 0))

	var err := out.save_png(OUTPUT_STRIP_PATH)
	if err != OK:
		push_error("slice_gemini_sheet: failed saving %s (err=%s)" % [OUTPUT_STRIP_PATH, str(err)])
		quit(1)
		return
	print("slice_gemini_sheet: wrote ", OUTPUT_STRIP_PATH)
	quit(0)
