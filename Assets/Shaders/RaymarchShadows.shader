Shader "Unlit/RaymarchShadows"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _LightDir ("Light Direction", Vector) = (0.0, 0.0, 0.0, 1.0)
        _Color ("Color", Color) = (1.0, 1.0, 1.0, 1.0)

        [Header(Shadows)]
        [Space]
        _ShadowMinDistance ("Shadow Minimum Distance", Float) = 0.1
        _ShadowMaxDistance ("Shadow Maximum Distance", Float) = 100
        _ShadowSoftness ("Shadow Softness", Range(0, 128)) = 20.0
        _ShadowIntensity ("Shadow Intensity", Float) = 2.5

        [Header(Ambient Occlusion)]
        [Space]
        _AOStepsize ("Ambient Occlusion Step Size", Range(0.01, 10.0)) = 0.2
        [IntRange] _AOIterations ("Ambient Occlusion Interations", Range(1, 5)) = 3
        _AOIntensity ("Ambient Occlusion Intensity", Range(0, 1)) = 0.25
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            #define MAX_STEPS 200 // The maximum steps a ray can march
            #define MAX_DIST 70. // The maximum distance a ray can march
            #define SURF_DIST 0.00001 // The distance at which something is considered a surface
            #define SPACE_SIZE 3 // Used in space warping

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 ro : TEXCOORD1;
                float3 hitPos : TEXTCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _LightDir;
            fixed4 _Color;
            StructuredBuffer<float4> spheres;
            int numberOfSpheres;
            
            float _ShadowMinDistance;
            float _ShadowMaxDistance;
            float _ShadowSoftness;
            float _ShadowIntensity;
            float _AOStepsize;
            int _AOIterations;
            float _AOIntensity;
            float _CurrentTime;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.ro = _WorldSpaceCameraPos;
                o.hitPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            float smin(float a, float b, float k) //Selects the minimum but *smoothly*. Makes objects blend together.
            {
                float res = exp2(-k * a) + exp2(-k * b);
                return -log2(res) / k;
            }

            float sdSphere(float3 p, float3 center, float radius)
            {
                return length(p - center) - radius;
            }

            float sdPlane(float3 p, float3 normal, float yHeight)
            {
                // n must be normalized
                return dot(p, normal) + yHeight;
            }

            float sdRoundBox(float3 p, float3 center, float3 size, float r)
            {
                float3 q = abs(p - center) - size;
                return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0) - r;
            }

            float opSmoothSubtraction(float sdf1, float sdf2, float k)
            {
                float h = clamp(0.5 - 0.5 * (sdf2 + sdf1) / k, 0.0, 1.0);
                return lerp(sdf2, -sdf1, h) + k * h * (1.0 - h);
            }

            float GetDist(float3 p)
            {
                float d = MAX_DIST;

                // Add (round box - sphere)
                float3 boxPos = float3(-3, 4, 0);
                float3 spherePos = boxPos;
                spherePos.y += sin(_CurrentTime);
                float sphereRadius = 4 + cos(_CurrentTime / 3) / 2;
                
                float boxMinusSphere = opSmoothSubtraction(
                    sdSphere(p, spherePos, sphereRadius),
                    sdRoundBox(p, boxPos, float3(3, 3, 3), 0.5),
                    0.9
                );
                d = min(d, boxMinusSphere);

                // Add sphere
                float sphere = sdSphere(p, boxPos, 1);
                d = min(d, sphere);
                
                // Add infinite plane
                d = min(d, sdPlane(p, normalize(float3(0, 1, 0)), 2));

                return d;
            }

            float2 Raymarch(float3 ro, float3 rd)
            {
                float dO = 0; //The distance from the origin (camera) / distance the ray has marched
                float dS; //The distance to the scene (closest object) in the current step
                for (int i = 0; i < MAX_STEPS; i++)
                {
                    float3 p = ro + dO * rd; //Gets the current point by adding the distance marched to the origin
                    dS = GetDist(p); //Get distance to scene
                    dO += dS; //Add the found distance to the total marched distance
                    if (dS < SURF_DIST || dO > MAX_DIST) break;
                    //If we hit an object or reach the render distance, end the loop.
                }

                return dO;
            }

            float3 GetNormal(float3 p) //Gets normals by sampling nearby points and and constructing a plane out of them
            {
                float2 e = float2(0.01, 0);

                float3 n = GetDist(p) - float3(
                    GetDist(p - e.xyy),
                    GetDist(p - e.yxy),
                    GetDist(p - e.yyx)
                );

                return normalize(n);
            }

            float HardShadow(float3 ro, float3 rd, float mint, float maxt)
            {
                for (float t = mint; t < maxt;)
                {
                    float distanceToLightSource = GetDist(ro + rd * t);
                    if (distanceToLightSource < SURF_DIST)
                    {
                        return 0.0;
                    }
                    t += distanceToLightSource;
                }
                return 1.0;
            }

            float SoftShadow(const float3 ro, const float3 rd, const float mint, const float maxt, const float softness)
            {
                float result = 1.0;
                for (float t = mint; t < maxt;)
                {
                    const float distanceTowardsLight = GetDist(ro + rd * t);
                    if (distanceTowardsLight < 0.001)
                        return 0.0;
                    result = min(result, softness * distanceTowardsLight / t);
                    t += distanceTowardsLight;
                }
                return result;
            }

            float AmbientOcclusion(float3 p, float3 n)
            {
                float step = _AOStepsize;
                float ao = 0.0;
                float dist;
                for (int i = 1; i <= _AOIterations; i++)
                {
                    dist = step * i;
                    ao += max(0.0, (dist - GetDist(p + n * dist)) / dist);
                }
                return (1.0 - ao * _AOIntensity);
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 base = _Color * float3(0.8, 1.25, 0.95) / 1.25;
                float3 ro = i.ro; // float3(0, 0, -3);
                float3 rd = normalize(i.hitPos - ro); // normalize(float3(uv.x, uv.y, 1));

                float d = Raymarch(ro, rd); //Gets the distance one ray travels
                fixed4 col;

                if (d < MAX_DIST)
                {
                    float3 p = ro + d * rd;
                    float3 n = GetNormal(p);

                    // Lighting
                    float3 v = -rd;
                    float3 l = normalize(_LightDir.xyz);
                    float3 h = normalize(l + v);

                    // Shadow
                    float shadow = SoftShadow(p, l, _ShadowMinDistance, _ShadowMaxDistance, _ShadowSoftness);
                    shadow = shadow * 0.5 + 0.5;
                    shadow = max(0.0, pow(shadow, _ShadowIntensity));

                    // Apply lighting
                    float3 litColor = _Color.xyz * (0.1 + max(0.0, dot(n, l))) + pow(max(0.0, dot(n, h)), 200.0) * shadow;

                    col = float4(litColor.xyz, 1.0);
                    float s = 0.2;
                    float dp = d / MAX_DIST;
                    col = col * (1 - dp) + float4(base * s, 1.0) * dp;

                    // Apply shadow
                    col *= shadow;

                    // Ambient Occlusion + apply
                    float ao = AmbientOcclusion(p, n);
                    col *= ao;
                }
                else
                {
                    float s = 0.2;
                    col = float4(base * s, 1.0); //float4(outColor.xyz, 1.0);
                } //discard; //dont even render this pixel

                return col;
            }
            ENDCG
        }
    }
}