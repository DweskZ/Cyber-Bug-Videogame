extends SceneTree

const OUT_DIR := "res://assets/spritesheets"

func _init() -> void:
	print("BAKE START")
	await _bake_all()
	print("BAKE DONE")
	quit()

func _bake_all() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	await _bake_player()
	await _bake_enemy()
	await _bake_boss()

func _make_viewport(size: Vector2i) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = size
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.disable_3d = true
	get_root().add_child(vp)
	return vp

func _capture(vp: SubViewport) -> Image:
	# Let rendering catch up
	await process_frame
	await process_frame
	var img := vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	return img

func _save_sheet(frames: Array[Image], out_path: String) -> void:
	if frames.is_empty():
		return
	var fw := frames[0].get_width()
	var fh := frames[0].get_height()
	var sheet := Image.create(fw * frames.size(), fh, false, Image.FORMAT_RGBA8)
	for i in frames.size():
		sheet.blit_rect(frames[i], Rect2i(0, 0, fw, fh), Vector2i(i * fw, 0))
	var abs := ProjectSettings.globalize_path(out_path)
	var err := sheet.save_png(abs)
	print("SAVE ", abs, " err=", err)

func _bake_player() -> void:
	var vp := _make_viewport(Vector2i(128, 128))
	var world := Node2D.new()
	vp.add_child(world)

	var tex := load("res://assets/player.svg") as Texture2D
	var slash_tex := load("res://assets/slash.svg") as Texture2D

	var s := Sprite2D.new()
	s.texture = tex
	s.position = Vector2(64, 80)
	world.add_child(s)

	var fx := Sprite2D.new()
	fx.texture = slash_tex
	fx.position = Vector2(88, 78)
	fx.visible = false
	world.add_child(fx)

	# IDLE (4)
	var idle: Array[Image] = []
	for i in 4:
		s.position = Vector2(64, 80 + sin(float(i) / 4.0 * TAU) * 1.5)
		s.scale = Vector2.ONE
		fx.visible = false
		idle.append(await _capture(vp))
	_save_sheet(idle, OUT_DIR + "/player_idle.png")

	# RUN (6)
	var run: Array[Image] = []
	for i in 6:
		var t := float(i) / 6.0 * TAU
		var bob := sin(t) * 2.0
		var squash := 1.0 + sin(t) * 0.06
		s.position = Vector2(64, 80 + bob)
		s.scale = Vector2(squash, 2.0 - squash)
		fx.visible = false
		run.append(await _capture(vp))
	_save_sheet(run, OUT_DIR + "/player_run.png")

	# ATTACK (4)
	var atk: Array[Image] = []
	for i in 4:
		s.position = Vector2(64, 80)
		s.scale = Vector2.ONE
		fx.visible = true
		fx.modulate = Color(1, 1, 1, 0.0 if i == 0 else 0.85)
		fx.scale = Vector2(0.8 + float(i) * 0.12, 0.8 + float(i) * 0.12)
		fx.rotation = 0.0
		atk.append(await _capture(vp))
	_save_sheet(atk, OUT_DIR + "/player_attack.png")

	# DOWN ATTACK (4)
	var datk: Array[Image] = []
	for i in 4:
		s.position = Vector2(64, 80)
		s.scale = Vector2.ONE
		fx.visible = true
		fx.position = Vector2(64, 104)
		fx.modulate = Color(1, 1, 1, 0.0 if i == 0 else 0.85)
		fx.scale = Vector2(0.8 + float(i) * 0.12, 0.8 + float(i) * 0.12)
		fx.rotation = PI / 2.0
		datk.append(await _capture(vp))
	_save_sheet(datk, OUT_DIR + "/player_down_attack.png")

	vp.queue_free()

func _bake_enemy() -> void:
	var vp := _make_viewport(Vector2i(128, 128))
	var world := Node2D.new()
	vp.add_child(world)

	var tex := load("res://assets/enemy.svg") as Texture2D
	var s := Sprite2D.new()
	s.texture = tex
	s.position = Vector2(64, 84)
	world.add_child(s)

	# IDLE (4)
	var idle: Array[Image] = []
	for i in 4:
		s.position = Vector2(64, 84 + sin(float(i) / 4.0 * TAU) * 1.2)
		idle.append(await _capture(vp))
	_save_sheet(idle, OUT_DIR + "/enemy_idle.png")

	# RUN (6)
	var run: Array[Image] = []
	for i in 6:
		var t := float(i) / 6.0 * TAU
		s.position = Vector2(64, 84 + sin(t) * 1.8)
		var squash := 1.0 + sin(t) * 0.05
		s.scale = Vector2(squash, 2.0 - squash)
		run.append(await _capture(vp))
	s.scale = Vector2.ONE
	_save_sheet(run, OUT_DIR + "/enemy_run.png")

	# ATTACK (6) (windup -> lunge)
	var atk: Array[Image] = []
	for i in 6:
		if i < 2:
			s.scale = Vector2(1.1, 0.9)
			s.position = Vector2(64, 84)
		else:
			s.scale = Vector2.ONE
			s.position = Vector2(64 + (i - 1) * 4, 84)
		atk.append(await _capture(vp))
	_save_sheet(atk, OUT_DIR + "/enemy_attack.png")

	vp.queue_free()

func _bake_boss() -> void:
	var vp := _make_viewport(Vector2i(256, 192))
	var world := Node2D.new()
	vp.add_child(world)

	var tex := load("res://assets/openclaw.svg") as Texture2D
	var swipe_tex := load("res://assets/swipe_fx.svg") as Texture2D
	var laser_tex := load("res://assets/laser_fx.svg") as Texture2D
	var slam_tex := load("res://assets/slam_fx.svg") as Texture2D

	var s := Sprite2D.new()
	s.texture = tex
	s.position = Vector2(128, 120)
	world.add_child(s)

	var fx := Sprite2D.new()
	fx.visible = false
	world.add_child(fx)

	# IDLE (4)
	var idle: Array[Image] = []
	for i in 4:
		s.position = Vector2(128, 120 + sin(float(i) / 4.0 * TAU) * 1.0)
		fx.visible = false
		idle.append(await _capture(vp))
	_save_sheet(idle, OUT_DIR + "/boss_idle.png")

	# SWIPE (4)
	var swipe: Array[Image] = []
	for i in 4:
		fx.texture = swipe_tex
		fx.visible = true
		fx.position = Vector2(170, 118)
		fx.rotation = 0.0
		fx.modulate = Color(1, 1, 1, 0.2 + float(i) * 0.2)
		swipe.append(await _capture(vp))
	_save_sheet(swipe, OUT_DIR + "/boss_swipe.png")

	# LASER (4)
	var laser: Array[Image] = []
	for i in 4:
		fx.texture = laser_tex
		fx.visible = true
		fx.position = Vector2(200, 112)
		fx.rotation = 0.0
		fx.modulate = Color(1, 1, 1, 0.25 + float(i) * 0.18)
		laser.append(await _capture(vp))
	_save_sheet(laser, OUT_DIR + "/boss_laser.png")

	# SLAM (4)
	var slam: Array[Image] = []
	for i in 4:
		fx.texture = slam_tex
		fx.visible = true
		fx.position = Vector2(128, 150)
		fx.rotation = 0.0
		fx.scale = Vector2(0.7 + float(i) * 0.18, 0.7 + float(i) * 0.18)
		fx.modulate = Color(1, 1, 1, 0.25 + float(i) * 0.15)
		slam.append(await _capture(vp))
	_save_sheet(slam, OUT_DIR + "/boss_slam.png")

	vp.queue_free()
