"""iOS 26 아이콘(Icon Composer .icon) 레이어를 만든다.

    python3 tool/icons/make_ios_icon.py ios/Runner/AppIcon.icon
"""
# 평평한 레이어. Icon Composer 가 유리(반사·굴절·그림자)를 입힌다.
import math, os, json, sys
OUT=sys.argv[1]
A=30; DX,DY=-10,12; H=150
BARS=[(551,270,569),(510,510,607),(553,796,304)]
KNOB=(531,256); KR=76
a=math.radians(A)
def lx(cx,cy): dx,dy=KNOB[0]-cx,KNOB[1]-cy; return dx*math.cos(a)+dy*math.sin(a)

def svg(inner, defs=''):
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024"><defs>{defs}</defs>{inner}</svg>'
def cap(cx,cy,L,fill):
    return f'<rect x="{cx-L/2+DX}" y="{cy-H/2+DY}" width="{L}" height="{H}" rx="{H/2}" fill="{fill}" transform="rotate({A} {cx+DX} {cy+DY})"/>'
def grad(id,c0,c1): return f'<linearGradient id="{id}" x1="0" y1="0" x2="1" y2="0" gradientTransform="rotate({A} .5 .5)"><stop offset="0" stop-color="{c0}"/><stop offset="1" stop-color="{c1}"/></linearGradient>'

PAL={
 'light':dict(bars=[('#3C66A6','#2F5A99'),('#4C7FC2','#3A6BB0'),('#6AA2E6','#4F86CC')],fill=('#3FA9FF','#0A84FF'),knob='#FFFFFF'),
 'dark': dict(bars=[('#9CC3F5','#7EAAE6'),('#7FA9E3','#628FCF'),('#5E88C6','#4A73B0')],fill=('#3FA9FF','#0A84FF'),knob='#F2F4F7'),
}
os.makedirs(os.path.join(OUT,'Assets'),exist_ok=True)
for mode,p in PAL.items():
    sfx='' if mode=='light' else '-dark'
    for k,name in [(1,'bar-middle'),(2,'bar-bottom'),(0,'bar-toggle')]:
        cx,cy,L=BARS[k]
        open(os.path.join(OUT,'Assets',f'{name}{sfx}.svg'),'w').write(svg(cap(cx,cy,L,'url(#g)'),grad('g',*p['bars'][k])))
    cx,cy,L=BARS[0]; X,Y=cx+DX,cy+DY; l=lx(cx,cy)
    fill=(f'<g transform="rotate({A} {X} {Y})"><clipPath id="c"><rect x="{X-L/2}" y="{Y-H/2}" width="{L}" height="{H}" rx="{H/2}"/></clipPath>'
          f'<rect x="{X+l}" y="{Y-H/2}" width="{L/2-l+2}" height="{H}" fill="url(#f)" clip-path="url(#c)"/></g>')
    open(os.path.join(OUT,'Assets',f'toggle-fill{sfx}.svg'),'w').write(svg(fill,grad('f',*p['fill'])))
    kx,ky=X+l*math.cos(a),Y+l*math.sin(a)
    open(os.path.join(OUT,'Assets',f'knob{sfx}.svg'),'w').write(svg(f'<circle cx="{kx}" cy="{ky}" r="{KR}" fill="{p["knob"]}"/>'))

def layer(name, glass=True):
    return {"name":name,"glass":glass,
            "image-name-specializations":[{"value":f"{name}.svg"},{"appearance":"dark","value":f"{name}-dark.svg"}]}
icon={
 "fill-specializations":[
   {"value":{"linear-gradient":["srgb:1.00000,1.00000,1.00000,1.00000","srgb:0.90196,0.92941,0.96863,1.00000"]}},
   {"appearance":"dark","value":{"linear-gradient":["srgb:0.10196,0.14902,0.21961,1.00000","srgb:0.04314,0.06667,0.10588,1.00000"]}}],
 "groups":[
   {"name":"knob","layers":[layer("knob")],"shadow":{"kind":"neutral","opacity":0.5},"translucency":{"enabled":True,"value":0.2},"specular":True},
   {"name":"toggle","layers":[layer("toggle-fill"),layer("bar-toggle")],"shadow":{"kind":"layer-color","opacity":0.5},"translucency":{"enabled":True,"value":0.4},"specular":True},
   {"name":"bars","layers":[layer("bar-middle"),layer("bar-bottom")],"shadow":{"kind":"layer-color","opacity":0.5},"translucency":{"enabled":True,"value":0.4},"specular":True},
 ],
 "supported-platforms":{"squares":"shared"}
}
json.dump(icon,open(os.path.join(OUT,'icon.json'),'w'),indent=2)
