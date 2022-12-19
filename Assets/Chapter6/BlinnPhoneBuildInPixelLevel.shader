Shader "Unity Shaders Book/Chapter6/Blinn-Phone BuildIn PixelLevel"{

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
                // !使用内置函数将法线从模型空间转换到世界空间，但要注意进行归一化操作
                // o.worldNormal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));
                o.worldNormal =normalize(UnityObjectToWorldNormal(v.normal));
                // 将顶点从模型空间转换到世界空间 
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                return o;
            }

            // 在片元着色器中计算漫反射光照模型
            fixed4 frag(v2f i) : SV_Target{
                //环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                //!使用内置函数得到世界空间的光线方向
                // fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 worldLight = normalize(UnityWorldSpaceLightDir(i.worldPos));
                //计算漫反射
                fixed3 diffuse = _LightColor0.rbg * _Diffuse.rgb * saturate(dot(i.worldNormal,worldLight));
                
                //!使用内置函数得到世界空间的视线方向
                // fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz-mul(unity_ObjectToWorld,i.worldPos).xyz);
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
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