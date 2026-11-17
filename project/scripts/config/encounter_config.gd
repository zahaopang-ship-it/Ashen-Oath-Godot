extends Resource
class_name EncounterConfig

## Authored spatial and patrol data for a single encounter/world layout.
@export_group("Player and boss")
@export var player_spawn := Vector3(0.0, 0.0, 4.0)
@export var player_checkpoint := Vector3(0.0, 0.0, 10.0)
@export var boss_spawn := Vector3(0.0, 0.0, -3.0)
@export_group("West sentinel")
@export var west_sentinel_spawn := Vector3(-7.0, 0.0, -1.0)
@export var west_sentinel_patrol: Array[Vector3] = [Vector3(-7.0, 0.0, -1.0), Vector3(-7.0, 0.0, -7.0), Vector3(-10.0, 0.0, -7.0), Vector3(-10.0, 0.0, -1.0)]
@export var west_sentinel_speed := 1.55
@export var west_sentinel_vision := 12.0
@export var west_sentinel_half_angle := 52.0
@export_group("East sentinel")
@export var east_sentinel_spawn := Vector3(15.0, 0.0, 8.0)
@export var east_sentinel_patrol: Array[Vector3] = [Vector3(15.0, 0.0, 8.0), Vector3(19.0, 0.0, 8.0), Vector3(19.0, 0.0, 13.0), Vector3(14.0, 0.0, 13.0)]
@export var east_sentinel_speed := 1.7
@export var east_sentinel_vision := 13.0
@export_group("North sentinel")
@export var north_sentinel_spawn := Vector3(-15.0, 0.0, -13.0)
@export var north_sentinel_patrol: Array[Vector3] = [Vector3(-15.0, 0.0, -13.0), Vector3(-19.0, 0.0, -13.0), Vector3(-19.0, 0.0, -18.0), Vector3(-13.0, 0.0, -18.0)]
@export var north_sentinel_speed := 1.45
@export_group("World interaction placements")
@export var stealth_cover_positions: Array[Vector3] = [Vector3(-5.1, 0.0, -3.0), Vector3(-9.2, 0.0, -4.5), Vector3(-5.8, 0.0, -8.6)]
@export var grapple_anchor_positions: Array[Vector3] = [Vector3(-2.5, 5.2, 0.0), Vector3(2.5, 5.8, -5.5), Vector3(7.0, 4.8, 1.5)]
@export var training_pond_position := Vector3(9.0, -0.15, -7.0)
@export var training_pond_size := Vector3(5.0, 1.4, 7.0)
@export var climb_wall_position := Vector3(11.8, 2.0, 2.0)
@export var climb_wall_size := Vector3(0.55, 4.0, 7.0)
@export var west_monolith_position := Vector3(-19.0, 0.0, -7.0)
@export var pondside_bell_position := Vector3(14.0, 0.0, -8.0)
@export var secret_cache_position := Vector3(-21.0, 0.0, -8.5)
@export var ashen_shrine_position := Vector3(0.0, 0.0, 8.5)
@export var grove_shrine_position := Vector3(-16.5, 0.0, -18.0)

[executed on device: 7c002306e9ff (fe647cfc-f15d-4336-86f3-23818a8e869a)]