Shader "Unlit/Raymarch"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _LightPos ("Light Position", Vector) = (0.0, 4.05, -3.62, 1.0)
        _Color ("Color", Color) = (0.5, 0.75, 0.75, 1.0)
        _Gamma ("Gamma", Float) = 2.2
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

            #define MAX_STEPS 100
            #define MAX_DIST 100
            #define SURF_DIST 0.0001
            #define SPACE_SIZE 10
            
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
            fixed4 _LightPos;
            fixed4 _Color;
            float _Gamma;
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

            float smin( float a, float b, float k )
            {
                float res = exp2( -k*a ) + exp2( -k*b );
                return -log2( res )/k;
            }

            float GetDist(float3 p)
            {
                float3 bp = fmod( p, SPACE_SIZE);

                float d = MAX_DIST;
                for (int i = 0; i < numberOfSpheres; i++)
                {
                    float3 center = spheres[i].xyz;
                    float radius = spheres[i].w / 2.0;
                    d = smin(d, length(bp - center) - radius, 3);
                }

                return d;
            }

            float3 GetRegion(float3 p)
            {
                return (p - fmod(p, SPACE_SIZE)) / SPACE_SIZE;
            }

            float RestrictToRegion(float3 p, float3 d)
            {
                float3 r = GetRegion(p);
                return length(clamp(p + d, r * SPACE_SIZE, (r + 1) * SPACE_SIZE) - p);
            }

            float Raymarch(float3 ro, float3 rd)
            {
                float dO = 0;
                float dS;
                for (int i = 0; i < MAX_STEPS; i++)
                {
                    float3 p = ro + dO * rd;
                    dS = GetDist(p);
                    if (all(GetRegion(ro + (dO + dS) * rd) == GetRegion(p)))
                    {
                        dO += dS;
                        if (dS < SURF_DIST || dO > MAX_DIST) break;
                    } else
                    {
                        float dR = RestrictToRegion(p, dS * rd);
                        dO += min(dS, dR);
                        if (dO > MAX_DIST) break;
                    }
                }

                return dO;
            }

            float3 GetNormal(float3 p)
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
                float3 base = float3(0.4, 0.8, 0.9);
                float3 ro = i.ro; // float3(0, 0, -3);
                float3 rd = normalize(i.hitPos - ro); // normalize(float3(uv.x, uv.y, 1));

                float d = Raymarch(ro, rd);
                fixed4 col = 0;

                if (d < MAX_DIST)
                {
                    float3 p = ro + d * rd;
                    float3 n = GetNormal(p);
                    col.rgb = n;

                    float3 lightPos = _LightPos.xyz;
                    float3 vertexPos = normalize(i.vertex);

                    float3 v = normalize(- vertexPos);
                    float3 l = normalize(lightPos - vertexPos);
                    float3 h = normalize(l + v);

                    float3 gammaColor = pow(_Color.xyz, float3(_Gamma, _Gamma, _Gamma));
                    float3 litColor = gammaColor * (0.1 + max(0.0, dot(n, l))) + pow(max(0.0, dot(n, h)), 200.0);
                    float3 outColor = pow(litColor, float3(1.0 / _Gamma, 1.0 / _Gamma, 1.0 / _Gamma));

                    col = float4(outColor.xyz, 1.0);
                    //float s = 0.2 + (1-( d / 100.0)) * 0.8 ;
                    //col = col * 0.5 + float4(base * s, 1.0) * 0.5;
                }
                else
                {
                    float s = 0.2 ;
                    col = float4(base * s, 1.0);//float4(outColor.xyz, 1.0);
                }//discard; //dont even render this pixel

                return col;
            }
            ENDCG
        }
    }
}