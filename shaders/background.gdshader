shader_type canvas_item;

uniform float brightness : hint_range(0.5, 2.0) = 1.0;
uniform vec4 overlay_color : source_color = vec4(0.0, 0.0, 0.0, 0.3);
uniform float fade_alpha : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    // Obtener color base de la textura
    vec4 base_color = texture(TEXTURE, UV);
    
    // Aplicar brillo
    base_color.rgb *= brightness;
    
    // Aplicar fade alpha
    base_color.a *= fade_alpha;
    
    // Mezclar con color overlay
    COLOR = mix(base_color, overlay_color, overlay_color.a);
}
