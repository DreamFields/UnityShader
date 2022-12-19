Shader "Unity Shaders Book/Chapter6/Blinn-Phone Specular Pixel-Level"{

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
                // fixed3 color : COLOR;
                float3 worldNormal:NORMAL;

                // 修改顶点着色器的输出结构体
                float3 worldPos: TEXCOORD1;
            };
            
            // 顶点着色器不计算光照模型
            v2f vert(a2v v){
                v2f o;
                //将顶点从模型空间转换到裁剪空间，其实在片元着色器中用不到
                o.pos = UnityObjectToClipPos(v.vertex);               
                //将法线从模型空间转换到世界空间，之后传递给片元着色器
                o.worldNormal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));
                // 将顶点从模型空间转换到世界空间 
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                return o;
            }

            // 在片元着色器中计算漫反射光照模型
            fixed4 frag(v2f i) : SV_Target{
                //环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                //世界空间的光线方向
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
                //计算漫反射
                fixed3 diffuse = _LightColor0.rbg * _Diffuse.rgb * saturate(dot(i.worldNormal,worldLight));
                
                //得到世界空间的视线方向：通过_ WorldSpaceCameraPos 得到了世界空间中的摄像机位置，再把顶点位置从模型空间
                // 变换到世界空间下，再通过和_WorldSpaceCameraPos 相减即可得到世界空间下的视角方向。
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz-mul(unity_ObjectToWorld,i.worldPos).xyz);
                // 计算世界空间的半程向量方向
                fixed3 halfDir = normalize(worldLight+viewDir);
                //使用Blinn-Phong计算高光项
                fixed3 specular = _LightColor0.rbg*_Specular.rgb*pow(saturate(dot(i.worldNormal,halfDir)),_Gloss);
                
                float3 color = ambient+diffuse+specular;
                return fixed4(color,1.0);
            }
            ENDCG
        }
    }
    FallBack "Specular"
}