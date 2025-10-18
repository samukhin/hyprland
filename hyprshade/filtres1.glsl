#version 100
precision mediump float;

// --- ВХОДНЫЕ ДАННЫЕ ---
uniform sampler2D tex;
uniform float iTime; // Не используется, но оставляю для совместимости

const highp vec2 iResolution = vec2(1440.0, 900.0);
const highp vec2 iResolutionInv = vec2(1.0/1440.0, 1.0/900.0); // Инверсия для производительности


// --- НАСТРОЙКИ ШЕЙДЕРА ---

// 1. Сглаживание (FXAA)
// Сила сглаживания. 0.0 - выкл. 1.0 - стандарт. Больше - сильнее.
const float FXAA_STRENGTH = 1.0; 

// 2. Адаптивная резкость (CAS)
// Сила повышения резкости. 0.0 - выкл. 0.5 - умеренно. 1.0 - сильно.
const float SHARPEN_STRENGTH = 0.5;


// Функция для вычисления яркости (Luminance)
float getLuma(vec3 rgb) {
    return dot(rgb, vec3(0.299, 0.587, 0.114));
}


void main()
{
    // ==================================================================
    // ==                       ЭТАП 1: FXAA                           ==
    // ==================================================================

    highp vec2 uv = gl_FragCoord.xy * iResolutionInv;
    
    // Шаг в один пиксель
    highp vec2 step_size = iResolutionInv;

    // --- 1. Сэмплируем яркость окружающих пикселей ---
    float luma_center = getLuma(texture2D(tex, uv).rgb);
    float luma_down = getLuma(texture2D(tex, uv - vec2(0.0, step_size.y)).rgb);
    float luma_up = getLuma(texture2D(tex, uv + vec2(0.0, step_size.y)).rgb);
    float luma_left = getLuma(texture2D(tex, uv - vec2(step_size.x, 0.0)).rgb);
    float luma_right = getLuma(texture2D(tex, uv + vec2(step_size.x, 0.0)).rgb);

    // --- 2. Находим локальный контраст и направление градиента ---
    float luma_min = min(luma_center, min(min(luma_down, luma_up), min(luma_left, luma_right)));
    float luma_max = max(luma_center, max(max(luma_down, luma_up), max(luma_left, luma_right)));
    
    // Если контраст слишком мал, сглаживание не нужно
    float contrast = luma_max - luma_min;

    vec3 final_color_aa;
    
    // Порог, ниже которого FXAA не применяется
    if (contrast < 0.0312) {
        final_color_aa = texture2D(tex, uv).rgb;
    } else {
        // --- 3. Вычисляем направление и применяем сглаживание ---
        highp vec2 grad;
        grad.x = -luma_left + luma_right;
        grad.y = -luma_down + luma_up;

        // Направление, перпендикулярное градиенту (вдоль "лесенки")
        highp vec2 grad_inv = vec2(grad.y, -grad.x);
        
        // Нормализуем и умножаем на шаг пикселя
        highp vec2 dir = normalize(grad_inv) * step_size;

        // Сэмплируем две точки вдоль "лесенки" и усредняем
        vec3 color1 = texture2D(tex, uv + dir * 0.5).rgb;
        vec3 color2 = texture2D(tex, uv - dir * 0.5).rgb;
        vec3 blended_color = (color1 + color2) * 0.5;

        // Смешиваем исходный цвет и сглаженный в зависимости от силы FXAA
        final_color_aa = mix(texture2D(tex, uv).rgb, blended_color, FXAA_STRENGTH);
    }


    // ==================================================================
    // ==         ЭТАП 2: Адаптивная резкость (CAS)                    ==
    // ==================================================================
    
    // Если резкость отключена, сразу выводим результат
    if (SHARPEN_STRENGTH <= 0.0) {
        gl_FragColor = vec4(final_color_aa, 1.0);
        return;
    }

    // --- 1. Сэмплируем 4 соседних пикселя из уже сглаженного изображения ---
    // (для этого мы не можем использовать текстуру, поэтому делаем это вручную)
    vec3 c1 = texture2D(tex, uv + vec2(0.0, -step_size.y)).rgb;
    vec3 c2 = texture2D(tex, uv + vec2(-step_size.x, 0.0)).rgb;
    vec3 c3 = texture2D(tex, uv + vec2(step_size.x, 0.0)).rgb;
    vec3 c4 = texture2D(tex, uv + vec2(0.0, step_size.y)).rgb;

    // --- 2. Находим самый темный и самый светлый из соседей ---
    vec3 min_c = min(c1, min(c2, min(c3, c4)));
    vec3 max_c = max(c1, max(c2, max(c3, c4)));

    // --- 3. Вычисляем адаптивный коэффициент резкости ---
    // Чем больше разница между min/max, тем меньше будет резкость (чтобы не шарпить края)
    float sharpness_w = 1.0 / (max(max_c.r, max(max_c.g, max_c.b)) - min(min_c.r, min(min_c.g, min_c.b)) + 0.0001);
    sharpness_w = clamp(sharpness_w, 0.0, 1.0); // Ограничиваем от 0 до 1

    // --- 4. Применяем резкость ---
    // Формула CAS: смешиваем исходный цвет с усредненным цветом соседей
    vec3 sharpened_color = (c1 + c2 + c3 + c4) * 0.25;
    
    // Смешиваем результат сглаживания (final_color_aa) с "замыленным" цветом соседей.
    // Коэффициент смешивания зависит от силы и адаптивного веса.
    vec3 final_color = mix(final_color_aa, sharpened_color, -SHARPEN_STRENGTH * sharpness_w);

    gl_FragColor = vec4(clamp(final_color, 0.0, 1.0), 1.0);
}
