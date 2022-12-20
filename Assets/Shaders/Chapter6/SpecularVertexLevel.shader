Shader "Unity Shaders Book/Chapter6/Specular Vertex-Level"{

    Properties{
        _Diffuse ("Diffuse",Color) = (1,1,1,1)
        _Gloss ("Gloss", Range(8.0,256)) = 20 // 控制高光区域的大小
        _Specular ("Specular", Color) = (1,1,1,1) // 控制材质的高光反射颜色
    }

    SubShader{
        Pass{
            Tags{"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"
            fixed4 _Diffuse; 
            float _Gloss;
            fixed4 _Specular; 
            struct a2v{
                float4 vertex : POSITION; 
                float3 normal : NORMAL; 
            };

            struct v2f{
                float4 pos : SV_POSITION;
                fixed3 color : COLOR;
            };
            
            v2f vert(a2v v){
                v2f o;
                //将顶点从模型空间转换到裁剪空间
                o.pos = UnityObjectToClipPos(v.vertex);
                //环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                //将法线从模型空间转换到世界空间
                fixed3 worldNormal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));
                //世界空间的光线方向
                // !_WorldSpaceLightPos0.xyz 是指向光源的方向
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 diffuse = _LightColor0.rbg * _Diffuse.rgb * saturate(dot(worldNormal,worldLight));

                //计算世界空间的光线反射方向
                // CG 的reflect 函数的入射方向要求是由光源指向交点处的
                fixed3 reflectDir = normalize(reflect(-worldLight,worldNormal));
                //得到世界空间的视线方向：通过_ WorldSpaceCameraPos 得到了世界空间中的摄像机位置，再把顶点位置从模型空间
                // 变换到世界空间下，再通过和_WorldSpaceCameraPos 相减即可得到世界空间下的视角方向。
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz-mul(unity_ObjectToWorld,v.vertex).xyz);
                //计算高光项
                fixed3 specular = _LightColor0.rbg*_Specular.rgb*pow(saturate(dot(reflectDir,viewDir)),_Gloss);
                
                o.color = ambient+diffuse+specular;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target{
                return fixed4(i.color,1.0);
            }
            ENDCG
        }
    }
    FallBack "Specular"
}