uniform int dotCount;
uniform vec2 dots[1014];
uniform float radius;
uniform float smoothFactor;
uniform vec3 viewDir;  // Direction from the surface point to the camera, normalized

float smoothMin(float d1, float d2, float k) {
    float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
    return mix(d2, d1, h) - k * h * (1.0 - h);
}

vec4 sdf(vec2 point) {
    float minDist = 10000.0; // Large number to start with
    vec3 color = vec3(1.0); // Default color (background color)

    for (int i = 0; i < dotCount; i++) {
        float dist = length(point - dots[i]) - radius;
        minDist = smoothMin(minDist, dist, smoothFactor);
    }

    return vec4(color, minDist);
}

vec3 calculateNormal(vec2 point) {
    float eps = 0.01; // Small offset for numerical gradient calculation
    float distX1 = sdf(point + vec2(eps, 0.0)).w;
    float distX2 = sdf(point - vec2(eps, 0.0)).w;
    float distY1 = sdf(point + vec2(0.0, eps)).w;
    float distY2 = sdf(point - vec2(0.0, eps)).w;

    vec2 gradient = vec2(distX1 - distX2, distY1 - distY2);
    return normalize(vec3(gradient, 2.0 * eps));
}

vec3 sky(vec3 direction) {
    vec3 horizonColor = vec3(1.0, 0.8, 0.5); // Orange for the horizon
    vec3 midSkyColor1 = vec3(0.7, 0.7, 0.7); // Light blue for the mid sky
    vec3 midSkyColor2 = vec3(0.2, 0.6, 1.0); // Light blue for the mid sky
    vec3 topSkyColor = vec3(0.1, 0.1, 0.7); // Dark blue for the top sky
    vec3 sunColor = vec3(1.0, 0.9, 0.7); // Yellowish color for the sun

    // Fixed sun angles (in degrees)
    vec3 sunAngles = vec3(45.0, -60.0, 0.0); // yaw, pitch, roll

    // Convert sun angles from degrees to radians
    float sunYaw = radians(sunAngles.x); // Horizontal angle
    float sunPitch = radians(sunAngles.y); // Vertical angle

    // Convert sun angles to a direction vector
    vec3 sunDirection = normalize(vec3(
        cos(sunPitch) * cos(sunYaw),
        sin(sunPitch),
        cos(sunPitch) * sin(sunYaw)
    ));

    float t = clamp((-direction.y + 1.0) / 2.0, 0.0, 1.0);
    vec3 skyColor;

    if (t < 0.47) {
        // Blend from horizon to mid sky with a smoother transition
        skyColor = mix(horizonColor, midSkyColor1, smoothstep(0.0, 0.47, t));
    } else if (t < 0.53) {
        // Blend from mid sky1 to mid sky2 for a smoother middle transition
        skyColor = mix(midSkyColor1, midSkyColor2, smoothstep(0.47, 0.53, t));
    } else {
        // Blend from mid sky2 to top sky with a smoother transition
        skyColor = mix(midSkyColor2, topSkyColor, smoothstep(0.53, 1.0, t));
    }
    
    // Calculate sun influence based on dot product
    float sunInfluence = exp(-pow(acos(dot(direction, sunDirection)) * 12.5, 8.0));
    skyColor = mix(skyColor, sunColor, sunInfluence);

    return skyColor;
}

vec4 effect(vec4 color, Image texture, vec2 uv, vec2 screenCoords) {
    vec4 result = sdf(screenCoords);  
    if (result.w < 0.0) {
        vec3 normal = calculateNormal(screenCoords);

        // Calculate reflection direction
        vec3 reflectionDir = reflect(-viewDir, normal);

        // Get sky color based on reflection direction
        vec3 reflectionColor = sky(reflectionDir);

        // Might use later
        float smoothEdge = smoothstep(-radius, radius, result.w);

        // Create a watercolor-like color
        vec3 watercolor = vec3(0.4, 0.4, 0.8); // Light blueish-green

        // Blend reflection color with watercolor effect
        vec3 finalColor = mix(reflectionColor, watercolor, 0.9);
        if (result.w > -1) {
            return vec4(finalColor * 3, 1);
        } else {
            return vec4(finalColor, 1); // Semi-transparent effect
        };
    }
    return vec4(vec3(0.0), 1.0);
}
