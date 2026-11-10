shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;
uniform vec4 tint : source_color = vec4(1.0, 0.12, 0.035, 1.0);
uniform float strength = 1.0;
void fragment() {
    float edge = smoothstep(0.0, 0.18, UV.y) * (1.0 - smoothstep(0.84, 1.0, UV.y));
    float tip = pow(max(sin(UV.x * 3.14159265), 0.0), 0.45);
    vec3 hot = mix(tint.rgb, vec3(1.0, 0.82, 0.42), pow(UV.y, 3.0));
    ALBEDO = hot * 1.6;
    ALPHA = edge * tip * strength;
}
