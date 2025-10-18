#version 300 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

void main() {
    vec4 pixColor = texture(tex, v_texcoord);
    vec2 pixelCoord = gl_FragCoord.xy;

    //Выше базовые переменные, ниже логика
    //vec3 gray = vec3(dot(vec3(0.2126,0.7152,0.0722),pixColor.rgb)); //Оттенок серого через вычисления
    const float top = 100.0; //Отступ сверху, который нужно сделать серым
    float average = (pixColor.r + pixColor.g + pixColor.b)/3.0; //Оттенок серого через простое вычисление
    vec3 gray2 = vec3(average); //Формируем вектор для этого оттенка  vec3(average,average,average)

    //Если выше этого значения
    if (pixelCoord.y <= top) {
    //То смешиваем пропорционально
    fragColor = vec4(
    vec3(mix(pixColor.rgb,gray2,(top-pixelCoord.y)/top)),
    pixColor.a);
    } else {
    //Если нет, остаёмся со старым цветом
    //fragColor = vec4(pixColor.r,pixColor.g,pixColor.b, pixColor.a);
    }
  
}
