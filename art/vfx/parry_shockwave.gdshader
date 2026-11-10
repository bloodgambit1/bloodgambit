shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;

uniform vec4 ring_color : source_color = vec4(1.0, 0.75, 0.25, 1.0);
uniform float ring_width : hint_range(0.01, 0.5) = 0.08;
uniform float intensity : hint_range(0.0, 10.0) = 4.0;
uniform float progress : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec2 uv = UV * 2.0 - 1.0;
    float dist = length(uv);
    
    // An expanding circular rim: ring expands as progress goes 0 -> 1
    float radius = mix(0.1, 0.95, progress);
    float ring = 1.0 - smoothstep(0.0, ring_width, abs(dist - radius));
    
    // Fade out as it expands outward
    float fade = 1.0 - pow(progress, 1.5);
    
    ALBEDO = ring_color.rgb * intensity;
    ALPHA = ring * fade * ring_color.a;
}
