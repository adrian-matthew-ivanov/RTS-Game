@tool
extends Node2D

@export var shader: Shader

const DEFAULT_SHADER_PATH := "res://grass.gdshader"
const MAX_POLYS := 16               # must match the shader
const MAX_POINTS := 256             # total points across all polygons, must match the shader
const RENDERER_NAME := "GrassRenderer"
const EXTENT := 100000.0

var _renderer: Polygon2D
var _warned_empty := false

func _ready() -> void:
	if shader == null and ResourceLoader.exists(DEFAULT_SHADER_PATH):
		shader = load(DEFAULT_SHADER_PATH) as Shader
	if shader == null:
		push_error("Grass: no Shader assigned and %s not found." % DEFAULT_SHADER_PATH)
		return

	_cleanup_old()

	# One renderer for everything, drawn first so the (transparent) polygons sit on top
	_renderer = get_node_or_null(RENDERER_NAME) as Polygon2D
	if _renderer == null:
		_renderer = Polygon2D.new()
		_renderer.name = RENDERER_NAME
		add_child(_renderer)             # no owner, so it isn't saved into the scene file
	move_child(_renderer, 0)
	_renderer.polygon = PackedVector2Array([
		Vector2(-EXTENT, -EXTENT), Vector2(EXTENT, -EXTENT),
		Vector2(EXTENT, EXTENT), Vector2(-EXTENT, EXTENT)])
	_renderer.color = Color.WHITE
	var mat := ShaderMaterial.new()
	mat.shader = shader
	_renderer.material = mat

	for c in get_children():
		_prepare(c)
	child_entered_tree.connect(func(n: Node): _prepare.call_deferred(n))

# Removes leftovers from the older versions
func _cleanup_old() -> void:
	var g: Node = get_node_or_null("GrassGround")
	if g != null:
		g.queue_free()
	# A leftover overlay from the old screen-wide version would paint over everything
	for c in get_children():
		if c is CanvasLayer:
			(c as CanvasLayer).visible = false
			push_warning("Grass: hid the old CanvasLayer '%s'. Delete it from the scene." % c.name)
	for c in get_children():
		if c is Polygon2D and c.name != RENDERER_NAME:
			var old: Node = c.get_node_or_null(RENDERER_NAME)
			if old != null:
				old.queue_free()

func _prepare(node: Node) -> void:
	if node is Polygon2D and node != _renderer:
		var p: Polygon2D = node as Polygon2D
		p.color = Color(0, 0, 0, 0)      # the polygon is only the shape; the shader draws it
		p.texture = null

func _process(_delta: float) -> void:
	if _renderer == null or _renderer.material == null:
		return

	var pts := PackedVector2Array()
	var ranges := PackedVector2Array()
	var bmin := PackedVector2Array()
	var bmax := PackedVector2Array()

	for c in get_children():
		if c == _renderer or not (c is Polygon2D):
			continue
		var poly: Polygon2D = c as Polygon2D
		var local: PackedVector2Array = poly.polygon
		if not poly.visible or local.size() < 3:
			continue
		if ranges.size() >= MAX_POLYS or pts.size() + local.size() > MAX_POINTS:
			push_warning("Grass: polygon/point limit reached, extra polygons are ignored.")
			break

		var xf: Transform2D = poly.global_transform
		var start: int = pts.size()
		var lo: Vector2 = xf * local[0]
		var hi: Vector2 = lo
		for i in local.size():
			var w: Vector2 = xf * local[i]
			pts.append(w)
			lo = Vector2(minf(lo.x, w.x), minf(lo.y, w.y))
			hi = Vector2(maxf(hi.x, w.x), maxf(hi.y, w.y))
		ranges.append(Vector2(float(start), float(local.size())))
		bmin.append(lo)
		bmax.append(hi)

	var count: int = ranges.size()
	if count == 0 and not _warned_empty:
		_warned_empty = true
		push_warning("Grass: no visible Polygon2D children with 3+ points.")

	pts.resize(MAX_POINTS)               # pad to the fixed array sizes
	ranges.resize(MAX_POLYS)
	bmin.resize(MAX_POLYS)
	bmax.resize(MAX_POLYS)

	var mat: ShaderMaterial = _renderer.material as ShaderMaterial
	mat.set_shader_parameter("points", pts)
	mat.set_shader_parameter("poly_range", ranges)
	mat.set_shader_parameter("bounds_min", bmin)
	mat.set_shader_parameter("bounds_max", bmax)
	mat.set_shader_parameter("poly_count", count)
