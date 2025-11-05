float sdCircle(vec2 p, float r)
{
    return length(p) - r;
}
// PATH SAMPLER
float sdTracePath(vec2 p)
{
    const int N = 512;
    float d = 1e10;
    for (int i = 0; i < N; ++i) {
        float t = 6.283185 * float(i) / float(N);
        vec2 base = vec2(cos(t), sin(t)) * 0.75;
        vec2 offset = vec2(base.x * 0.5 + 0.5 * sin(t), base.y * 0.5 + 0.5 * sin(t));
        vec2 c = base - offset;
        d = min(d, length(p - c));
    }
    return d;
}

float stars(vec2 uv) {
    uv *= 10.0;  // density
    vec2 id = floor(uv);
    vec2 gv = fract(uv) - 0.5;
    
    float brightness = 0.0;
    for (int y = -1; y <= 1; ++y) {
        for (int x = -1; x <= 1; ++x) {
            vec2 offset = vec2(x, y);
            vec2 cell = id + offset;
            
            // Random star position & size
            float h = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
            vec2 starPos = offset + 0.5 + (vec2(h, fract(h * 7.3)) - 0.5) * 0.8;
            float starSize = fract(h * 13.7) * 0.03 + 0.01;
            
            float d = length(gv - starPos);
            float star = smoothstep(starSize, starSize * 0.5, d);
            
            // Twinkle
            float twinkle = sin(iTime * (h * 10.0) + h * 6.28) * 0.5 + 0.5;
            star *= twinkle * 0.7 + 0.3;
            
            brightness += star;
        }
    }
    return brightness;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;
    uv = uv * 2.0 - 1.0;


    // YELLOW - Source path
    vec2 pathCenter = vec2(0.0, 0.0);
    float pathRadius = 0.75;
    float pathD = sdCircle(uv - pathCenter, pathRadius);
    float pathL = smoothstep(0.02, 0.015, abs(pathD));
    
    // SPHERE
    float angle = iTime;
    vec2 base = pathCenter + vec2(cos(angle), sin(angle)) * pathRadius;
    vec2 offset = vec2(base.x * 0.5 + 0.5 * sin(iTime), base.y * 0.5 + 0.5 * sin(iTime));
    vec2 center = base - offset;
    float minR = 0.15;
    float maxR = 0.35;
    float t = (base.y + pathRadius) / (2.0 * pathRadius);
    float radius = mix(minR, maxR, t);
    float sphere = sdCircle(uv - center, radius);
    
    // SPHERE LIGHTING
    vec2 lightPoint = pathCenter + vec2(0.0, 1.0) * 1.2;
    vec2 lightVec = lightPoint - uv;
    float lightDist = length(lightVec - 0.5 * sin(iTime) + 0.5 * -sin(iTime));
    vec2 n2D = (uv - center) / radius;
    vec3 normal = vec3(n2D, 0.0);
    vec3 lightDir = normalize(vec3(lightVec, 1.0));
    float diff = max(dot(normal.xy, lightDir.xy), 0.08);
    float atten = 1.0 / (1.0 + 0.5 * lightDist * lightDist);
    vec3 viewDir = vec3(0.0, 0.0, 1.0);
    vec3 reflectDir = reflect(-lightDir, normal);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0),10.0);

    // ORANGE - Final path

    // vec2 base = pathCenter + vec2(cos(angle), sin(angle)) * pathRadius;
    // vec2 offset = vec2(base.x * 0.5 + 0.5 * sin(iTime), base.y * 0.5 + 0.5 * sin(iTime));
    // vec2 center = base - offset;
    float traceD = sdTracePath(uv);
    float traceL = smoothstep(0.025, 0.015, abs(traceD));

    vec3 bg = vec3(1.0) * stars(uv);

    if (sphere > 0.0) {
        vec3 col = bg;
        col = mix(col, vec3(1.0, 1.0, 0.0), pathL);
        col = mix(col, vec3(1.0, 0.5, 0.0), traceL);
        fragColor = vec4(col, 1.0);
        return;
    }

    // COLORS
    float i = abs(sin(iTime * 0.5)) * 0.5 + 0.8;
    vec3 baseCol = vec3(i, i, i);

    vec3 col = baseCol * (0.3 + 0.7 * diff * atten) + vec3(1.0) * spec;

    fragColor = vec4(col, 1.0);

}