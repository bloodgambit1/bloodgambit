shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;

uniform vec4 core_color : source_color = vec4(1.0, 0.95, 0.8, 1.0);
uniform vec4 glow_color : source_color = vec4(1.0, 0.6, 0.1, 1.0);
uniform float intensity : hint_range(0.0, 10.0) = 3.5;
uniform float rays : hint_range(4.0, 16.0) = 8.0;

void fragment() {
    vec2 uv = UV * 2.0 - 1.0;
    float dist = length(uv);
    if (dist > 1.0) {
        discard;
    }
    
    // Central radial glow
    float core = clamp(1.0 - dist * 2.0, 0.0, 1.0);
    core = pow(core, 2.0);
    
    // Star rays
    float angle = atan(uv.y, uv.x);
    float ray_pattern = abs(cos(angle * rays * 0.5));
    float star = pow(ray_pattern, 6.0) * clamp(1.0 - dist, 0.0, 1.0);
    
    // Cross rays along axes (horizontal & vertical bright flash)
    float cross_h = max(0.0, 1.0 - abs(uv.y) * 12.0) * max(0.0, 1.0 - abs(uv.x) * 1.2);
    float cross_v = max(0.0, 1.0 - abs(uv.x) * 12.0) * max(0.0, 1.0 - abs(uv.y) * 1.2);
    float cross_flare = (cross_h + cross_v) * 1.5;
    
    float total_intensity = core * 2.5 + star * 1.8 + cross_flare;
    vec3 col = mix(glow_color.rgb, core_color.rgb, clamp(total_intensity * 0.5, 0.0, 1.0)) * intensity;
    
    ALBEDO = col;
    ALPHA = clamp(total_intensity, 0.0, 1.0) * core_color.a;
}
