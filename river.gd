@tool
extends MeshInstance2D

const MAX_POINTS := 256

@export var path_node: Path2D:
	set(value):
		if path_node == value:
			return
		_disconnect_curve_signal()
		path_node = value
		_connect_curve_signal()
		queue_mesh_regeneration()

@export var width: float = 48.0:
	set(value):
		width = value
		queue_mesh_regeneration()

@export var resolution: int = 50:
	set(value):
		resolution = value
		queue_mesh_regeneration()

@export_tool_button("Regenerate River Mesh", "MeshInstance2D")
var regenerate_button = generate_spline_mesh

var _is_dirty: bool = false
var _connected_curve: Curve2D = null


func _ready() -> void:
	_connect_curve_signal()
	generate_spline_mesh()


func _exit_tree() -> void:
	_disconnect_curve_signal()

func _connect_curve_signal() -> void:
	if path_node != null and path_node.curve != null:
		_connected_curve = path_node.curve
		if not _connected_curve.changed.is_connected(_on_curve_changed):
			_connected_curve.changed.connect(_on_curve_changed)


func _disconnect_curve_signal() -> void:
	if _connected_curve != null and _connected_curve.changed.is_connected(_on_curve_changed):
		_connected_curve.changed.disconnect(_on_curve_changed)
	_connected_curve = null


func _on_curve_changed() -> void:
	queue_mesh_regeneration()

func queue_mesh_regeneration() -> void:
	if not Engine.is_editor_hint():
		generate_spline_mesh()
		return

	if not _is_dirty:
		_is_dirty = true
		call_deferred("_thaw_regeneration")


func _thaw_regeneration() -> void:
	_is_dirty = false
	generate_spline_mesh()

func generate_spline_mesh() -> void:
	if not path_node or not path_node.curve:
		mesh = null
		return

	if path_node.curve != _connected_curve:
		_disconnect_curve_signal()
		_connect_curve_signal()

	var curve: Curve2D = path_node.curve
	var baked_length: float = curve.get_baked_length()

	if baked_length <= 0.0 or resolution <= 0:
		mesh = null
		return

	var points_count: int = clampi(resolution, 1, MAX_POINTS - 1)

	var path_global_transform: Transform2D = path_node.global_transform
	var my_inverse_global_transform: Transform2D = global_transform.inverse()

	var world_points := PackedVector2Array()
	world_points.resize(points_count + 1)

	var min_bound := Vector2(INF, INF)
	var max_bound := Vector2(-INF, -INF)

	for i in range(points_count + 1):
		var t: float = float(i) / points_count
		var offset: float = t * baked_length
		var sample_pos: Vector2 = curve.sample_baked(offset)
		var world_sample: Vector2 = path_global_transform * sample_pos

		world_points[i] = world_sample
		min_bound.x = min(min_bound.x, world_sample.x)
		min_bound.y = min(min_bound.y, world_sample.y)
		max_bound.x = max(max_bound.x, world_sample.x)
		max_bound.y = max(max_bound.y, world_sample.y)

	var half_w: float = width * 0.5
	var margin: float = half_w + 16.0

	var rect_min: Vector2 = min_bound - Vector2(margin, margin)
	var rect_max: Vector2 = max_bound + Vector2(margin, margin)

	var world_tl := Vector2(rect_min.x, rect_min.y)
	var world_tr := Vector2(rect_max.x, rect_min.y)
	var world_br := Vector2(rect_max.x, rect_max.y)
	var world_bl := Vector2(rect_min.x, rect_max.y)

	var local_tl: Vector2 = my_inverse_global_transform * world_tl
	var local_tr: Vector2 = my_inverse_global_transform * world_tr
	var local_br: Vector2 = my_inverse_global_transform * world_br
	var local_bl: Vector2 = my_inverse_global_transform * world_bl

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.add_vertex(Vector3(local_tl.x, local_tl.y, 0.0))
	st.add_vertex(Vector3(local_tr.x, local_tr.y, 0.0))
	st.add_vertex(Vector3(local_br.x, local_br.y, 0.0))
	st.add_vertex(Vector3(local_tl.x, local_tl.y, 0.0))
	st.add_vertex(Vector3(local_br.x, local_br.y, 0.0))
	st.add_vertex(Vector3(local_bl.x, local_bl.y, 0.0))
	mesh = st.commit()

	_sync_shader_params(world_points, points_count + 1)


func _sync_shader_params(world_points: PackedVector2Array, valid_count: int) -> void:
	var shader_mat := material as ShaderMaterial
	if shader_mat == null:
		return

	var padded := world_points.duplicate()
	var last_point: Vector2 = world_points[world_points.size() - 1] if world_points.size() > 0 else Vector2.ZERO
	padded.resize(MAX_POINTS)
	for i in range(valid_count, MAX_POINTS):
		padded[i] = last_point

	shader_mat.set_shader_parameter("path_points", padded)
	shader_mat.set_shader_parameter("point_count", valid_count)
	shader_mat.set_shader_parameter("river_width", width)
