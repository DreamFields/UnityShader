Shader "Unity Shaders Book/Chapter6/Diffuse Pixel-Level"{

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
                float3 worldNormal : NORMAL;
            };
            
            v2f vert(a2v v){
                v2f o;
                //将顶点从模型空间转换到裁剪空间
                o.pos = UnityObjectToClipPos(v.vertex);
                //将法线从模型空间转换到世界空间，截取unity_WorldToObject的前三行前三列
                o.worldNormal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));
 
                return o;
            }

            fixed4 frag(v2f i) : SV_Target{
                //环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                //世界空间的光线方向，假设场景中只有一个光源且是平行光，其它光源要改变计算方法
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 diffuse = _LightColor0.rbg * _Diffuse.rgb * (dot(i.worldNormal,worldLight)*0.5 + 0.5);
                return fixed4(diffuse+ambient,1.0);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}