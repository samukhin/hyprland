#version 100

precision highp float;

// --- ВХОДНЫЕ ДАННЫЕ ---
varying vec2 v_texcoord; 
uniform sampler2D tex;

// РАЗРЕШЕНИЕ УКАЗАНО ВРУЧНУЮ КАК КОНСТАНТА
const vec2 iResolution = vec2(1440.0, 900.0);


void main() {
    // --- 1. НАСТРОЙКА ---
    float blockSize = 2.0;
    float gridBrightness = 0.0;
    float compensationStrength = 1.0;

    // --- 2. ПИКСЕЛИЗАЦИЯ (вычисление UV для блока) ---
    vec2 pix = gl_FragCoord.xy;
    vec2 block_uv = floor(pix / blockSize) * blockSize / iResolution;
    
    vec3 original_col = texture2D(tex, block_uv).rgb;

    // --- 3. СОЗДАНИЕ СЕТКИ ---
    vec2 gridCoord = mod(pix, blockSize);
    float gridMask = step(1.0, gridCoord.x) * step(1.0, gridCoord.y);

    // --- 4. КОМПЕНСАЦИЯ ЯРКОСТИ ---
    vec3 grid_color = original_col * gridBrightness;
    
    vec3 image_color = original_col;
    if (blockSize > 1.0) {
        float totalArea = blockSize * blockSize;
        float colorArea = (blockSize - 1.0) * (blockSize - 1.0);
        float theoreticalFactor = totalArea / colorArea;
        float boost = mix(1.0, theoreticalFactor, compensationStrength);
        image_color *= boost;
    }
    
    // --- 5. СМЕШИВАНИЕ ---
    vec3 finalColor = mix(grid_color, image_color, gridMask);

    // --- 6. ВЫВОД РЕЗУЛЬТАТА ---
    gl_FragColor = vec4(clamp(finalColor, 0.0, 1.0), 1.0);
}
