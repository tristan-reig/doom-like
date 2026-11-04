// Shader du sol et du plafond
extern Image floorTex;
extern Image ceilTex;

extern vec2 playerPos;
extern vec2 forward;
extern vec2 right;
extern number projDist;
extern vec2 halfScreen;
extern number camHeight;
extern number tileSize;
extern number fadeDist;

vec4 effect(vec4 color, Image tex, vec2 texCoords, vec2 screenCoords)
{
    number p = screenCoords.y - halfScreen.y;
    bool isFloor = p > 0.0;
    p = max(abs(p), 0.5); // évite une division par zéro sur l'horizon

    number rowDist = camHeight * projDist / p;
    number k = (screenCoords.x - halfScreen.x) / projDist;
    vec2 world = playerPos + rowDist * (forward + right * k);
    vec2 uv = world / tileSize;

    vec4 c;
    if (isFloor) {
        c = Texel(floorTex, uv);
    } else {
        c = Texel(ceilTex, uv);
    }

    // Même assombrissement que les murs
    number shade = max(0.25, 1.0 - rowDist / fadeDist);
    return vec4(c.rgb * shade, 1.0) * color;
}
