extends RefCounted

## Owns transient combat presentation: hitstop, impact camera response, clash VFX, and spatial SFX.
const HITSTOP_SCALE := 0.055
const AUDIO_EVENTS := {
	"hit": "res://audio/impact_body.wav",
	"deflect": "res://audio/sword_deflect.wav",
	"mikiri": "res://audio/sword_deflect.wav",
	"sweep_evaded": "res://audio/sword_deflect.wav",
	"guard": "res://audio/guard_clang.wav",
	"posture_break": "res://audio/posture_break.wav",
	"death": "res://audio/impact_body.wav",
	"grabbed": "res://audio/impact_body.wav",
	"stomp": "res://audio/posture_break.wav",
	"boss_phase": "res://audio/posture_break.wav",
	"deathblow": "res://audio/sword_deflect.wav"
}

var host: Node3D
var camera_rig: RefCounted
var _hitstop_generation := 0
var _hitstop_previous_scale := 1.0
var _hitstop_active := false


func configure(owner: Node3D, rig: RefCounted) -> void:
	host = owner
	camera_rig = rig


func on_enemy_attack_hit(_target: Node) -> void:
	if is_instance_valid(camera_rig):
		camera_rig.add_impact_impulse(0.22)


func on_player_attack_hit(_target: Node) -> void:
	if is_instance_valid(camera_rig):
		camera_rig.add_impact_impulse(0.13)


func trigger_hitstop(duration: float, strength: float) -> void:
	if not _hitstop_active:
		_hitstop_previous_scale = Engine.time_scale
		_hitstop_active = true
	Engine.time_scale = HITSTOP_SCALE
	_hitstop_generation += 1
	var generation := _hitstop_generation
	if is_instance_valid(camera_rig):
		camera_rig.add_shake(strength)
	host.get_tree().create_timer(duration, true, false, true).timeout.connect(restore_hitstop.bind(generation))


func restore_hitstop(generation: int) -> void:
	if not _hitstop_active or generation != _hitstop_generation:
		return
	Engine.time_scale = _hitstop_previous_scale
	_hitstop_active = false


func handle_feedback(kind: String, source: Node3D) -> void:
	if not is_instance_valid(source):
		return
	var hitstop := 0.045
	var shake := 0.12
	match kind:
		"hit":
			hitstop = 0.052
			shake = 0.22
		"deflect":
			hitstop = 0.072
			shake = 0.34
		"mikiri", "sweep_evaded":
			hitstop = 0.085
			shake = 0.38
		"guard":
			hitstop = 0.025
			shake = 0.12
		"posture_break":
			hitstop = 0.105
			shake = 0.48
		"death":
			hitstop = 0.12
			shake = 0.52
		"grabbed":
			hitstop = 0.07
			shake = 0.36
		"stomp":
			hitstop = 0.085
			shake = 0.42
		"boss_phase":
			hitstop = 0.11
			shake = 0.58
		"deathblow":
			hitstop = 0.16
			shake = 0.72
	trigger_hitstop(hitstop, shake)
	play_combat_sound(kind, source.global_position)
	if kind == "deflect":
		spawn_deflect_clash(source)


func spawn_deflect_clash(source: Node3D) -> void:
	var clash := Node3D.new()
	clash.name = "DeflectClashFX"
	var contact := source.global_position + Vector3.UP * 1.30
	if "target" in source and is_instance_valid(source.get("target")):
		var opponent: Node3D = source.get("target")
		contact = (source.global_position + opponent.global_position) * 0.5 + Vector3.UP * 1.35
	host.add_child(clash)
	clash.global_position = contact
	clash.rotation.y = source.global_rotation.y
	clash.scale = Vector3.ONE * 0.35
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.72, 0.94, 1.0, 1.0)
	material.emission_enabled = true
	material.emission = Color(0.28, 0.78, 1.0)
	material.emission_energy_multiplier = 3.2
	for angle in [-0.68, 0.68]:
		var spark := MeshInstance3D.new()
		var shape := BoxMesh.new()
		shape.size = Vector3(0.055, 0.055, 0.72)
		spark.mesh = shape
		spark.rotation.y = angle
		spark.material_override = material
		clash.add_child(spark)
	var tween := host.create_tween()
	tween.set_parallel(true)
	tween.tween_property(clash, "scale", Vector3.ONE * 1.25, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(material, "albedo_color:a", 0.0, 0.16)
	tween.chain().tween_callback(clash.queue_free)


func play_combat_sound(kind: String, world_position: Vector3) -> void:
	if not AUDIO_EVENTS.has(kind):
		return
	var stream := load(str(AUDIO_EVENTS[kind])) as AudioStream
	if not stream:
		return
	var player_audio := AudioStreamPlayer3D.new()
	player_audio.name = "CombatSFX"
	player_audio.stream = stream
	player_audio.position = world_position
	player_audio.volume_db = -5.0 if kind in ["deflect", "mikiri", "posture_break"] else -9.0
	player_audio.max_distance = 22.0
	player_audio.unit_size = 7.0
	player_audio.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	host.add_child(player_audio)
	player_audio.finished.connect(player_audio.queue_free)
	player_audio.play()
