#define CONWAY_HEIGHT 30.1

uniform sampler2D colortex14;

const vec4 cylinderColor = vec4(1.0, 1.0, 1.0, 3.0);

vec4 GetConway(vec3 translucentMult, vec3 playerPos, float dist0, float dist1, float dither) {
    if (min(cameraPosition.y, playerPos.y + cameraPosition.y) > CONWAY_HEIGHT) {
        return vec4(0);
    }
    float slopeFactor0 = playerPos.y / length(playerPos.xz);

    float slopeFactor = sqrt(1 + slopeFactor0 * slopeFactor0);
    playerPos = vec3(0.25, 1.0, 0.25) * normalize(playerPos) * dist1;
    playerPos += 0.0002 * vec3(lessThan(abs(playerPos), vec3(0.0001)));
    float lPlayerPos = length(playerPos.xz);
    vec2 dir = playerPos.xz / lPlayerPos;
    vec3 start = vec3(fract(0.25 * cameraPosition.xz), cameraPosition.y).xzy;
    vec2 stepSize = 1.0 / abs(playerPos.xz);
    vec2 progress = (vec2(greaterThan(playerPos.xz, vec2(0))) - start.xz) / playerPos.xz - vec2(stepSize.x, 0);
    vec4 color = vec4(0);
    float startInVolume = start.y > CONWAY_HEIGHT ? max((CONWAY_HEIGHT - start.y) / playerPos.y, 0.0) : 0.0;
    float stopInVolume = start.y < CONWAY_HEIGHT ? (CONWAY_HEIGHT - start.y) / playerPos.y : 1.0;
    stopInVolume = stopInVolume < 0.0 ? 1.0 : min(stopInVolume, 1.0);
    stopInVolume = playerPos.y < 0 ? min(stopInVolume, (CONWAY_HEIGHT - 30 - start.y) / playerPos.y) : stopInVolume;
    float rayOffset = 0.001 / lPlayerPos;
    float lastOffset = startInVolume;
    float w = startInVolume;
    progress += floor((startInVolume - progress) / stepSize) * stepSize;
    for (; w < stopInVolume; w = min(progress.x, progress.y)) {
        vec2 mask = vec2(lessThanEqual(progress.xy, progress.yx));
        progress += mask * stepSize;
        float nextW = min(progress.x, progress.y);
        vec3 pos = start + playerPos * (w + rayOffset);
        float livelihood = texelFetch(colortex14, ivec2(floor(pos.xz) + 0.1 + vec2(viewWidth, viewHeight) * 0.5), 0).r;
        vec2 circleCenter = floor(pos.xz) + 0.5 - start.xz;
        float circleW = dot(dir, circleCenter) / lPlayerPos;
        float dist = length(playerPos.xz * circleW - circleCenter);
        float insideLen = 2.0 * sqrt((1.0 / 9.0) - dist * dist) / lPlayerPos;
        if (insideLen != insideLen) {
            insideLen = -(1.0 / 3.0) / lPlayerPos;
        }
        float onset = max(circleW - 0.5 * insideLen, startInVolume);
        float offset = min(circleW + 0.5 * insideLen, stopInVolume);
        insideLen = offset - onset;
        if (offset > onset) {
            if (onset < 1.0) {
                float starty = start.y + playerPos.y * onset - CONWAY_HEIGHT;
                float stopy = start.y + playerPos.y * offset - CONWAY_HEIGHT;
                float cylinderFactor = exp(0.2 * max(starty, stopy)) * livelihood;
                float baseCylinderDensity = cylinderColor.a * cylinderFactor;
                float cylinderDensity = 1 - exp(-baseCylinderDensity * insideLen * dist1);
                color += cylinderDensity * vec4(cylinderColor.rgb * cylinderFactor, 1.0) * (1 - color.a);
                if (color.a > 0.999) {
                    break;
                }
                lastOffset = offset;
            }
        }
    }
    return color;
}