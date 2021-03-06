﻿Shader "Unlit/Raymarch"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _LightDir ("Light Direction", Vector) = (0.0, 0.0, 0.0, 1.0)
        _Color ("Color", Color) = (1.0, 1.0, 1.0, 1.0)
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

            float GetDist(float3 p)
            {
                float3 bp = abs(fmod(p, SPACE_SIZE));
                //fmod loops space, abs mirrors the effect to make it loop infinitely in all directions

                float d = MAX_DIST;
                for (int i = 0; i < numberOfSpheres; i++) //Loop of all circles in scene
                {
                    float3 center = spheres[i].xyz; //Sphere center
                    float radius = spheres[i].w / 2.0; // radius
                    d = smin(d, length(bp - center) - radius, 3);
                    // Distance from the current point to the edge of the closest sphere
                }

                return d;
            }

            float3 GetRegion(float3 p) // Not used currently
            {
                return floor(p / SPACE_SIZE);
            }

            float RestrictToRegion(float3 p, float3 d) // Not used currently
            {
                float3 r = GetRegion(p);
                return length(clamp(p + d, r * SPACE_SIZE, (r + 1) * SPACE_SIZE) - p);
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

                    float3 v = -rd;
                    float3 l = normalize(_LightDir.xyz);
                    float3 h = normalize(l + v);

                    float3 litColor = _Color.xyz * (0.1 + max(0.0, dot(n, l))) + pow(max(0.0, dot(n, h)), 200.0);

                    col = float4(litColor.xyz, 1.0);
                    float s = 0.2;
                    float dp = d / MAX_DIST;
                    col = col * (1 - dp) + float4(base * s, 1.0) * dp;
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