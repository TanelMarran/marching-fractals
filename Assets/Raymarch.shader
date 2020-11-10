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
            #define SURF_DIST 0.001

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

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.ro = _WorldSpaceCameraPos;//mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
                o.hitPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            float GetDist(float3 p)
            {
                float3 bp = p;

                //float3 n = normalize(float3(1.0, 1.0, 1.0));
                //bp -= 2.*min(0., dot(p, n));
                bp = abs(bp);
                //bp.z += sin(bp.x) * 3.;
                float d = length(bp - float3(6.0, 2.0, 4.0)) - 1.; // sphere

                return d;
            }

            float Raymarch(float3 ro, float3 rd)
            {
                float dO = 0;
                float dS;
                for (int i = 0; i < MAX_STEPS; i++)
                {
                    float3 p = ro + dO * rd;
                    dS = GetDist(p);
                    dO += dS;
                    if (dS < SURF_DIST || dO > MAX_DIST) break;
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
                }
                else discard; //dont even render this pixel

                return col;
            }
            ENDCG
        }
    }
}