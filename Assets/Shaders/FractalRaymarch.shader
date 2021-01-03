Shader "Unlit/Raymarch"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _LightDir ("Light Direction", Vector) = (0.0, 4.05, -3.62, 1.0)
        _Color ("Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _MandelDegree ("Madelbulb degree", Float) = 8.0
        _MandelIterations ("Madelbulb iterations", int) = 100.0
        SURF_DIST ("Surface Distance", float) = 0.01
        MAX_ITERATIONS ("Iterations", int) = 300
        DEPTH_OF_FIELD ("Depth of field", int) = 4
        POWER ("Power", float) = 2
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

            #define MAX_STEPS 600 // The maximum steps a ray can march
            #define MAX_DIST 600 // The maximum distance a ray can march
            //#define SURF_DIST 0.001 // The distance at which something is considered a surface
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
            float _MandelDegree;
            float _MandelIterations;
            float SURF_DIST;
            float MAX_ITERATIONS;
            float DEPTH_OF_FIELD;
            float POWER;
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

            float2 GetDist(float3 p)
            {
                float3 z = p;
                float dr = 1;
                float r = 0;

                int i;
                for (i = 0; i < MAX_ITERATIONS; i++)
                {
                    r = length(z);
                    if (r > DEPTH_OF_FIELD) break;

                    float theta = acos(z.z / r);
                    float phi = atan2(z.y, z.x);
                    dr = pow(r, POWER - 1.0) * POWER * dr + 1.0;

                    float zr = pow(r, POWER);
                    theta = theta * POWER;
                    phi = phi * POWER;

                    z = float3(sin(theta) * cos(phi), sin(theta) * sin(phi), cos(theta));
                    z = z * zr + p;
                }

                return float2(.5 * log(r) * r / dr, i);
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
                int iterations = 0;
                for (int i = 0; i < MAX_STEPS; i++)
                {
                    float3 p = ro + dO * rd; //Gets the current point by adding the distance marched to the origin

                    float2 dist = GetDist(p);
                    iterations = dist.y;
                    dS = dist.x; //Get distance to scene
                    dO += dS; //Add the found distance to the total marched distance
                    if (dS < SURF_DIST || dO > MAX_DIST) break;
                    //If we hit an object or reach the render distance, end the loop.
                }

                return float2(dO, iterations);
            }

            float3 GetNormal(float3 p) //Gets normals by sampling nearby points and and constructing a plane out of them
            {
                float2 e = float2(SURF_DIST / 4.0, 0);

                float3 n = GetDist(p).x - float3(
                    GetDist(p - e.xyy).x,
                    GetDist(p - e.yxy).x,
                    GetDist(p - e.yyx).x
                );

                return normalize(n);
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 base = _Color * float3(0.8, 1.25, 0.95) / 1.25;
                float3 ro = i.ro; // float3(0, 0, -3);
                float3 rd = normalize(i.hitPos - ro); // normalize(float3(uv.x, uv.y, 1));

                float2 raymarch = Raymarch(ro, rd);
                float d = raymarch.x; //Gets the distance one ray travel
                float iterations = raymarch.y;
                fixed4 col;

                if (d < MAX_DIST)
                {
                    float3 p = ro + d * rd;
                    float3 n = GetNormal(p);

                    float3 v = -rd;
                    float3 l = normalize(_LightDir.xyz);
                    float3 h = normalize(l + v);

                    float3 litColor = _Color.xyz * (0.1 + max(0.0, dot(n, l)));// + pow(max(0.0, dot(n, h)), 1000.0);

                    litColor.x += iterations * 0.1;
                    litColor.z += iterations * 0.05;

                    col = float4(litColor.xyz * (1.0 - iterations / 12), 1.0);
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