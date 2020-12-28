﻿Shader "Unlit/RaymarchShadows"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _LightDir ("Light Direction", Vector) = (0.0, 0.0, 0.0, 1.0)
        _Color ("Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _ShadowSoftness ("Shadow Softness", Range(0, 128)) = 10.0
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
            uniform int numberOfSpheres;
            uniform float _ShadowSoftness;

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

            float sdPlane(float3 p, float3 n, float h)
            {
                // n must be normalized
                return dot(p, n) + h;
            }

            float GetDist(float3 p)
            {
                float d = MAX_DIST;
                for (int i = 0; i < numberOfSpheres; i++) //Loop of all circles in scene
                {
                    float3 center = spheres[i].xyz; //Sphere center
                    float radius = spheres[i].w / 2.0; // radius
                    d = smin(d, length(p - center) - radius, 3);
                    // Distance from the current point to the edge of the closest sphere
                }
                d = min(d, sdPlane(p, float3(0, 1, 0), 0));

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
                    float3 vertexPos = normalize(i.vertex);
                    float3 v = normalize(- vertexPos);
                    float3 l = normalize(_LightDir.xyz);
                    float3 h = normalize(l + v);

                    float3 litColor = _Color.xyz * (0.1 + max(0.0, dot(n, l))) + pow(max(0.0, dot(n, h)), 200.0);

                    col = float4(litColor.xyz, 1.0);
                    float s = 0.2;
                    float dp = d / MAX_DIST;
                    col = col * (1 - dp) + float4(base * s, 1.0) * dp;

                    // Shadow
                    float shadow = SoftShadow(p, l, 0.1, 100, _ShadowSoftness);
                    col *= shadow;
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