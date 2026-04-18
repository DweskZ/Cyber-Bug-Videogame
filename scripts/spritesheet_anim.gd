extends Node
class_name SpritesheetAnim

static func add_strip(
	frames: SpriteFrames,
	anim_name: String,
	strip: Texture2D,
	frame_w: int,
	frame_h: int,
	frame_count: int,
	fps: float,
	loop: bool = true
) -> void:
	if frames == null or strip == null:
		return
	if not frames.has_animation(anim_name):
		frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, fps)
	frames.set_animation_loop(anim_name, loop)
	for i in range(frame_count):
		var at := AtlasTexture.new()
		at.atlas = strip
		at.region = Rect2(float(i * frame_w), 0.0, float(frame_w), float(frame_h))
		frames.add_frame(anim_name, at)

static func add_grid(
	frames: SpriteFrames,
	anim_name: String,
	sheet: Texture2D,
	frame_w: int,
	frame_h: int,
	cols: int,
	rows: int,
	frame_count: int,
	fps: float,
	loop: bool = true
) -> void:
	if frames == null or sheet == null:
		return
	if cols <= 0 or rows <= 0:
		return
	if frame_w <= 0 or frame_h <= 0:
		return
	if not frames.has_animation(anim_name):
		frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, fps)
	frames.set_animation_loop(anim_name, loop)
	var total: int = int(min(frame_count, cols * rows))
	for i in range(total):
		var c: int = i % cols
		var r: int = int(i / cols)
		var at := AtlasTexture.new()
		at.atlas = sheet
		at.region = Rect2(float(c * frame_w), float(r * frame_h), float(frame_w), float(frame_h))
		frames.add_frame(anim_name, at)
