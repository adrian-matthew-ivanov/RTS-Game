shader_type canvas_item;
render_mode world_vertex_coords;

// Set by the script
uniform vec2 points[256];
uniform vec2 poly_range[16];     // (start index, point count) per polygon
uniform vec2 bounds_min[16];
uniform vec2 bounds_max[16];
uniform int poly_count = 0;

const float pixel_size = 1.0;            // art pixel size in WORLD pixels

// Low ground (LIGHT), inside the polygons
const vec4 low_dark  = vec4(76.0/255.0, 143.0/255.0, 130.0/255.0, 1.0);   // #4c8f82
const vec4 low_mid   = vec4(120.0/255.0, 179.0/255.0, 146.0/255.0, 1.0);  // #78b392
const vec4 low_light = vec4(120.0/255.0, 179.0/255.0, 146.0/255.0, 1.0);  // #78b392

// Raised ground (DARK), everywhere outside the polygons
const vec4 high_dark  = vec4(53.0/255.0, 121.0/255.0, 133.0/255.0, 1.0);  // #357985
const vec4 high_mid   = vec4(76.0/255.0, 143.0/255.0, 130.0/255.0, 1.0);  // #4c8f82
const vec4 high_light = vec4(76.0/255.0, 143.0/255.0, 130.0/255.0, 1.0);  // #4c8f82

const vec4 rim_color     = vec4(181.0/255.0, 224.0/255.0, 186.0/255.0, 1.0); // #b5e0ba
const vec4 outline_color = vec4(36.0/255.0, 43.0/255.0, 74.0/255.0, 1.0);    // #242b4a

// Details
const vec4 fleck_color = vec4(181.0/255.0, 224.0/255.0, 186.0/255.0, 1.0);   // #b5e0ba
const float fleck_density = 0.0125;

// Cliff
const vec4 cliff_top = vec4(156.0/255.0, 79.0/255.0, 65.0/255.0, 1.0);    // #9c4f41
const vec4 cliff_mid = vec4(102.0/255.0, 51.0/255.0, 61.0/255.0, 1.0);    // #66333d
const vec4 cliff_low = vec4(102.0/255.0, 51.0/255.0, 61.0/255.0, 1.0);    // #66333d
const int cliff_height = 8;              // art pixels (max 16)

// Shadow
const vec2 shadow_offset = vec2(2.0, 2.0);
const vec4 shadow_color = vec4(76.0/255.0, 143.0/255.0, 130.0/255.0, 1.0); // #4c8f82

// Noise
const float noise_scale = 0.09;
const float dark_threshold = 0.38;
const float light_threshold = 0.64;
const float dither_band = 0.06;
const float noise_seed = 0.0;

varying vec2 world_pos;

void vertex() {
	world_pos = VERTEX;
}

float hash(vec2 p) {
	p += noise_seed;
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float n = value_noise(p) * 0.6;
	n += value_noise(p * 2.1 + 17.0) * 0.4;
	return n;
}

// Even-odd point-in-polygon test for ONE polygon (with a cheap bounding box reject first)
bool inside_poly(int k, vec2 w) {
	if (w.x < bounds_min[k].x || w.x > bounds_max[k].x ||
		w.y < bounds_min[k].y || w.y > bounds_max[k].y) {
		return false;
	}
	int start = int(poly_range[k].x);
	int n = int(poly_range[k].y);
	bool c = false;
	int j = start + n - 1;
	for (int i = 0; i < 256; i++) {
		if (i >= n) {
			break;
		}
		vec2 a = points[start + i];
		vec2 b = points[j];
		if ((a.y > w.y) != (b.y > w.y)) {
			if (w.x < (b.x - a.x) * (w.y - a.y) / (b.y - a.y) + a.x) {
				c = !c;
			}
		}
		j = start + i;
	}
	return c;
}

// Union of all polygons: inside ANY of them counts as low ground
bool inside_any(vec2 w) {
	for (int k = 0; k < 16; k++) {
		if (k >= poly_count) {
			break;
		}
		if (inside_poly(k, w)) {
			return true;
		}
	}
	return false;
}

// 1.0 if the art pixel p is RAISED ground, i.e. outside every polygon
float is_high(vec2 p) {
	return inside_any((p + 0.5) * pixel_size) ? 0.0 : 1.0;
}

vec4 grass(vec2 p, vec4 dark, vec4 mid, vec4 light) {
	float n = fbm(p * noise_scale);
	bool checker = mod(p.x + p.y, 2.0) < 1.0;
	vec4 c = mid;

	if (n < dark_threshold - dither_band) {
		c = dark;
	} else if (n < dark_threshold + dither_band) {
		c = checker ? dark : mid;
	} else if (n > light_threshold + dither_band) {
		c = light;
	} else if (n > light_threshold - dither_band) {
		c = checker ? light : mid;
	}

	if (hash(p * 1.3) < fleck_density) {
		c = fleck_color;
	}
	return c;
}

void fragment() {
	vec2 w = world_pos;
	vec2 p = floor(w / pixel_size);

	// Fast path: pixels far from every polygon are plain raised grass
	float pad = (float(cliff_height) + max(shadow_offset.x, shadow_offset.y) + 3.0) * pixel_size;
	bool close_to_poly = false;
	for (int k = 0; k < 16; k++) {
		if (k >= poly_count) {
			break;
		}
		if (w.x > bounds_min[k].x - pad && w.x < bounds_max[k].x + pad &&
			w.y > bounds_min[k].y - pad && w.y < bounds_max[k].y + pad) {
			close_to_poly = true;
			break;
		}
	}

	vec4 col;

	if (!close_to_poly) {
		col = grass(p, high_dark, high_mid, high_light);
	} else if (is_high(p) > 0.5) {
		// Raised ground
		col = grass(p, high_dark, high_mid, high_light);

		float up    = is_high(p + vec2(0.0, -1.0));
		float down  = is_high(p + vec2(0.0,  1.0));
		float left  = is_high(p + vec2(-1.0, 0.0));
		float right = is_high(p + vec2( 1.0, 0.0));

		if (up < 0.5) {
			col = rim_color;                       // lit edge
		} else if (left < 0.5 || right < 0.5 || down < 0.5) {
			col = outline_color;                   // dark outline
		}
	} else {
		// Low ground, inside the merged polygon shape
		col = grass(p, low_dark, low_mid, low_light);

		int cliff_depth = 0;
		for (int i = 1; i <= 16; i++) {
			if (i > cliff_height) {
				break;
			}
			if (is_high(p - vec2(0.0, float(i))) > 0.5) {
				cliff_depth = i;
				break;
			}
		}

		if (cliff_depth > 0) {
			bool checker = mod(p.x + p.y, 2.0) < 1.0;
			if (cliff_depth == cliff_height) {
				col = outline_color;               // bottom outline
			} else if (cliff_depth == 1) {
				col = cliff_top;                   // light top row
			} else if (cliff_depth == cliff_height - 1) {
				col = cliff_low;                   // darkest row above outline
			} else {
				col = checker ? cliff_mid : cliff_top;   // dithered middle
			}
		} else {
			vec2 sp = p - vec2(0.0, float(cliff_height)) - shadow_offset;
			if (is_high(sp) > 0.5 && mod(p.x + p.y, 2.0) < 1.0) {
				col = shadow_color;
			}
		}
	}

	COLOR = vec4(col.rgb, 1.0);
}