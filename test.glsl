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

    if (sphere > 0.0) {
        vec3 col = vec3(0.1);
        // col = mix(col, vec3(1.0, 1.0, 0.0), pathL);
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

// float sdCircle(vec2 p, float r) {
//     return length(p) - r;
// }

// float sdTracePath(vec2 p) {
//     const int N = 512;
//     float d = 1e10;
//     for (int i = 0; i < N; ++i) {
//         float t = 6.283185 * float(i) / float(N);
//         vec2 base = vec2(cos(t), sin(t)) * 0.75;
//         vec2 offset = vec2(base.x * 0.5 + 0.5 * sin(t),
//                            base.y * 0.5 + 0.5 * sin(t));
//         vec2 c = base - offset;
//         d = min(d, length(p - c));
//     }
//     return d;
// }

// void mainImage(out vec4 fragColor, in vec2 fragCoord)
// {
//     vec2 uv = fragCoord / iResolution.xy;
//     uv = uv * 2.0 - 1.0;

//     // --------------------------------------------------
//     // 1. YELLOW – Original circular path
//     // --------------------------------------------------
//     vec2 pathCenter = vec2(0.0, 0.0);
//     float pathRadius = 0.75;
//     float pathD = sdCircle(uv - pathCenter, pathRadius);
//     float pathL = smoothstep(0.02, 0.015, abs(pathD));

//     // --------------------------------------------------
//     // 2. SPHERE – Moving centre with wobble
//     // --------------------------------------------------
//     float angle = iTime;
//     vec2 base = pathCenter + vec2(cos(angle), sin(angle)) * pathRadius;
//     vec2 offset = vec2(base.x * 0.5 + 0.5 * sin(iTime),
//                        base.y * 0.5 + 0.5 * sin(iTime));
//     vec2 center = base - offset;

//     // --------------------------------------------------
//     // 3. RADIUS BASED ON base.y (vertical position)
//     // --------------------------------------------------
//     // base.y ranges from -0.75 to +0.75
//     // We map: bottom → small, top → large
//     float minRadius = 0.15;
//     float maxRadius = 0.35;
//     float t = (base.y + pathRadius) / (2.0 * pathRadius);  // 0 to 1
//     float radius = mix(minRadius, maxRadius, t);          // smooth blend

//     // --------------------------------------------------
//     // 4. Sphere SDF with dynamic radius
//     // --------------------------------------------------
//     float sphere = sdCircle(uv - center, radius);

//     // --------------------------------------------------
//     // 5. If outside sphere → draw background + paths
//     // --------------------------------------------------
//     if (sphere > 0.0) {
//         vec3 col = vec3(0.1);
//         col = mix(col, vec3(1.0, 1.0, 0.0), pathL);
//         float traceD = sdTracePath(uv);
//         float traceL = smoothstep(0.025, 0.015, abs(traceD));
//         col = mix(col, vec3(1.0, 0.5, 0.0), traceL);
//         fragColor = vec4(col, 1.0);
//         return;
//     }

//     // --------------------------------------------------
//     // 6. 3D LIGHTING
//     // --------------------------------------------------
//     vec2 lightPoint = pathCenter + vec2(cos(iTime), sin(iTime)) * 1.2;
//     vec2 lightVec = lightPoint - uv;
//     float lightDist = length(lightVec);
//     vec2 n2D = (uv - center) / radius;
//     vec3 normal = vec3(n2D, 0.0);
//     vec3 lightDir = normalize(vec3(lightVec, 1.0));
//     float diff = max(dot(normal.xy, lightDir.xy), 0.08);
//     float atten = 1.0 / (1.0 + 0.5 * lightDist * lightDist);
//     vec3 viewDir = vec3(0.0, 0.0, 1.0);
//     vec3 reflectDir = reflect(-lightDir, normal);
//     float spec = pow(max(dot(viewDir, reflectDir), 0.0), 10.0);

//     // --------------------------------------------------
//     // 7. Final color
//     // --------------------------------------------------
//     float i = sin(iTime);
//     vec3 baseCol = vec3(0.0, 0.0, i + 0.5);  // blue pulse
//     vec3 col = baseCol * (0.3 + 0.7 * diff * atten) + vec3(1.0) * spec;

//     fragColor = vec4(col, 1.0);
// }