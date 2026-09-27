shader_type canvas_item;
render_mode world_vertex_coords;

const int MAX_POINTS = 256;

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

uniform float river_width = 48.0;      
uniform vec2 path_points[MAX_POINTS];  
uniform int point_count = 0;           

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

float get_path_dist(vec2 world_p) {
    float min_dist = 1e20;
    for (int i = 0; i < point_count - 1; i++) {
        min_dist = min(min_dist, dist_to_segment(world_p, path_points[i], path_points[i + 1]));
    }
    return min_dist;
}

varying vec2 world_pos;

void vertex() {
    world_pos = VERTEX;
}

void fragment() {
    vec2 pixel_coord = floor(world_pos / pixel_size);
    vec2 center_world = (pixel_coord + vec2(0.5)) * pixel_size;

    float half_width = river_width * 0.5;

    float center_dist = get_path_dist(center_world);
    if (center_dist > half_width) {
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
        if (get_path_dist(neighbor_world) > half_width) {
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
        
        float dist_to_edge = half_width - center_dist;
        if (dist_to_edge <= edge_foam_thickness) {
            float edge_factor = 1.0 - (dist_to_edge / edge_foam_thickness);
            float e_noise = get_bubble_noise(pixel_coord, TIME * edge_foam_speed);
            
            if (e_noise < edge_factor) {
                base_color = foam_color;
            }
        }
        
        COLOR = base_color;
    }
}