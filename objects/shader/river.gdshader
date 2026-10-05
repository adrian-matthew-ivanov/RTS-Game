shader_type canvas_item;
render_mode world_vertex_coords;

uniform float pixel_size = 1.0; 

uniform vec4 water_dark : source_color = vec4(0.09, 0.27, 0.63, 1.0);
uniform vec4 water_light : source_color = vec4(0.18, 0.49, 0.82, 1.0);
uniform vec4 outline_color : source_color = vec4(0.05, 0.1, 0.25, 1.0);
uniform vec4 foam_color : source_color = vec4(0.85, 0.93, 0.98, 1.0);

uniform float edge_foam_thickness = 4.0; 
uniform float edge_foam_scale = 0.2;     
uniform float edge_foam_speed = 3.0;     

uniform vec2 flow_direction = vec2(1.0, 0.5);
uniform float wave_speed = 1.5;
uniform float wave_scale = 0.05;
uniform float wave_dark_threshold = 0.3;
uniform float wave_foam_threshold = 0.85;

// Hardcoded array size for maximum compatibility across Godot 4 drivers
uniform vec4 river_segments[256]; 
uniform float river_widths[256];  
uniform int segment_count = 0;             

float get_bubble_noise(vec2 p, float time) {
    vec2 scaled_p = p * edge_foam_scale;
    float n = sin(scaled_p.x + time) * cos(scaled_p.y - time);
    n += sin(scaled_p.x - scaled_p.y + time * 1.5);
    return (n + 2.0) / 4.0; 
}

float get_wave_noise(vec2 p, float time) {
    vec2 scaled_p = p * wave_scale;
    vec2 flow = normalize(flow_direction) * time;
    scaled_p -= flow; 
    
    float n = sin(scaled_p.x) * cos(scaled_p.y + time * 0.5);
    n += sin(scaled_p.x * 1.5 - scaled_p.y * 1.2 + time * 0.8) * 0.5;
    return (n + 1.5) / 3.0;
}

float dist_to_segment(vec2 p, vec2 a, vec2 b) {
    vec2 ab = b - a;
    float ab_len2 = dot(ab, ab);
    float t = ab_len2 > 0.0001 ? clamp(dot(p - a, ab) / ab_len2, 0.0, 1.0) : 0.0;
    vec2 proj = a + ab * t;
    return length(p - proj);
}

// Returns a Signed Distance: < 0 is INSIDE the river, > 0 is OUTSIDE
float get_edge_dist(vec2 world_p) {
    float min_dist_to_edge = 1e20;
    
    for (int i = 0; i < 256; i++) {
        if (i >= segment_count) {
            break;
        }
        
        // Only evaluate valid rivers with positive width
        if (river_widths[i] > 0.0) {
            float d = dist_to_segment(world_p, river_segments[i].xy, river_segments[i].zw);
            float edge_d = d - (river_widths[i] * 0.5);
            min_dist_to_edge = min(min_dist_to_edge, edge_d);
        }
    }
    return min_dist_to_edge;
}

varying vec2 world_pos;

void vertex() {
    world_pos = VERTEX;
}

void fragment() {
    vec2 pixel_coord = floor(world_pos / pixel_size);
    vec2 center_world = (pixel_coord + vec2(0.5)) * pixel_size;

    float center_edge_dist = get_edge_dist(center_world);
    
    if (center_edge_dist > 0.0) {
        discard;
    }

    vec2 offsets[4] = vec2[](
        vec2(-1.0, 0.0),
        vec2(1.0, 0.0),
        vec2(0.0, -1.0),
        vec2(0.0, 1.0)
    );

    bool is_outline = false;
    for (int i = 0; i < 4; i++) {
        vec2 neighbor_world = center_world + offsets[i] * pixel_size;
        if (get_edge_dist(neighbor_world) > 0.0) {
            is_outline = true;
            break;
        }
    }

    if (is_outline) {
        COLOR = outline_color;
    } else {
        float w_noise = get_wave_noise(pixel_coord, TIME * wave_speed);
        vec4 base_color = water_light;
        
        if (w_noise < wave_dark_threshold) {
            base_color = water_dark;
        } else if (w_noise > wave_foam_threshold) {
            base_color = foam_color;
        }
        
        float dist_from_edge = -center_edge_dist; 
        
        if (dist_from_edge <= edge_foam_thickness) {
            float edge_factor = 1.0 - (dist_from_edge / edge_foam_thickness);
            float e_noise = get_bubble_noise(pixel_coord, TIME * edge_foam_speed);
            
            if (e_noise < edge_factor) {
                base_color = foam_color;
            }
        }
        
        COLOR = base_color;
    }
}