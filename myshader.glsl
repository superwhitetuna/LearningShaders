float sdCircle(vec2 p, float r)
{
    return length(p) - r;
}
float random(vec2 st)
{
    return (fract(sin(dot(st, vec2(12.9898, 78.233))) * 43758.5453123));
}
float noise(vec2 st)
{
    vec2 i = floor(st);
    vec2 f = fract(st);
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a,b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}
vec3 palette(float t)
{
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.259, 0.416, 0.557);
    return c * cos(6.28318 * (a + b + c * t + d));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    uv = uv * 2.0 - 1.0;
    
    vec2 mainCenter = vec2(sin(iTime * 2.0), sin(iTime * 3.0));
    float mainRadius = sin(abs(1.0 + sin(iTime)));
    float mainCircle = sdCircle(uv - mainCenter, mainRadius);

    vec2 offset = vec2( -1.0, 1.5);
    vec2 smallCenter = mainCenter + offset;
    float smallRadius = mainRadius * 0.5;
    float d2 = sdCircle(uv - smallCenter, smallRadius);

    vec2 offset3 = vec2( 1.0, 1.5);
    vec2 small3Center = mainCenter + offset3;
    float d3 = sdCircle(uv - small3Center, smallRadius);

    vec2 offset4 = vec2(-1.0, -1.5);
    vec2 small4Center = mainCenter + offset4;
    float d4 = sdCircle(uv - small4Center, smallRadius);

    vec2 offset5 =  vec2(1.0, -1.5);
    vec2 small5Center = mainCenter + offset5;
    float d5 = sdCircle(uv - small5Center, smallRadius);

    vec2 small6Center = vec2(-sin(iTime * 2.0), -sin(iTime * 3.0));
    // float small6Radius = mainRadius * 0.3;
    float d6 = sdCircle(uv - small6Center, 0.3);


    float d = min(mainCircle, min(d2, min(d3, min(d4, d5))));
    
    float s = min(d6, d6);
       
    vec3 col;
    if (d < 0.0) {
        float t = iTime * 0.1;
        vec2 nebulaUV = uv * 2.0 + vec2(cos(t), sin(t));
        float nebula = noise(nebulaUV);
        vec3 nebulaColor = palette(nebula + iTime * 0.5);
        col = vec3(0.1) + vec3(nebulaColor) * 0.5;
    }
    else {
        col = vec3(0.7 - 0.3 + uv.y * uv.x * d * sin(cos(iTime)) * 2.0);
    }

    if (s < 0.0) {
        col = vec3(abs(sin(col))); 
    }
    else if (s > 0.0 && s < 0.1) {
        vec3 outcol = vec3(0.7 - 0.3 + uv.y * uv.x * d * sin(cos(iTime)) * 2.0, 0.2, 0.2);
        col = vec3(abs(sin(outcol)));
    }

    vec3 outcol = vec3(0.7 - 0.3 + uv.y * uv.x * d * sin(cos(iTime)) * 2.0);
    float edgeWidth = 10.0;
    float t = smoothstep(-edgeWidth, edgeWidth, d);
    col = mix(col, outcol, t);

    fragColor = vec4(col, 1.0); // Red (R=1, G=0, B=0, A=1 for opacity)
}
