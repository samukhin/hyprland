#version 100

precision highp float;

varying vec2 v_texcoord;
uniform sampler2D tex;

void main() {
    vec4 pixColor = texture2D(tex, v_texcoord);
    vec2 pixelCoord = gl_FragCoord.xy;

    const float top = 100.0;
    
    // Умножитель скорости. 2.0 означает, что градиент будет в 2 раза короче.
    const float TRANSITION_MULTIPLIER = 2.0;

    if (pixelCoord.y <= top) {
        float mixFactor = ((top - pixelCoord.y) / top) * TRANSITION_MULTIPLIER;
        
        // Ограничиваем значение, чтобы оно не превышало 1.0
        mixFactor = clamp(mixFactor, 0.0, 1.0);

        float average = (pixColor.r + pixColor.g + pixColor.b) / 3.0;
        vec3 gray2 = vec3(average);

        gl_FragColor = vec4(
            vec3(mix(pixColor.rgb, gray2, mixFactor)),
            pixColor.a);
    } else {
        gl_FragColor = pixColor;
    }
}
