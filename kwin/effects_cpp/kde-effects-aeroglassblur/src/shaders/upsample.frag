uniform sampler2D texUnit;
uniform float offset;
uniform vec2 halfpixel;

uniform float aeroColorR;
uniform float aeroColorG;
uniform float aeroColorB;
uniform float aeroColorA;
uniform float aeroColorBalance;
uniform float aeroAfterglowBalance;
uniform float aeroBlurBalance;
uniform bool  aeroColorize;

uniform mat4 colorMatrix;
varying vec2 uv;

void main(void)
{
    vec4 sum = texture2D(texUnit, uv + vec2(-halfpixel.x * 2.0, 0.0) * offset);
    sum += texture2D(texUnit, uv + vec2(-halfpixel.x, halfpixel.y) * offset) * 2.0;
    sum += texture2D(texUnit, uv + vec2(0.0, halfpixel.y * 2.0) * offset);
    sum += texture2D(texUnit, uv + vec2(halfpixel.x, halfpixel.y) * offset) * 2.0;
    sum += texture2D(texUnit, uv + vec2(halfpixel.x * 2.0, 0.0) * offset);
    sum += texture2D(texUnit, uv + vec2(halfpixel.x, -halfpixel.y) * offset) * 2.0;
    sum += texture2D(texUnit, uv + vec2(0.0, -halfpixel.y * 2.0) * offset);
    sum += texture2D(texUnit, uv + vec2(-halfpixel.x, -halfpixel.y) * offset) * 2.0;

    sum /= 12.0;

    if (aeroColorize)
    {
        vec4 color          = vec4(aeroColorR, aeroColorG, aeroColorB, aeroColorA);
        vec3 primaryColor   = color.rgb;
        vec3 secondaryColor = color.rgb;
        vec3 primaryLayer   = primaryColor * aeroColorBalance; // * pow(c, 1.1);
        vec3 secondaryLayer = (secondaryColor * dot(sum.xyz, vec3(0.3, 0.6, 0.1))) * aeroAfterglowBalance;
        vec3 blurLayer      = sum.xyz * aeroBlurBalance;

        gl_FragColor = vec4(primaryLayer + secondaryLayer + blurLayer, 1.0);
    }
    else
    {
        gl_FragColor = sum;
    }

    gl_FragColor *= colorMatrix;
}
