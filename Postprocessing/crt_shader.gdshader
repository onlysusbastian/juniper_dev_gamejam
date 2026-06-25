shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

// =======================================================
// ADJUST THESE VALUES
// =======================================================

// CRT Screen Curvature
uniform float curve_strength : hint_range(0.0,1.0) = 0.2;

// RGB Separation
uniform float rgb_offset : hint_range(0.0,0.003) = 0.001;

// Screen Wobble
uniform float wobble_strength : hint_range(0.0,0.002) = 0.003;

// Scanlines
uniform float scanline_strength : hint_range(0.0,1.0) = 0.17;

// Vignette
uniform float vignette_strength : hint_range(0.0,1.0) = 0.4;

// Shadow Mask
uniform float shadowmask_strength : hint_range(0.0,1.0) = 0.70;

// Flicker
uniform float flicker_strength : hint_range(0.0,0.05) = 0.01;


// =======================================================

vec2 curve(vec2 uv)
{
    uv = (uv - 0.5) * 2.0;

    // Much gentler CRT curve
    float amount = 0.08 * curve_strength;

    uv.x *= 1.0 + amount * uv.y * uv.y;
    uv.y *= 1.0 + amount * uv.x * uv.x;

    uv = uv * 0.5 + 0.5;

    return uv;
}

void fragment()
{
    vec2 resolution = 1.0 / SCREEN_PIXEL_SIZE;

    vec2 uv = curve(SCREEN_UV);

    // ---------------------------------------------------
    // Screen wobble
    // ---------------------------------------------------

    float wobble =
        sin(0.3*TIME + uv.y*21.0) *
        sin(0.7*TIME + uv.y*29.0) *
        sin(0.3 + 0.33*TIME + uv.y*31.0) *
        wobble_strength;

    // ---------------------------------------------------
    // RGB Separation
    // ---------------------------------------------------

    vec3 col;

    col.r = texture(
        screen_texture,
        vec2(uv.x + wobble + rgb_offset, uv.y)
    ).r;

    col.g = texture(
        screen_texture,
        vec2(uv.x + wobble, uv.y)
    ).g;

    col.b = texture(
        screen_texture,
        vec2(uv.x + wobble - rgb_offset, uv.y)
    ).b;

    // Outside curved screen

    // Clamp instead of producing hard black wedges
	uv = clamp(uv, vec2(0.0), vec2(1.0));

    // ---------------------------------------------------
    // Vignette
    // ---------------------------------------------------

    float vig =
        16.0 *
        uv.x *
        uv.y *
        (1.0-uv.x) *
        (1.0-uv.y);

    col *= mix(
        vec3(1.0),
        vec3(pow(vig,0.3)),
        vignette_strength
    );

    // ---------------------------------------------------
    // Scanlines
    // ---------------------------------------------------

    float scans =
        clamp(
            0.35 +
            scanline_strength *
            sin(
                3.5 * TIME +
                uv.y * resolution.y * 1.5
            ),
            0.0,
            1.0
        );

    float s = pow(scans,1.7);

    col *= vec3(
        0.85 +
        scanline_strength * s
    );

    // ---------------------------------------------------
    // Flicker
    // ---------------------------------------------------

    col *=
        1.0 +
        flicker_strength *
        sin(110.0 * TIME);

    // ---------------------------------------------------
    // Shadow Mask
    // ---------------------------------------------------

    col *=
        1.0 -
        shadowmask_strength *
        vec3(
            clamp(
                (mod(FRAGCOORD.x,2.0)-1.0)*2.0,
                0.0,
                1.0
            )
        );

    COLOR = vec4(col,1.0);
}