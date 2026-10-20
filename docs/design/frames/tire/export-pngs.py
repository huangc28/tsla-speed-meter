#!/usr/bin/env python3
"""Export round-7 PNGs. SVG uses the HTML's shared model and bundled TTF metrics.

Chrome mode also runs the page's actual DOM audit. SVG mode explicitly records
that its geometry checks are not a browser audit. Old PNG names are untouched.
"""
import argparse, html, json, os, re, shutil, subprocess, tempfile
from pathlib import Path
from PIL import ImageFont

ROOT = Path(__file__).resolve().parent
NODE = r"""
const fs=require('node:fs'),vm=require('node:vm');
const html=fs.readFileSync(process.argv[1],'utf8');
const model=html.split('// BEGIN TIRE MODEL:')[1].split('\n').slice(1).join('\n').split('// END TIRE MODEL')[0];
const context={};vm.createContext(context);vm.runInContext(model,context);
const specs=[];
function add(state,width,lang,style='glass',scale=1,end=false,name=''){
 const model=vm.runInContext(`makeModel(${JSON.stringify(state)},${width},${JSON.stringify(lang)},${JSON.stringify(style)},${scale})`,context);
 specs.push({name:name||`r7-${state}-${width}-${lang}`,end,model});
}
for(const state of vm.runInContext('Object.keys(stateNames)',context))for(const width of [184,165,280])for(const lang of ['zh','en'])add(state,width,lang);
for(const width of [184,165,280])for(const lang of ['zh','en'])add('mixed',width,lang,'ceramic',1,false,`r7-ceramic-${width}-${lang}`);
for(const scale of [1.5,2])for(const width of [184,165,280])for(const lang of ['zh','en'])for(const end of [false,true])add('mixed',width,lang,'glass',scale,end,`r7-mixed-${Math.round(scale*100)}-${width}-${lang}-${end?'end':'top'}`);
console.log(JSON.stringify(specs));
"""
FONT_CACHE = {}
def font(size, cjk=False):
    key=(round(size*100),cjk)
    if key not in FONT_CACHE:
        FONT_CACHE[key]=ImageFont.truetype(str(ROOT/('NotoSansTC-400.ttf' if cjk else 'Inter-600.ttf')),key[0])
    return FONT_CACHE[key]
def advance(text,size):
    total=0; run=''
    for ch in text:
        if '\u4e00'<=ch<='\u9fff' or ch in '，。':
            if run: total+=font(size).getlength(run)/100; run=''
            total+=font(size,True).getlength(ch)/100
        else: run+=ch
    return total+(font(size).getlength(run)/100 if run else 0)
def numeric_advance(value,size):
    return font(size).getlength(value,features=['tnum'])/100
def wrap(text,size,width):
    tokens=text.split(' ') if ' ' in text else list(text); lines=['']; sep=' ' if ' ' in text else ''
    for token in tokens:
        candidate=lines[-1]+(sep if lines[-1] else '')+token
        if advance(candidate,size)<=width+.01: lines[-1]=candidate; continue
        if lines[-1]: lines.append('')
        for ch in token:
            if lines[-1] and advance(lines[-1]+ch,size)>width+.01: lines.append('')
            lines[-1]+=ch
    return lines

def baseline_at(top,size,line_height):
    ascent,descent=font(size).getmetrics()
    return top+(line_height-(ascent+descent)/100)/2+ascent/100
def text(value,x,top,size,line_height,color='#AEBCD4',baseline=None,tabular=False):
    if baseline is None:baseline=baseline_at(top,size,line_height)
    feature=' style="font-variant-numeric:tabular-nums;font-feature-settings: &quot;tnum&quot;"' if tabular else ''
    return f'<text x="{x:.4f}" y="{baseline:.4f}" font-size="{size}" fill="{color}"{feature}>{html.escape(value)}</text>'
def backing(x,y,w,h):
    return f'<rect x="{x-2:.4f}" y="{y:.4f}" width="{w+4:.4f}" height="{h:.4f}" rx="1" fill="#101B2E"/>'
def artwork(style,x,y,w,h):
    svg=(ROOT/f'car-{style}.svg').read_text()
    return re.sub(r'<svg\b[^>]*>',f'<svg xmlns="http://www.w3.org/2000/svg" x="{x}" y="{y}" width="{w}" height="{h}" viewBox="0 0 100 200" fill="none">',svg,count=1)
def locator(index,x,y):
    marks=''.join(f'<rect x="{xx}" y="{yy}" width="4" height="7" rx="2" fill="{("#AEBCD4" if i==index else "#101B2E")}" stroke="#AEBCD4"/>' for i,(xx,yy) in enumerate([(2,9),(18,9),(2,27),(18,27)]))
    return f'<g transform="translate({x} {y})"><rect x="7" y="3" width="10" height="34" rx="4" fill="none" stroke="#8A97AE"/>{marks}</g>'
def reading(w,x,y,scale,historical):
    size=19*scale; unit_size=12*scale; line=24*scale; value=w['value']; vw=numeric_advance(value,size)
    width=vw+(3+advance('psi',unit_size) if w['psi'] is not None else 0)
    color='#8A97AE' if historical else '#F2F5FA'
    result=backing(x,y,width,line)+text(value,x,y,size,line,color,tabular=True)
    if w['psi'] is not None:result+=text('psi',x+vw+3,y,unit_size,line,color,baseline_at(y,size,line))
    return result,width

def compose(model,end=False):
    m=model; g=m['geometry']; width=m['width']; height=g['height']; scale=m['scale']; parts=[]; issues=[]
    if m['hidden']:return f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}"><rect width="100%" height="100%" fill="#101B2E"/></svg>',{'layout':'hidden','issues':[]}
    reading_widths=[numeric_advance(w['value'],19*scale)+(3+advance('psi',12*scale) if w['psi'] is not None else 0) for w in m['wheels']]
    reading_heights=[] if m['unsupported'] else [24*scale for _ in m['wheels']]
    summary_scale=m['summaryScale']; summary_size=12*summary_scale; summary_line=14*summary_scale
    summary_lines=wrap(m['summary']['text'],summary_size,width) if m['summary']['text'] and not m['unsupported'] else []
    summary_height=len(summary_lines)*summary_line
    heading_height=len(wrap(m['title'],14*scale,width))*18*scale
    use_list=any(h>32.01 for h in reading_heights) or (not m['unsupported'] and any(w>g['col']+.01 for w in reading_widths)) or summary_height>32.01 or heading_height>24.01
    if len(summary_lines)>2:issues.append('Shared time exceeds two lines')
    if use_list:
        # Header and shared age stay fixed; only the four rows scroll.
        usable=width-13
        header_lines=wrap(m['title'],14*scale,width-(32 if not m['unsupported'] else 0)); header_h=max(48 if not m['unsupported'] else 0,len(header_lines)*18*scale)
        for i,line in enumerate(header_lines):parts.append(text(line,0,i*18*scale,14*scale,18*scale))
        if not m['unsupported']:parts.append(artwork(m['style'],width-24,(header_h-48)/2,24,48))
        y=header_h+12
        for line in summary_lines:
            parts.append(backing(0,y,advance(line,summary_size),summary_line)+text(line,0,y,summary_size,summary_line));y+=summary_line
        if summary_lines:y+=16
        if y>=height:issues.append('Shared time not visible without scrolling')
        if m['unsupported']:
            for line in wrap(m['unavailable'],14*scale,width):parts.append(text(line,0,y,14*scale,21*scale));y+=21*scale
        else:
            rows=[]; row_y=0; viewport=height-y
            for i,w in enumerate(m['wheels']):
                position_lines=wrap(w['position'],12*scale,usable-36)
                copy_h=len(position_lines)*16*scale+24*scale;row_h=max(48,copy_h);copy_y=row_y+(row_h-copy_h)/2
                rows.append(locator(i,0,row_y+(row_h-40)/2))
                for j,line in enumerate(position_lines):
                    top=copy_y+j*16*scale
                    rows.append(backing(36,top,advance(line,12*scale),16*scale)+text(line,36,top,12*scale,16*scale))
                item,item_width=reading(w,36,copy_y+len(position_lines)*16*scale,scale,w['dim']);rows.append(item)
                if 36+item_width>usable+.5:issues.append('List reading overflows')
                row_y+=row_h+12
            content_h=row_y;offset=max(0,content_h-viewport) if end else 0
            parts.append(f'<defs><clipPath id="readings-clip"><rect x="0" y="{y}" width="{width}" height="{viewport}"/></clipPath></defs><g clip-path="url(#readings-clip)"><g transform="translate(0 {y-offset})">'+''.join(rows)+'</g></g>')
            if content_h>viewport:
                thumb=max(22,viewport*viewport/content_h);thumb_y=y+(viewport-thumb if end else 0)
                parts.append(f'<rect x="{width-4}" y="{thumb_y}" width="3" height="{thumb}" rx="1.5" fill="#8A97AE"/>')
    else:
        parts.append(text(m['title'],0,0,14*scale,18*scale))
        if m['unsupported']:
            for i,line in enumerate(wrap(m['unavailable'],14*scale,width)):parts.append(text(line,0,104+i*21*scale,14*scale,21*scale))
        else:
            parts.append(artwork(m['style'],(width-g['carW'])/2,g['carTop'],g['carW'],g['carH']))
            for i,w in enumerate(m['wheels']):
                rw=reading_widths[i];x=g['labelRight']-rw if i%2==0 else g['labelLeft']
                y=height-g['frontBottom']-24*scale if i<2 else g['rearTop']
                item,_=reading(w,x,y,scale,w['dim']);parts.append(item)
                if x<-.5 or x+rw>width+.5 or y<24 or y+24*scale>height:issues.append('Diagram reading outside bounds')
                if i<2 and y+24*scale>g['carTop']+g['carH']*.19-7.5:issues.append('Front reading touches capsule')
                if i>=2 and y<g['carTop']+g['carH']*.73+7.5:issues.append('Rear reading touches capsule')
                center=(x+rw/2,y+12*scale)
                wheel_centers=[((width-g['carW'])/2+g['carW']*xx,g['carTop']+g['carH']*yy) for xx,yy in [(.11,.265),(.89,.265),(.11,.655),(.89,.655)]]
                distances=[((center[0]-xx)**2+(center[1]-yy)**2)**.5 for xx,yy in wheel_centers]
                if min(d for j,d in enumerate(distances) if i!=j)+.01<1.5*distances[i]:issues.append('Reading not 1.5 times closer to own wheel')
            y=g['summaryTop']
            for line in summary_lines:
                tw=advance(line,summary_size);x=(width-tw)/2;parts.append(backing(x,y,tw,summary_line)+text(line,x,y,summary_size,summary_line));y+=summary_line
            if y>height+.5:issues.append('Shared time outside bounds')
    svg=f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}"><rect width="100%" height="100%" fill="#101B2E"/><g font-family="Inter, Noto Sans TC" font-weight="600">'+''.join(parts)+'</g></svg>'
    return svg,{'layout':'list' if use_list else 'diagram','metrics':{'readingHeights':reading_heights,'readingWidths':reading_widths if not m['unsupported'] else [],'columnWidth':g['col'],'summaryHeight':summary_height,'summaryLines':len(summary_lines),'headingHeight':heading_height},'dimWheels':[w['coord'] for w in m['wheels'] if w['dim']] if not m['unsupported'] else [],'issues':issues}

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--renderer',choices=['auto','chrome','svg'],default='auto');args=parser.parse_args()
    chrome=os.environ.get('TIRE_CHROME','/Applications/Google Chrome.app/Contents/MacOS/Google Chrome')
    renderer=args.renderer;reason='explicit SVG renderer' if renderer=='svg' else ''
    specs=json.loads(subprocess.run(['node','-e',NODE,str(ROOT/'tire-icon.html')],check=True,capture_output=True,text=True).stdout)
    with tempfile.TemporaryDirectory(prefix='tire-r7-') as tmp:
        if renderer=='auto':
            try:
                probe=subprocess.run([chrome,'--headless=new','--disable-gpu','--no-first-run','--no-default-browser-check',f'--user-data-dir={tmp}/chrome-probe','--dump-dom','about:blank'],capture_output=True,timeout=15)
                if probe.returncode==0:renderer='chrome'
                else:renderer='svg';reason=f'Chrome probe exit {probe.returncode}'
            except (OSError,subprocess.TimeoutExpired) as e:renderer='svg';reason=str(e)
        if renderer=='svg' and not shutil.which('rsvg-convert'):raise SystemExit('rsvg-convert is required for the SVG fallback')
        config=Path(tmp)/'fonts.conf';config.write_text(f'<?xml version="1.0"?><!DOCTYPE fontconfig SYSTEM "fonts.dtd"><fontconfig><dir>{html.escape(str(ROOT))}</dir><cachedir>{tmp}/font-cache</cachedir></fontconfig>')
        env={**os.environ,'FONTCONFIG_FILE':str(config)};results=[]
        for spec in specs:
            m=spec['model'];out=ROOT/(spec['name']+'.png');svg,check=compose(m,spec['end'])
            if check['issues']:raise RuntimeError(f'{spec["name"]}: {check["issues"]}')
            if renderer=='svg':
                subprocess.run(['rsvg-convert','-w',str(m['width']*2),'-h',str(m['geometry']['height']*2),'-o',str(out)],input=svg,text=True,check=True,env=env,capture_output=True)
            else:
                query=f'state={m["state"]}&size={m["width"]}&lang={m["lang"]}&style={m["style"]}&scale={m["scale"]}&end={int(spec["end"])}'
                cmd=[chrome,'--headless=new','--disable-gpu','--hide-scrollbars','--no-first-run','--no-default-browser-check',f'--user-data-dir={tmp}/chrome-export',f'--window-size={m["width"]},{m["geometry"]["height"]}','--force-device-scale-factor=2','--virtual-time-budget=8000',f'--screenshot={out}','--dump-dom',(ROOT/'tire-icon.html').as_uri()+'?'+query]
                result=subprocess.run(cmd,check=True,capture_output=True,text=True,timeout=30)
                match=re.search(r'<script id="tire-audit-result" type="application/json">(.*?)</script>',result.stdout,re.S)
                if not match:raise RuntimeError('Chrome DOM audit did not finish')
                check['browserAudit']=json.loads(html.unescape(match[1]));
                if check['browserAudit']['issues']:raise RuntimeError(str(check['browserAudit']))
            from PIL import Image
            with Image.open(out) as image:assert image.size==(m['width']*2,m['geometry']['height']*2),(spec['name'],image.size)
            results.append({'file':out.name,**check})
        report={'round':7,'ruling':'L46','renderer':renderer,'reason':reason,'browserAudit':'performed per image' if renderer=='chrome' else 'not performed; SVG vector/TTF geometry checks only','count':len(results),'issues':[],'outputs':results}
        (ROOT/'r7-export-audit.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
        print(json.dumps({'renderer':renderer,'reason':reason,'pngs':len(results),'issues':[],'browserAudit':report['browserAudit']},ensure_ascii=False))
if __name__=='__main__':main()
