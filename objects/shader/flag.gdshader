shader_type canvas_item;

uniform vec4 tint_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float tolerance : hint_range(0.0, 0.5) = 0.05;
uniform float tint_strength : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    float rg_diff = abs(tex_color.r - tex_color.g);
    float rb_diff = abs(tex_color.r - tex_color.b);
    float gb_diff = abs(tex_color.g - tex_color.b);
    
    if (rg_diff < tolerance && rb_diff < tolerance && gb_diff < tolerance) {
        vec3 blended_color = mix(tex_color.rgb, tint_color.rgb * tex_color.rgb, tint_strength);
        COLOR = vec4(blended_color, tex_color.a);
    } else {
        COLOR = tex_color;
    }
}
