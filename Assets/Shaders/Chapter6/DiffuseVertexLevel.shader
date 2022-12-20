Shader "Unity Shaders Book/Chapter6/Diffuse Vertex-Level"{

    Properties{
        _Diffuse ("Diffuse",Color) = (1,1,1,1)
    }

    SubShader{
        Pass{
            // LightMode 标签是Pass 标签中的一种，它用于定义该Pass 在Unity 的光照流水线中的角色
            Tags{"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // 为了使用Unity 内置的一些变量，如后面要讲到的_LightColor0 ,包含进Unity 的内置文件
            #include "Lighting.cginc"
            fixed4 _Diffuse; 
            struct a2v{
                float4 vertex : POSITION; 
                float3 normal : NORMAL; 
            };

            struct v2f{
                float4 pos : SV_POSITION;
                // 并不是必须使用COLOR语义， 一些资料中会使用TEXCOORDO 语义。
                fixed3 color : COLOR;
            };
            
            v2f vert(a2v v){
                v2f o;
                //将顶点从模型空间转换到裁剪空间
                o.pos = UnityObjectToClipPos(v.vertex);
                //环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                //将法线从模型空间转换到世界空间，截取unity_WorldToObject的前三行前三列
                fixed3 worldNormal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));
                //世界空间的光线方向，假设场景中只有一个光源且是平行光，其它光源要改变计算方法
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
                //计算漫反射，saturate函数将参数截取在[0, 1)范围内，如果是一个矢量，则对它的每一个分量进行这样的操作。
                // Unity 提供给我们一个内置变量_LightColor0 来访问该Pass 处理的光源的颜色和强度信息
                fixed3 diffuse = _LightColor0.rbg * _Diffuse.rgb * saturate(dot(worldNormal,worldLight));

                o.color = ambient+diffuse;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target{
                return fixed4(i.color,1.0);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}