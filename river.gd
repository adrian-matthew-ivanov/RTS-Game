@tool
extends MeshInstance2D

const MAX_SEGMENTS := 256

@export var path_nodes: Array[Path2D] = []:
	set(value):
		if path_nodes == value:
			return
		_disconnect_all_signals()
		path_nodes = value
		_connect_all_signals()
		queue_mesh_regeneration()

@export var path_widths: Array[float] = []:
	set(value):
		path_widths = value
		queue_mesh_regeneration()

@export var default_width: float = 48.0:
	set(value):
		default_width = value
		queue_mesh_regeneration()

@export var resolution: int = 50:
	set(value):
		resolution = value
		queue_mesh_regeneration()

@export_tool_button("Regenerate River Mesh", "MeshInstance2D")
var regenerate_button = generate_spline_mesh

var _is_dirty: bool = false
var _connected_curves: Array[Curve2D] = []

func _ready() -> void:
	_connect_all_signals()
	generate_spline_mesh()

func _exit_tree() -> void:
	_disconnect_all_signals()

func _connect_all_signals() -> void:
	for path in path_nodes:
		if path != null and path.curve != null:
			if not path.curve.changed.is_connected(_on_curve_changed):
				path.curve.changed.connect(_on_curve_changed)
			if not _connected_curves.has(path.curve):
				_connected_curves.append(path.curve)

func _disconnect_all_signals() -> void:
	for curve in _connected_curves:
		if curve != null and curve.changed.is_connected(_on_curve_changed):
			curve.changed.disconnect(_on_curve_changed)
	_connected_curves.clear()

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
	_disconnect_all_signals()
	_connect_all_signals()

	var all_segments: PackedVector4Array = PackedVector4Array()
	var all_widths: PackedFloat32Array = PackedFloat32Array()
	
	var min_bound := Vector2(INF, INF)
	var max_bound := Vector2(-INF, -INF)
	var has_valid_geometry := false

	var my_inverse_global_transform: Transform2D = global_transform.inverse()

	var current_path_index = 0

	for path in path_nodes:
		if not path or not path.curve:
			current_path_index += 1
			continue

		var curve: Curve2D = path.curve
		var baked_length: float = curve.get_baked_length()

		if baked_length <= 0.0 or resolution <= 0:
			current_path_index += 1
			continue
			
		# Match the width array to the path array by index
		var river_width: float = default_width
		if current_path_index < path_widths.size():
			river_width = path_widths[current_path_index]

		var points_count: int = clampi(resolution, 1, MAX_SEGMENTS)
		var path_global_transform: Transform2D = path.global_transform
		
		var prev_world_sample: Vector2
		
		for i in range(points_count + 1):
			var t: float = float(i) / points_count
			var offset: float = t * baked_length
			var sample_pos: Vector2 = curve.sample_baked(offset)
			var world_sample: Vector2 = path_global_transform * sample_pos
			
			min_bound.x = min(min_bound.x, world_sample.x)
			min_bound.y = min(min_bound.y, world_sample.y)
			max_bound.x = max(max_bound.x, world_sample.x)
			max_bound.y = max(max_bound.y, world_sample.y)
			has_valid_geometry = true
			
			if i > 0 and all_segments.size() < MAX_SEGMENTS:
				all_segments.append(Vector4(prev_world_sample.x, prev_world_sample.y, world_sample.x, world_sample.y))
				all_widths.append(river_width)
				
			prev_world_sample = world_sample
			
		current_path_index += 1

	if not has_valid_geometry:
		mesh = null
		return

	var max_padding: float = default_width * 0.5
	for w in all_widths:
		max_padding = max(max_padding, w * 0.5)
		
	var margin: float = max_padding + 16.0

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

	_sync_shader_params(all_segments, all_widths)

func _sync_shader_params(segments: PackedVector4Array, widths: PackedFloat32Array) -> void:
	var shader_mat := material as ShaderMaterial
	if shader_mat == null:
		return

	var valid_count = segments.size()
	
	# Use untyped Arrays to guarantee Godot translates it to uniforms properly
	var final_segments: Array = []
	var final_widths: Array = []
	
	final_segments.resize(MAX_SEGMENTS)
	final_widths.resize(MAX_SEGMENTS)
	
	for i in range(MAX_SEGMENTS):
		if i < valid_count:
			final_segments[i] = segments[i]
			final_widths[i] = widths[i]
		else:
			# CRITICAL FIX: Place unused segments infinitely far away!
			# If set to ZERO, the shader calculates distance to (0,0) and corrupts the math.
			final_segments[i] = Vector4(999999.0, 999999.0, 999999.1, 999999.1)
			final_widths[i] = -1.0 # Negative width flags it to be ignored

	shader_mat.set_shader_parameter("river_segments", final_segments)
	shader_mat.set_shader_parameter("river_widths", final_widths)
	shader_mat.set_shader_parameter("segment_count", valid_count)
