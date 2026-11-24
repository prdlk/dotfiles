// Gloss over Ghostty's frosted-glass background (background-opacity +
// Hyprland blur): a faint specular sheen from the top-left corner and a thin
// rim highlight along the window edge. Static, so the config sets
// custom-shader-animation = false.
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 termColor = texture(iChannel0, uv);

    // Diagonal sheen, strongest at the top-left (Shadertoy coords: y up).
    float diagonal = (1.0 - uv.x) * 0.45 + uv.y * 0.55;
    float sheen = smoothstep(0.55, 1.0, diagonal) * 0.045;

    // Two-pixel inner rim highlight.
    vec2 edge = min(uv, 1.0 - uv) * iResolution.xy;
    float borderDist = min(edge.x, edge.y);
    float rim = (1.0 - smoothstep(0.0, 2.0, borderDist)) * 0.08;

    // Scaled by alpha: the texture is premultiplied, so this keeps the
    // highlight proportional to the glass rather than painting opaque white.
    vec3 highlight = vec3(0.92, 0.96, 1.0) * (sheen + rim);
    fragColor = vec4(termColor.rgb + highlight * termColor.a, termColor.a);
}
