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
