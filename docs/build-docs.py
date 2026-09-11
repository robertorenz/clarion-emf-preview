# Builds the four EmfPreview volumes:
#
#   getting-started.html    install it, the first preview, the tests
#   programmers-guide.html  the concepts, the recipes, the Clarion 12 Unicode notes
#   template-guide.html     both extensions, every tab, prompt and embed point
#   reference.html          the classes, the queues, the equates, the template symbols
#
# The reference volume is READ OUT OF THE SOURCES - src/EmfPreview.inc and
# src/EmfPreview.tpl - so a signature or a default here is the one in the
# build.  Run this after changing the API:   python docs\build-docs.py
import io, re, html, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INC  = os.path.join(ROOT, 'src', 'EmfPreview.inc')
TPL  = os.path.join(ROOT, 'src', 'EmfPreview.tpl')
CLW  = os.path.join(ROOT, 'src', 'EmfPreview.clw')
OUT  = os.path.join(ROOT, 'docs')

def _read(p):
    return io.open(p, encoding='utf-8', newline='').read().replace('\r\n', '\n')

# ---------------------------------------------------------------- extract: classes
def _block(text, start_re):
    lines = text.split('\n')
    a = next(i for i, l in enumerate(lines) if re.match(start_re, l))
    b = next(i for i, l in enumerate(lines) if i > a and re.match(r'^\s+END\s*$', l))
    return lines[a], lines[a + 1:b]

def _extract_class(name):
    """Properties and methods of one CLASS in EmfPreview.inc, with the section
    comment each sits under and the trailing comment on its own line."""
    head, body = _block(_read(INC), r'^%s\s+CLASS' % name)
    props, meths, section = [], [], ''
    for ln in body:
        t = ln.strip()
        m = re.match(r'^! ---- (.+?) -+$', t)
        if m:
            section = m.group(1).strip(); continue
        if not t or t.startswith('!'):
            continue
        m = re.match(r'^(\w+)\s+PROCEDURE\((.*?)\)((?:,[A-Z]+)*)(?:\s+!\s*(.*))?$', ln)
        if m:
            attrs = [a for a in m.group(3).split(',') if a]
            meths.append({'name': m.group(1), 'parms': m.group(2).strip(),
                          'attrs': attrs, 'note': (m.group(4) or '').strip(),
                          'section': section})
            continue
        m = re.match(r'^(\w+)\s+([^\s!]+)(?:\s*!\s*(.*))?$', ln)
        if m:
            props.append({'name': m.group(1), 'type': m.group(2),
                          'note': (m.group(3) or '').strip(),
                          'protected': 'PROTECTED' in m.group(2),
                          'section': section})
    m = re.match(r'^\w+\s+CLASS\((\w+)\)', head)
    parent = m.group(1) if m else ''
    impl = re.findall(r'IMPLEMENTS\((\w+)\)', head)
    return {'name': name, 'head': head.strip(), 'parent': parent, 'implements': impl,
            'props': props, 'meths': meths}

def _extract_queues():
    text = _read(INC)
    out = []
    for m in re.finditer(r'^(\w+)\s+QUEUE,TYPE\s*$', text, re.M):
        name = m.group(1)
        head, body = _block(text, r'^%s\s+QUEUE,TYPE' % name)
        # the comment lines directly above the declaration describe it
        above, i = [], text[:m.start()].rstrip('\n').split('\n')
        while i and i[-1].startswith('!'):
            above.insert(0, i.pop().lstrip('! ').strip())
        fields = []
        for ln in body:
            mm = re.match(r'^(\w+)\s+([^\s!]+)(?:\s*!\s*(.*))?$', ln)
            if mm:
                fields.append({'name': mm.group(1), 'type': mm.group(2), 'note': (mm.group(3) or '').strip()})
            elif fields and ln.strip().startswith('!'):
                # a continuation comment belongs to the previous field
                fields[-1]['note'] += ' ' + ln.strip().lstrip('! ').strip()
        out.append({'name': name, 'doc': ' '.join(above), 'fields': fields})
    return out

def _extract_equates():
    out = []
    for m in re.finditer(r'^(EmfPrv:[\w:]+)\s+EQUATE\((.*?)\)(?:\s*!\s*(.*))?$', _read(INC), re.M):
        out.append({'name': m.group(1), 'value': m.group(2), 'note': (m.group(3) or '').strip()})
    return out

# ---------------------------------------------------------------- extract: template
def _prompt_type(t):
    t = t.strip()
    if t == 'CHECK': return 'check box'
    if t == 'COLOR': return 'colour'
    m = re.match(r'SPIN\((@\w+),(-?\d+),(-?\d+)(?:,(\d+))?\)', t)
    if m: return 'spin %s to %s%s' % (m.group(2), m.group(3), (', step ' + m.group(4)) if m.group(4) else '')
    m = re.match(r"DROP\('(.*)'\)", t)
    if m: return 'drop: ' + ', '.join(m.group(1).split('|'))
    m = re.match(r'@s(\d+)', t)
    if m: return 'text, %s characters' % m.group(1)
    return t

def _colorref(v):
    """COLORREF 00BBGGRR (as a decimal in the template) -> #RRGGBB for a swatch."""
    try: v = int(v)
    except ValueError: return None
    return '#%02X%02X%02X' % (v & 255, (v >> 8) & 255, (v >> 16) & 255)

def _extract_template():
    text = _read(TPL)
    m = re.match(r"#TEMPLATE\((\w+),'(.*?)'\),FAMILY\('(\w+)'\)", text)
    tpl = {'name': m.group(1), 'desc': m.group(2), 'family': m.group(3), 'extensions': []}
    ext, tab, enable = None, '', []
    for ln in text.split('\n'):
        t = ln.strip()
        m = re.match(r"#EXTENSION\((\w+),'(.*?)'\),(APPLICATION|PROCEDURE)(.*)$", t)
        if m:
            req = re.search(r'REQ\((\w+)\)', m.group(4))
            ext = {'name': m.group(1), 'desc': m.group(2), 'scope': m.group(3),
                   'req': req.group(1) if req else '', 'tabs': [], 'ats': [], 'atstart': 0,
                   'restrict': ''}
            tpl['extensions'].append(ext); tab, enable = '', []; continue
        if ext is None: continue
        m = re.match(r"#TAB\('(.*?)'\)", t)
        if m: tab = m.group(1); continue
        if t == '#ENDTAB': tab = ''; continue
        m = re.match(r'#ENABLE\((.*)\)$', t)
        if m: enable.append(m.group(1)); continue
        if t == '#ENDENABLE': enable.pop(); continue
        m = re.match(r"#PROMPT\('((?:[^']|'')*)',(.*)\),(%\w+)(.*)$", t)
        if m:
            d = re.search(r"DEFAULT\(('?)(.*?)\1\)", m.group(4))
            p = {'label': m.group(1).replace('&', '').replace("''", "'"), 'type': m.group(2),
                 'kind': _prompt_type(m.group(2)), 'symbol': m.group(3),
                 'default': d.group(2) if d else '', 'enable': ' and '.join(enable), 'tab': tab}
            if m.group(2).strip() == 'COLOR': p['swatch'] = _colorref(p['default'])
            tabs = [x for x in ext['tabs'] if x['name'] == tab]
            if not tabs:
                ext['tabs'].append({'name': tab, 'prompts': []}); tabs = [ext['tabs'][-1]]
            tabs[0]['prompts'].append(p); continue
        if t == '#ATSTART': ext['atstart'] += 1; continue
        m = re.match(r"#AT\((%\w+)(?:,'(.*?)')?(?:,'(.*?)')?\)(.*)$", t)
        if m:
            pr = re.search(r'PRIORITY\((\d+)\)', m.group(4))
            wh = re.search(r'WHERE\((.*)\)$', m.group(4))
            ext['ats'].append({'point': m.group(1), 'sub': m.group(2) or '', 'sig': m.group(3) or '',
                               'priority': pr.group(1) if pr else '', 'where': wh.group(1) if wh else ''})
            continue
        if t.startswith('#IF(UPPER(%ProcedureTemplate)'):
            ext['restrict'] = 'Report procedures only'
    return tpl

def _generated_block():
    """The lines the report-options extension writes into WindowManager.Init,
    exactly as they stand in the template between #AT and #ENDAT."""
    text = _read(TPL)
    a = text.index("#AT(%WindowManagerMethodCodeSection")
    b = text.index('#ENDAT', a)
    return text[a:b + 6]

PREV   = _extract_class('EmfPreviewClass')
INDEX  = _extract_class('EmfTextIndexClass')
QUEUES = _extract_queues()
EQU    = _extract_equates()
TPLX   = _extract_template()
CLWLEN = len(_read(CLW).split('\n'))

sys.path.insert(0, OUT)
from usage import USAGE, PROPS

MISSING, PROBLEMS = [], []

# ---------------------------------------------------------------- helpers
def esc(s): return html.escape(s or '')
def slug(s): return re.sub(r'[^a-z0-9]+', '-', s.lower()).strip('-')

def code(txt, lang='clarion'):
    return '<pre class="code" data-lang="%s"><code>%s</code></pre>' % (lang, esc(txt.strip('\n')))

def usecode(txt):
    return '<pre class="code code--use" data-lang="use"><code>%s</code></pre>' % esc(txt)

def note(kind, title, body):
    return ('<aside class="note note--%s"><p class="note__t">%s</p><div class="note__b">%s</div></aside>'
            % (kind, esc(title), body))

def table(head, rows, cls=''):
    th = ''.join('<th>%s</th>' % h for h in head)
    tr = ''.join('<tr>%s</tr>' % ''.join('<td>%s</td>' % c for c in r) for r in rows)
    return ('<div class="tw"><table class="%s"><thead><tr>%s</tr></thead><tbody>%s</tbody></table></div>'
            % (cls, th, tr))

def kbd(s): return '<kbd>%s</kbd>' % esc(s)

# ---------------------------------------------------------------- volumes
VOLUMES = [
 ('getting-started.html',   'Getting Started',      'Install it and preview a Unicode report'),
 ('programmers-guide.html', "Programmer's Guide",   'How it works, and how to bend it'),
 ('template-guide.html',    'Template Guide',       'Both extensions, every prompt and embed'),
 ('reference.html',         'Reference',            'The classes, the queues and the equates'),
]

#  Published, each volume is its own page on its own address, so a relative
#  filename does not reach the next one.  Cross-volume links are written as
#  these absolute addresses; the local copies in docs/ therefore point at the
#  published set, which is the only thing that works from both places.
PUBLISHED = {
 'getting-started.html':   'https://claude.ai/code/artifact/59352b0d-291b-4ec6-b073-3abb0236cf05',
 'programmers-guide.html': 'https://claude.ai/code/artifact/cec9d673-cbe2-4671-9de0-3b9c3caa0c62',
 'template-guide.html':    'https://claude.ai/code/artifact/407dd75b-3ee8-4b8b-96cb-feb2955df9c6',
 'reference.html':         'https://claude.ai/code/artifact/77beb73a-d230-4f9a-b1f9-28eace8c5d56',
}

def href(target, current):
    return '#' if target == current else PUBLISHED.get(target, target)

#  Palette: the previewer's own COLORREFs.  AccentColor 00EB6F1FH is #1F6FEB
#  (the current-page frame), PageMarkColor 000B9EF5H is #F59E0B (a marked
#  page), HighlightColor 0076F1FFH is #FFF176 (a search hit) - so a note, a
#  warning and a <mark> in these pages look like the thing they describe.
CSS = """
:root{
  --paper:#fbfcfd; --surface:#f2f5f9; --sunken:#e9eef4; --rule:#d5dfe9;
  --ink:#101820; --soft:#4b5b6b; --faint:#7b8a9a;
  --accent:#1b5fcc; --accent-bg:#e6eefb; --accent-rule:#b8cff3;
  --clarion:#166f69; --clarion-bg:#e2f1ef;
  --warn:#9a5b06; --warn-bg:#fbf0dc;
  --hit:#fff176; --hit-ink:#3d3400;
}
@media (prefers-color-scheme:dark){
  :root:not([data-theme="light"]){
    --paper:#0e141b; --surface:#161e27; --sunken:#121a22; --rule:#263340;
    --ink:#e3eaf2; --soft:#9cadbe; --faint:#6e8093;
    --accent:#6ea3f2; --accent-bg:#15263c; --accent-rule:#2a4b74;
    --clarion:#4fb5ab; --clarion-bg:#102a29;
    --warn:#e0aa4a; --warn-bg:#2b2413;
    --hit:#5a4d00; --hit-ink:#fff3a0;
  }
}
:root[data-theme="dark"]{
  --paper:#0e141b; --surface:#161e27; --sunken:#121a22; --rule:#263340;
  --ink:#e3eaf2; --soft:#9cadbe; --faint:#6e8093;
  --accent:#6ea3f2; --accent-bg:#15263c; --accent-rule:#2a4b74;
  --clarion:#4fb5ab; --clarion-bg:#102a29;
  --warn:#e0aa4a; --warn-bg:#2b2413;
  --hit:#5a4d00; --hit-ink:#fff3a0;
}
*{box-sizing:border-box}
body{margin:0; background:var(--paper); color:var(--ink);
  font-family:"IBM Plex Serif",Georgia,serif; font-size:16px; line-height:1.62;
  -webkit-font-smoothing:antialiased}
h1,h2,h3,h4,.ui{font-family:"IBM Plex Sans",system-ui,-apple-system,Segoe UI,sans-serif}
code,pre,.mono,kbd{font-family:"IBM Plex Mono",ui-monospace,Consolas,monospace}
a{color:var(--accent)}
a:focus-visible,button:focus-visible,input:focus-visible{outline:2px solid var(--accent); outline-offset:2px}
.wrap{display:grid; grid-template-columns:270px minmax(0,1fr); align-items:start}
.side{position:sticky; top:0; height:100vh; overflow-y:auto; padding:24px 20px 60px;
  border-right:1px solid var(--rule); background:var(--surface)}
.brand{font-family:"IBM Plex Sans",sans-serif; font-weight:600; font-size:15px; margin:0 0 14px}
.brand b{color:var(--accent)}
.vols{list-style:none; margin:0 0 18px; padding:0 0 16px; display:flex; flex-direction:column; gap:3px;
  border-bottom:1px solid var(--rule)}
.vols a{display:block; padding:7px 10px; border-radius:6px; text-decoration:none;
  font:500 13px/1.35 "IBM Plex Sans",sans-serif; color:var(--soft); border:1px solid transparent}
.vols a:hover{background:var(--sunken); color:var(--ink)}
.vols a.here{background:var(--accent-bg); border-color:var(--accent-rule); color:var(--accent)}
.vols small{display:block; font:400 11px/1.35 "IBM Plex Sans",sans-serif; color:var(--faint); margin-top:2px}
.vols a.here small{color:var(--accent)}
.filter{width:100%; margin:0 0 16px; padding:7px 10px; font:13px/1.4 "IBM Plex Sans",sans-serif;
  color:var(--ink); background:var(--paper); border:1px solid var(--rule); border-radius:6px}
.nav__g{font:600 10.5px/1 "IBM Plex Sans",sans-serif; letter-spacing:.11em; text-transform:uppercase;
  color:var(--faint); margin:18px 0 8px}
.nav__l{list-style:none; margin:0; padding:0; display:flex; flex-direction:column; gap:1px}
.nav__l a{display:block; padding:4px 8px; border-radius:5px; text-decoration:none; color:var(--soft);
  font:400 13.5px/1.45 "IBM Plex Sans",sans-serif}
.nav__l a:hover{background:var(--sunken); color:var(--ink)}
.nav__l a.on{background:var(--accent-bg); color:var(--accent); font-weight:500}
.main{padding:0 0 120px; min-width:0}
.inner{max-width:980px; padding:0 40px}
.hero{padding:52px 40px 30px; border-bottom:1px solid var(--rule);
  background:linear-gradient(180deg,var(--accent-bg),transparent)}
.hero .inner{padding:0}
.eyebrow{font:600 11px/1 "IBM Plex Sans",sans-serif; letter-spacing:.14em; text-transform:uppercase;
  color:var(--accent); margin:0 0 12px}
h1{font-size:37px; line-height:1.1; margin:0 0 10px; letter-spacing:-.015em; text-wrap:balance}
.sub{font-size:17px; color:var(--soft); margin:0 0 18px; max-width:62ch}
.chips{display:flex; flex-wrap:wrap; gap:8px}
.chip{font:500 11.5px/1 "IBM Plex Sans",sans-serif; padding:6px 10px; border-radius:99px;
  border:1px solid var(--rule); background:var(--paper); color:var(--soft)}
.chip b{color:var(--ink); font-weight:600}
h2{font-size:26px; margin:60px 0 6px; letter-spacing:-.01em; scroll-margin-top:18px; text-wrap:balance}
h2 .k{font:600 10.5px/1 "IBM Plex Sans",sans-serif; letter-spacing:.12em; text-transform:uppercase;
  color:var(--accent); display:block; margin-bottom:9px}
h3{font-size:17.5px; margin:36px 0 10px; scroll-margin-top:18px}
h4{font-size:14.5px; margin:24px 0 6px; color:var(--soft); font-weight:600}
p{margin:0 0 14px; max-width:70ch}
ul.b,ol.b{max-width:70ch; padding-left:20px; margin:0 0 16px}
ul.b li,ol.b li{margin:0 0 7px}
.code{background:var(--sunken); border:1px solid var(--rule); border-left:3px solid var(--accent-rule);
  border-radius:0 7px 7px 0; padding:14px 16px; overflow-x:auto; margin:0 0 18px;
  font-size:12.9px; line-height:1.62; position:relative}
.code code{white-space:pre; color:var(--ink)}
.code::after{content:attr(data-lang); position:absolute; top:0; right:0; padding:3px 9px;
  font:500 9.5px/1 "IBM Plex Sans",sans-serif; letter-spacing:.1em; text-transform:uppercase;
  color:var(--faint); background:var(--surface); border-left:1px solid var(--rule);
  border-bottom:1px solid var(--rule); border-radius:0 0 0 6px}
.code--use{margin:7px 0 2px; border-left-color:var(--clarion); background:var(--paper);
  font-size:12.4px; padding:9px 12px}
.code--use::after{content:'Clarion'; color:var(--clarion)}
p code,li code,td code,dd code{background:var(--sunken); border:1px solid var(--rule); border-radius:4px;
  padding:.06em .34em; font-size:.86em}
kbd{font-size:.8em; padding:.1em .45em; border:1px solid var(--rule); border-bottom-width:2px;
  border-radius:4px; background:var(--paper); color:var(--ink); white-space:nowrap}
mark{background:var(--hit); color:var(--hit-ink); padding:0 .15em; border-radius:2px}
.tw{overflow-x:auto; margin:0 0 20px; border:1px solid var(--rule); border-radius:8px; background:var(--paper)}
table{border-collapse:collapse; width:100%; font-size:13.5px; font-family:"IBM Plex Sans",sans-serif}
th{text-align:left; font-weight:600; font-size:11px; letter-spacing:.08em; text-transform:uppercase;
  color:var(--faint); padding:9px 14px; border-bottom:1px solid var(--rule); background:var(--surface)}
td{padding:10px 14px; border-bottom:1px solid var(--rule); vertical-align:top}
tr:last-child td{border-bottom:0}
td.num{font-variant-numeric:tabular-nums; white-space:nowrap}
.fns .fn__n{width:210px; white-space:nowrap}
.fns .fn__n code{font-size:12.6px; color:var(--accent); font-weight:500; background:none; border:0; padding:0}
.fns .fn__s code{font-size:12.4px; color:var(--soft); background:none; border:0; padding:0; white-space:pre-wrap}
.fn__d{margin:5px 0 0; font-family:"IBM Plex Serif",serif; font-size:13.5px; color:var(--ink); max-width:74ch}
.tag{margin-left:7px; font:500 10px/1 "IBM Plex Mono",monospace; color:var(--faint);
  border:1px solid var(--rule); border-radius:4px; padding:2px 4px; vertical-align:1px}
.tag--v{color:var(--clarion); border-color:var(--clarion)}
.eq td:first-child code{color:var(--accent); background:none; border:0; padding:0}
.eq .v{font-variant-numeric:tabular-nums; color:var(--soft)}
.sw{display:inline-block; width:14px; height:14px; border-radius:3px; border:1px solid var(--rule);
  vertical-align:-2px; margin-right:7px}
.note{border:1px solid var(--rule); border-left:3px solid var(--accent); background:var(--surface);
  border-radius:0 7px 7px 0; padding:13px 16px; margin:0 0 18px; max-width:74ch}
.note--warn{border-left-color:var(--warn); background:var(--warn-bg)}
.note--cla{border-left-color:var(--clarion); background:var(--clarion-bg)}
.note__t{font:600 12px/1.3 "IBM Plex Sans",sans-serif; letter-spacing:.03em; margin:0 0 5px;
  text-transform:uppercase; color:var(--soft)}
.note--warn .note__t{color:var(--warn)} .note--cla .note__t{color:var(--clarion)}
.note__b p{margin:0 0 8px; font-size:14.5px} .note__b p:last-child{margin:0}
.stack{display:flex; flex-direction:column; gap:9px; margin:0 0 22px; max-width:640px}
.layer{border:1px solid var(--rule); border-radius:8px; padding:12px 15px; background:var(--surface);
  display:grid; grid-template-columns:128px 1fr; gap:14px; align-items:baseline}
.layer b{font:600 11px/1.4 "IBM Plex Sans",sans-serif; letter-spacing:.06em; text-transform:uppercase; color:var(--accent)}
.layer.cla b{color:var(--clarion)}
.layer p{margin:0; font-size:14px; color:var(--soft); max-width:none}
.arrow{text-align:center; color:var(--faint); font-size:12px; margin:-4px 0}
.keys{display:grid; grid-template-columns:repeat(auto-fill,minmax(280px,1fr)); gap:0 28px; max-width:760px;
  margin:0 0 20px; padding:0; list-style:none}
.keys li{display:grid; grid-template-columns:150px 1fr; gap:10px; padding:7px 0; border-bottom:1px solid var(--rule);
  font-size:14px; align-items:baseline}
.keys li span{font-family:"IBM Plex Sans",sans-serif; color:var(--soft)}
.next{display:grid; grid-template-columns:repeat(auto-fit,minmax(210px,1fr)); gap:12px; margin:26px 0 0}
.next a{display:block; padding:14px 16px; border:1px solid var(--rule); border-radius:9px; background:var(--surface);
  text-decoration:none}
.next a:hover{border-color:var(--accent-rule); background:var(--accent-bg)}
.next b{display:block; font:600 14px/1.3 "IBM Plex Sans",sans-serif; color:var(--accent); margin-bottom:3px}
.next span{font:400 13px/1.45 "IBM Plex Serif",serif; color:var(--soft)}
.hide{display:none !important}
footer{margin-top:70px; padding:22px 40px 0; border-top:1px solid var(--rule); color:var(--faint);
  font:400 13px/1.6 "IBM Plex Sans",sans-serif}
@media (max-width:900px){
  .wrap{grid-template-columns:1fr}
  .side{position:static; height:auto; border-right:0; border-bottom:1px solid var(--rule)}
  .inner,.hero{padding-left:22px; padding-right:22px}
  .layer{grid-template-columns:1fr; gap:4px}
  .keys li{grid-template-columns:1fr; gap:2px}
}
@media (prefers-reduced-motion:reduce){*{animation:none !important; transition:none !important; scroll-behavior:auto !important}}
"""

JS = """
const q = document.getElementById('filter');
if (q) {
  const rows = [...document.querySelectorAll('tr.fn')];
  q.addEventListener('input', () => {
    const t = q.value.trim().toLowerCase();
    rows.forEach(r => r.classList.toggle('hide', t && !r.dataset.k.includes(t)));
    document.querySelectorAll('.tw').forEach(w => {
      const body = w.querySelector('tbody');
      if (!body || !body.querySelector('tr.fn')) return;
      const any = [...body.querySelectorAll('tr')].some(r => !r.classList.contains('hide'));
      const h = w.previousElementSibling;
      w.classList.toggle('hide', !any);
      if (h && (h.tagName === 'H3' || h.tagName === 'P')) h.classList.toggle('hide', !any);
    });
  });
}
/*  Which sidebar entry is lit.  Position, not IntersectionObserver: one click
    crosses several headings at once, they all arrive in one callback, and the
    last one processed wins - which lights the wrong chapter.  */
const links = [...document.querySelectorAll('.nav__l a')];
if (links.length) {
  const byId  = new Map(links.map(a => [a.getAttribute('href').slice(1), a]));
  const marks = [...document.querySelectorAll('h2[id],h3[id]')].filter(h => byId.has(h.id));
  const light = a => links.forEach(l => l.classList.toggle('on', l === a));
  let held = null, holdUntil = 0, queued = false;
  function spy() {
    queued = false;
    if (held) { light(held); return; }
    let cur = marks[0];
    for (const h of marks) { if (h.getBoundingClientRect().top <= 120) cur = h; else break; }
    if (innerHeight + scrollY >= document.documentElement.scrollHeight - 2) cur = marks[marks.length - 1];
    if (cur) light(byId.get(cur.id));
  }
  links.forEach(a => a.addEventListener('click', () => { held = a; holdUntil = performance.now() + 700; light(a); }));
  const later = () => { if (!queued) { queued = true; requestAnimationFrame(spy); } };
  addEventListener('scroll', () => { if (held && performance.now() > holdUntil) held = null; later(); }, {passive: true});
  addEventListener('resize', later);
  if (marks.length) spy();
}
"""

def volnav(current):
    out = ['<ul class="vols">']
    for i, (fn, name, blurb) in enumerate(VOLUMES):
        here = ' class="here"' if fn == current else ''
        out.append('<li><a href="%s"%s>%s. %s<small>%s</small></a></li>'
                   % (href(fn, current), here, i + 1, esc(name), esc(blurb)))
    out.append('</ul>')
    return ''.join(out)

def headings(body):
    """Every anchored id in the body, with the words actually printed above it."""
    out = {}
    for m in re.finditer(r'<h([23]) id="([^"]+)"[^>]*>(.*?)</h\1>', body, re.S):
        txt = re.sub(r'<span class="k">.*?</span>', '', m.group(3), flags=re.S)
        out[m.group(2)] = re.sub(r"\s+", ' ', re.sub(r'<[^>]+>', '', txt)).strip()
    return out

def secnav(groups, titles):
    #  The sidebar prints the heading itself, never a second wording of it.
    out = []
    for group, items in groups:
        if group: out.append('<p class="nav__g">%s</p>' % esc(group))
        out.append('<ul class="nav__l">')
        for aid, label in items:
            out.append('<li><a href="#%s">%s</a></li>' % (aid, esc(html.unescape(titles.get(aid, label)))))
        out.append('</ul>')
    return ''.join(out)

def nextcards(names):
    cards = []
    for h in names:
        for fn, name, blurb in VOLUMES:
            if fn == h:
                cards.append('<a href="%s"><b>%s &rarr;</b><span>%s</span></a>'
                             % (PUBLISHED.get(fn, fn), esc(name), esc(blurb)))
    return '<div class="next">%s</div>' % ''.join(cards)

def page(filename, title, eyebrow, heading, sub, chips, groups, body, showfilter=False):
    titles = headings(body)
    linked = [aid for _, items in groups for aid, _ in items]
    for aid in linked:
        if aid not in titles:
            PROBLEMS.append('%s: the nav points at #%s, which is not a heading' % (filename, aid))
    for aid in titles:
        if aid not in linked:
            PROBLEMS.append('%s: heading #%s (%s) is in no nav' % (filename, aid, titles[aid]))
    nav = volnav(filename) + \
          ('<label class="ui" style="font-size:11px;color:var(--faint);letter-spacing:.08em;'
           'text-transform:uppercase" for="filter">Filter</label>'
           '<input id="filter" class="filter" type="search" placeholder="Find, ZoomMode, %EmfPrv&hellip;" '
           'autocomplete="off">' if showfilter else '') + secnav(groups, titles)
    chiphtml = ''.join('<span class="chip">%s</span>' % c for c in chips)
    doc = ('<title>%s</title>\n'
           '<meta name="viewport" content="width=device-width,initial-scale=1">\n'
           '<link rel="preconnect" href="https://fonts.googleapis.com">\n'
           '<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>\n'
           '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?'
           'family=IBM+Plex+Mono:wght@400;500&family=IBM+Plex+Sans:wght@400;500;600&'
           'family=IBM+Plex+Serif:wght@400;600&display=swap">\n'
           '<style>%s</style>\n'
           '<div class="wrap">\n<nav class="side">\n'
           '  <p class="brand"><b>EmfPreview</b> for Clarion 12 Unicode</p>\n%s\n</nav>\n'
           '<main class="main">\n'
           '  <header class="hero"><div class="inner">\n'
           '    <p class="eyebrow">%s</p>\n    <h1>%s</h1>\n    <p class="sub">%s</p>\n'
           '    <div class="chips">%s</div>\n'
           '  </div></header>\n  <div class="inner">%s\n'
           '    <footer>EmfPreview &mdash; four volumes. The reference is generated from '
           '<code>EmfPreview.inc</code> and <code>EmfPreview.tpl</code>, so its signatures, defaults and '
           'template symbols are the ones in the build. Clarion 12 Unicode only.</footer>\n'
           '  </div>\n</main>\n</div>\n<script>%s</script>\n'
           % (esc(title), CSS, nav, esc(eyebrow), esc(heading), sub, chiphtml, body, JS))
    io.open(os.path.join(OUT, filename), 'w', encoding='utf-8', newline='\n').write(doc)
    return len(doc)

# =====================================================================
#  1  GETTING STARTED
# =====================================================================
S_HELLO = """
  PROGRAM
  INCLUDE('KEYCODES.CLW'),ONCE
  INCLUDE('EQUATES.CLW'),ONCE
  INCLUDE('ERRORS.CLW'),ONCE
  INCLUDE('ABERROR.INC'),ONCE
  INCLUDE('ABREPORT.INC'),ONCE
  INCLUDE('EmfPreview.INC'),ONCE
  MAP
  END

GlobalErrors  ErrorClass
PgQ           PrintPreviewFileQueue         ! the report's page files land here
Prev          EmfPreviewClass
i             LONG
RowNo         LONG
RowName       USTRING(80)

Report REPORT,AT(500,1000,7500,9000),PRE(RPT),FONT('Segoe UI',10),THOUS, |
         PREVIEW(PgQ),UNICODE                ! UNICODE: wide text, .emf pages
         HEADER,AT(500,250,7500,700)
           STRING(U'Customers  Ω Ж 中 😀'),AT(0,0,7500,300),FONT(,14,,FONT:bold),CENTER
         END
Detail   DETAIL,AT(,,7500,300)
           STRING(@n5),AT(0,20,500,250),USE(RowNo),RIGHT
           STRING(@s80),AT(700,20,6000,250),USE(RowName)
         END
       END

  CODE
  GlobalErrors.Init()
  OPEN(Report)
  LOOP i = 1 TO 240
    RowNo   = i
    RowName = CHOOSE((i % 3) + 1, U'Ana Müller', U'Дмитрий Иванов', U'山田 太郎')
    PRINT(RPT:Detail)
  END
  ENDPAGE(Report)                            ! PgQ now holds one .emf per page

  Prev.Init(PgQ)
  Prev.Errors &= GlobalErrors
  Prev.Title = 'Customers - preview'
  IF Prev.Display()                          ! TRUE when the user chose Print
    Report{PROP:FlushPreview} = TRUE
  END
  Prev.Kill()
  CLOSE(Report)
  GlobalErrors.Kill()
"""

def build_getting_started():
    B = []; add = B.append

    add('''<h2 id="what"><span class="k">Start</span>What this is</h2>
<p>EmfPreview replaces the ABC <code>PrintPreviewClass</code> in a Clarion 12 Unicode application. The
report engine is untouched: it still prints to <code>PREVIEW</code> page files, and the previewer still
returns <code>TRUE</code> when the user wants the pages sent to the printer. What changes is the window
&mdash; a thumbnail sidebar, full-text search over every page with the hits <mark>highlighted on the
page</mark>, marker-pen text marks, page marks, zoom and fit modes, a mouse wheel that works, and
printing only the marked pages or the pages with their marks baked in.</p>
<div class="stack">
  <div class="layer cla"><b>Template</b><p>One global extension swaps the previewer class for every report; an optional per-report extension sets the title, overrides options, or opts a report out.</p></div>
  <div class="arrow">&#8595;&nbsp; sets options on</div>
  <div class="layer cla"><b>EmfPreviewClass</b><p>Derived from <code>PrintPreviewClass</code>, so the report template's <code>Previewer</code> object, <code>Display</code>, <code>Init</code> and <code>Kill</code> keep their meaning. Hand-coded programs use it directly.</p></div>
  <div class="arrow">&#8595;&nbsp; is fed by</div>
  <div class="layer"><b>EmfTextIndexClass</b><p>Runs the shipped <code>WMFDocumentParser</code> over the page metafiles and keeps every text item with its page rectangle. Reusable on its own.</p></div>
</div>''')
    add(note('warn', 'Clarion 12 Unicode only',
        '<p>The class relies on the Unicode report engine: <code>REPORT,&hellip;,UNICODE</code> writing '
        '<code>.emf</code> pages, <code>USTRING</code>, and the <code>IReportGeneratorW</code> wide lane of '
        '<code>ABWMFPAR</code>. None of that exists in Clarion 11 or the ANSI Clarion 12, and the include '
        'file refuses to compile there: <code>EmfPreview_requires_Clarion_12_Unicode</code> is the first '
        'error you would see.</p>'))

    add('<h2 id="install"><span class="k">Start</span>Installing</h2>')
    add('<p>Run the installer from the repository folder. It copies three files and registers the template chain:</p>')
    add(code('powershell -ExecutionPolicy Bypass -File install.ps1                      # C:\\Clarion12unicode\n'
             'powershell -ExecutionPolicy Bypass -File install.ps1 -ClarionRoot D:\\C12U   # somewhere else', 'shell'))
    add(code('src\\EmfPreview.inc   ->  <Clarion>\\accessory\\libsrc\\win\n'
             'src\\EmfPreview.clw   ->  <Clarion>\\accessory\\libsrc\\win\n'
             'src\\EmfPreview.tpl   ->  <Clarion>\\accessory\\template\\win      then  ClarionCL -tr EmfPreview.tpl', 'files'))
    add(note('warn', 'Restart the IDE if it was open',
        '<p>The template registry is read at start-up. An IDE that was running during the install does not '
        'list <b>EMF Unicode Previewer</b> under Global Extensions until it is restarted, which looks exactly '
        'like the install not working.</p>'))
    add('<p>Nothing to ship: the class is linked into the EXE (or into each DLL that uses it). There is no runtime file.</p>')

    add('<h2 id="hello"><span class="k">Start</span>The smallest preview, by hand</h2>')
    add('<p>No templates. A Unicode report, 240 rows, and the previewer instead of the stock one:</p>')
    add(code(S_HELLO))
    add(note('cla', 'Three lines that matter',
        '<p><code>PREVIEW(PgQ),UNICODE</code> on the REPORT. Without <code>UNICODE</code> the pages are '
        'placeable <code>.wmf</code> files &mdash; still previewed and searched, but through the ANSI text '
        'lane, so <code>山田</code> in a name is lost to the code page.</p>'
        '<p><code>Prev.Init(PgQ)</code> hands over the page queue; <code>Prev.Errors &amp;= GlobalErrors</code> '
        'is what the parser reports through.</p>'
        '<p><code>IF Prev.Display()</code> &mdash; the same contract as ABC: <code>TRUE</code> means print, '
        'and <code>PROP:FlushPreview</code> sends the pages. <code>PagesToPrint</code> is already filled when '
        'the user pressed <b>Print marked</b>.</p>'))

    add('<h2 id="first-template"><span class="k">Start</span>The same thing from AppGen</h2>')
    add('''<ol class="b">
<li>Open the application, <b>Global Properties &rarr; Extensions &rarr; Insert</b>, pick
<b>EMF Unicode Previewer &ndash; Global (activate)</b>. Leave <i>Replace the previewer in every report
procedure</i> ticked.</li>
<li>Give each report the <b>Unicode</b> attribute in the report designer (the REPORT structure gets
<code>,UNICODE</code>). Classic reports keep working; they just lose non-ANSI characters in the text
index.</li>
<li>Generate and compile. Every report procedure's <code>Previewer</code> object is now an
<code>EmfPreviewClass</code> &mdash; the extension sets the global <i>Print Previewer</i> class.</li>
<li>Optional, per report: <b>Extensions &rarr; EMF Unicode Previewer &ndash; Report options</b> for a
window title, local overrides, or to fall back to the classic window for that one report.</li>
</ol>''')
    add(note('cla', 'What the swap really is',
        '<p>The extension sets <b>Global Properties &rarr; Classes &rarr; Report &rarr; Print Previewer</b> to '
        '<code>EmfPreviewClass</code>, and Clarion stores that value in the .app. That is why removing the '
        'template has a procedure of its own &mdash; the <a href="%s#removing">Template Guide</a> covers it, '
        'and so does the <b>Removing</b> tab on the extension itself.</p>' % PUBLISHED.get('template-guide.html', 'template-guide.html')))

    add('<h2 id="demos"><span class="k">Start</span>The tests</h2>')
    add('<p>Two programs in the repository exercise the class, and both are useful as worked examples.</p>')
    add(table(['Folder', 'What it is'], [
      ['<code>test\\EmfRptTest</code>',
       'A hand-coded probe. <code>EmfRptTest.exe</code> prints an 8-page Unicode report (mixed scripts and '
       'emoji), dumps the metafile headers and the text index to <code>pages\\textindex.txt</code>, then '
       'opens the previewer. <code>EmfRptTest.exe autotest</code> also drives it through search, marks, '
       'zoom, click-mark and the wheel hook by timer and writes screenshots to <code>shots\\</code>.'],
      ['<code>testapp\\EmfPrvTest</code>',
       'An AppGen application built headlessly: a <code>.txd</code> dictionary and a <code>.txa</code> with '
       'one ABC Report procedure carrying both extensions. <code>ClarionCL -di</code>, <code>-ai</code>, '
       '<code>-ag</code>, then MSBuild. <code>removal.txa</code> and <code>disable.txa</code> are the '
       'regression tests for taking the template out again.'],
    ]))
    add('<p>Build either with the 32-bit MSBuild and the Clarion bin path:</p>')
    add(code('C:\\Windows\\Microsoft.NET\\Framework\\v4.0.30319\\MSBuild.exe EmfRptTest.cwproj '
             '/p:ClarionBinPath=C:\\Clarion12unicode\\bin /p:Configuration=Debug', 'shell'))

    add('<h2 id="next"><span class="k">Start</span>Where to go next</h2>')
    add(nextcards(['programmers-guide.html', 'template-guide.html', 'reference.html']))

    return page('getting-started.html',
                'EmfPreview Getting Started',
                'Volume 1', 'Getting Started',
                'Install it, preview a Unicode report by hand, then do the same thing from AppGen in four '
                'steps. Twenty minutes, Clarion 12 Unicode assumed.',
                ['<b>3</b> files to install', '<b>0</b> runtime files', '<b>2</b> test programs'],
                [('This volume', [('what', 'What this is'), ('install', 'Installing'),
                                  ('hello', 'By hand'), ('first-template', 'From AppGen'),
                                  ('demos', 'The tests'), ('next', 'Where to go next')])],
                ''.join(B))


# =====================================================================
#  2  PROGRAMMER'S GUIDE
# =====================================================================
S_DERIVE = """
InvoicePreview CLASS(EmfPreviewClass),TYPE
Open             PROCEDURE(),VIRTUAL
TakeWheel        PROCEDURE(LONG Delta, LONG Keys, LONG XPix, LONG YPix),LONG,VIRTUAL
               END

InvoicePreview.Open PROCEDURE()
  CODE
  PARENT.Open()                                ! builds the window, hooks the wheel
  SELF.HintText = ' F3 jumps to the next invoice number'
  SELF.SearchText = U'Invoice No.'
  POST(EVENT:Accepted, SELF.FeqFind)           ! search as soon as the window is up

InvoicePreview.TakeWheel PROCEDURE(LONG Delta, LONG Keys, LONG XPix, LONG YPix)
  CODE
  IF BAND(Keys, MK_SHIFT)                      ! Shift+wheel flips pages
    SELF.GotoPage(SELF.CurrentPage + CHOOSE(Delta > 0, -1, 1))
    RETURN 1
  END
  RETURN PARENT.TakeWheel(Delta, Keys, XPix, YPix)
"""

S_INDEX_ONLY = """
Idx   EmfTextIndexClass
Out   ASCII,NAME(OutName)
Line  STRING(1024)
i     LONG

  CODE
  Idx.Init(GlobalErrors)
  IF Idx.Build(PgQ) <> Level:Benign THEN RETURN.
  CREATE(Out); OPEN(Out)
  LOOP i = 1 TO RECORDS(Idx.Texts)
    GET(Idx.Texts, i)
    Line = TOANSI(Idx.Texts.Text, 0FDE9h)      ! UTF-8: assign FIRST, then concatenate
    Out.Line = Idx.Texts.PageNo & '<9>' & Idx.Texts.Left & '<9>' & Idx.Texts.Top & '<9>' & CLIP(Line)
    ADD(Out)
  END
  CLOSE(Out)
"""

S_INI = """
INIMgr  INIClass
  CODE
  INIMgr.Init('.\\MyApp.INI')
  Prev.SetINIManager(INIMgr)                   ! [_EmfPreview_]: window, Zoom, Sidebar
  IF Prev.Display() THEN Report{PROP:FlushPreview} = TRUE.
"""

S_MARKED = """
!  after Display returned TRUE:
!    Print         -> PagesToPrint as the ABC dialog left it (or all)
!    Print marked  -> PagesToPrint = MarkedPageList(), e.g. '1,3,7-9'
!  and, when PrintMarks is on and text marks exist, PrepareMarkedPrint has
!  swapped every marked page's file in ImageQueue for a twin with the marks
!  drawn - the report engine prints and deletes the twin like any page file.
IF Prev.Display()
  Report{PROP:FlushPreview} = TRUE
END
"""

S_COORDS = """
!  page mils -> IMAGE pixels             IMAGE pixels -> page mils
Px = Mils * SELF.PxPerMil                Mils = (Px + ScrollPos) / SELF.PxPerMil

!  what the parser delivers for an EMF page, and what the index keeps
Left = F.Pos.Left - CurBoxL - CurOffX    ! CurOffX = (frame - printable) / 2, ~158 mils on a laser
"""

def build_programmers_guide():
    B = []; add = B.append

    add('''<h2 id="model"><span class="k">Concepts</span>Pages, twins and the text index</h2>
<p>A Clarion report printed to <code>PREVIEW</code> leaves one metafile per page in a
<code>PrintPreviewFileQueue</code>. With <code>REPORT,&hellip;,UNICODE</code> those files are enhanced
metafiles (<code>.emf</code>, 600 dpi, one <code>EMR_EXTTEXTOUTW</code> per string); a classic report
writes placeable <code>.wmf</code> files. EmfPreview never draws a page itself. It does three things
with those files:</p>
<ol class="b">
<li><b>Index them.</b> <code>EmfTextIndexClass.Build</code> runs the shipped
<code>WMFDocumentParser</code> over the queue with itself registered as both the narrow
<code>IReportGenerator</code> and the wide <code>IReportGeneratorW</code> target. Every STRING, TEXT line,
CHECK, RADIO and GROUP caption arrives as a <code>USTRING</code> with its rectangle in 1/1000 inch and goes
into <code>Texts</code>; every page gets a row in <code>Pages</code> with its frame and offsets.</li>
<li><b>Render a twin.</b> To show a page, <code>RenderPage</code> plays the original metafile into a new
EMF whose frame is exactly the zoomed display size, then draws the hits and marks over it with
<code>SetROP2(R2_MASKPEN)</code> &mdash; the marker-pen effect that keeps black text black. The IMAGE
control shows the twin, not the original.</li>
<li><b>Map the mouse.</b> Because the twin's natural size equals the display size, the IMAGE's scroll
positions are pixels and a click converts to page mils with one division. <code>ItemAt</code> then finds
the text item under the point.</li>
</ol>''')
    add(code(S_COORDS))
    add('<h3 id="units">Units and coordinate spaces</h3>')
    add(table(['Space', 'Unit', 'Who uses it'], [
      ['Report / page', '<b>mils</b> &mdash; 1/1000 inch from the page frame origin',
       '<code>EmfTextQueue</code>, <code>EmfMarkQueue</code>, <code>ScrollTo</code>, <code>ItemAt</code>, '
       '<code>MeasureText</code>'],
      ['Metafile header', '0.01 mm (<code>rclFrame</code>); device pixels at the recording dpi',
       '<code>ProbePage</code> converts to mils'],
      ['Display', 'IMAGE pixels; <code>PxPerMil</code> converts',
       '<code>Layout</code>, <code>ShowPage</code>, <code>ToggleMarkAt</code>'],
      ['Window', 'pixels from the client origin (<code>PROP:Pixels</code> is on)',
       '<code>MOUSEX()</code>, <code>SETPOSITION</code>, the wheel hook'],
    ]))
    add(note('warn', 'The parser adds an offset that GDI playback does not',
        '<p><code>WMFParser</code> reports EMF text positions including the printer&rsquo;s physical offset '
        '&mdash; <code>(frame &minus; printable) / 2</code>, about 158 mils on a typical laser &mdash; while '
        '<code>PlayEnhMetaFile</code> maps the frame as-is. <code>ProbePage</code> reads the offset from the '
        'header (<code>szlDevice</code>, <code>szlMillimeters</code>, <code>rclFrame</code>, with the same '
        'dpi snapping the parser uses) and <code>AddText</code> subtracts it, so index rectangles land on the '
        'displayed text. Do the same in any code that overlays parser coordinates on a played page.</p>'))

    add('<h3 id="hits-marks">Hits, marks and page marks</h3>')
    add('''<p>Three kinds of state, all kept on the previewer for the length of one <code>Display</code>:</p>
<ul class="b">
<li><b>Hits</b> &mdash; the result of the last <code>Find</code>. One <code>EmfMarkQueue</code> row per
match with the span (<code>Start</code>, <code>Length</code> in UTF-16 units) and its display rectangle.
<code>CurHit</code> points at the framed one; <code>Pages.Matches</code> counts per page for the
thumbnail labels. Capped at 5000.</li>
<li><b>Marks</b> &mdash; the user's. A left click on a text line (<code>ClickMarks</code>) marks the whole
item; <b>Mark hits</b> copies every hit as a mark. Painted in <code>MarkColor</code>, and printed when
<code>PrintMarks</code> is on.</li>
<li><b>Page marks</b> &mdash; <code>Pages.Marked</code>. <kbd>Ctrl+M</kbd>, the toolbar button, or a
right click on a thumbnail. <code>MarkedPageList</code> turns them into <code>'1,3,7-9'</code>, which is
what <b>Print marked</b> hands to the ABC print loop as <code>PagesToPrint</code>.</li>
</ul>''')

    add('<h2 id="howto"><span class="k">How to</span>Recipes</h2>')
    add('<h3 id="derive">Derive the class</h3>')
    add('''<p>Every handler is <code>VIRTUAL</code>. <code>Open</code> runs after the window is built and the
wheel hook installed; the <code>Feq&hellip;</code> members name every toolbar control so a derived class
can drive them. Call <code>PARENT</code> in anything you override &mdash; the base handlers are where
the ABC previewer's own logic is deliberately <i>not</i> run.</p>''')
    add(code(S_DERIVE))
    add('<h3 id="remember">Remember the window, zoom and sidebar</h3>')
    add(code(S_INI))
    add('<p>Nothing is remembered without an INI manager. With one, the section is <code>[_EmfPreview_]</code>.</p>')
    add('<h3 id="print-marked">Print the marked pages, or pages with their marks</h3>')
    add(code(S_MARKED))
    add('<h3 id="classic">Fall back to the classic window</h3>')
    add('''<p>Set <code>ClassicMode</code> before <code>Display</code> and the object behaves exactly like its
parent &mdash; every override starts with <code>IF SELF.ClassicMode THEN RETURN PARENT.&hellip;</code>.
The per-report template extension does this when <i>Use the EMF previewer</i> is unticked.</p>''')
    add(code("Prev.ClassicMode = TRUE                       ! stock ABC preview window for this report"))
    add('<h3 id="index-only">Use the text index without the window</h3>')
    add('<p><code>EmfTextIndexClass</code> is independent. Anything that wants the text of a printed report with its position &mdash; an audit dump, a table-of-contents builder, a &ldquo;which page has this invoice&rdquo; lookup &mdash; can use it alone:</p>')
    add(code(S_INDEX_ONLY))
    add('<h3 id="colours">Colours</h3>')
    add('''<p>All seven are <code>COLORREF</code> values, <code>00BBGGRR</code>, the Clarion way round. The
defaults are chosen so a hit reads as <mark>yellow marker</mark> on white paper and a mark as a light
sky, and so the two thumbnail frames &mdash; blue for the current page, amber for a marked one &mdash;
cannot be confused. Set them before <code>Display</code>; the template exposes every one on its
<b>Colors</b> tab.</p>''')

    add('<h2 id="keys"><span class="k">Using it</span>Keyboard and mouse</h2>')
    add('''<ul class="keys">
<li>%s / %s<span>focus the search box / find next</span></li>
<li>%s / %s<span>next / previous hit, wrapping</span></li>
<li>%s %s<span>previous / next page</span></li>
<li>%s %s<span>first / last page</span></li>
<li>%s %s, wheel<span>scroll; flips pages at the top and bottom edges</span></li>
<li>%s+wheel, %s %s<span>zoom in / out through the fixed stops</span></li>
<li>double click<span>150 %% from a fit mode, fit width from a percent</span></li>
<li>left click on a line<span>toggle a text mark (<code>ClickMarks</code>)</span></li>
<li>right click<span>menu: mark text, mark page, zoom, fit, mark all hits, clear marks</span></li>
<li>%s<span>mark / unmark the current page</span></li>
<li>wheel over the sidebar<span>scroll the thumbnails</span></li>
<li>right click a thumbnail<span>mark / unmark that page</span></li>
<li>%s / %s<span>print / close without printing</span></li>
</ul>''' % (kbd('Ctrl+F'), kbd('Enter'), kbd('F3'), kbd('Shift+F3'), kbd('Ctrl+PgUp'), kbd('Ctrl+PgDn'),
            kbd('Ctrl+Home'), kbd('Ctrl+End'), kbd('PgUp'), kbd('PgDn'), kbd('Ctrl'), kbd('Ctrl +'),
            kbd('Ctrl −'), kbd('Ctrl+M'), kbd('Ctrl+P'), kbd('Esc')))

    add('<h2 id="notes"><span class="k">Notes</span>What Clarion 12 Unicode does, and does not, do</h2>')
    add('''<p>Behaviour that belongs to the compiler, the runtime and the report engine rather than to this
class &mdash; each one cost a debugging session, and each one shapes the code you will read in
<code>EmfPreview.clw</code>.</p>''')
    add('<h3 id="n-engine">The report engine</h3>')
    add('''<ul class="b">
<li><code>REPORT,&hellip;,UNICODE</code> (the <i>Unicode</i> property in the report designer) prints wide
text end to end and writes <code>PREVIEW</code> pages as <b>enhanced metafiles</b>. The probe confirmed
8 pages of 600-dpi EMF with the <code>' EMF'</code> signature and about 3&nbsp;000 records each.
Non-UNICODE reports still write placeable <code>.wmf</code>.</li>
<li>Colour emoji are recorded as <code>EMR_ALPHABLEND</code> 32-bpp stamps <i>in addition to</i> the
UTF-16 text run, so text search still finds them.</li>
<li>The shipped <code>WMFDocumentParser</code> has a complete EMF lane. Register a wide target with
<code>SetWideGenerator(IReportGeneratorW)</code> and every text item arrives as a <code>USTRING</code>;
the narrow <code>IReportGenerator</code> must still be supplied to <code>Init</code>.
<code>WideRun</code> on the index tells you which lane delivered.</li>
<li>Parser coordinates for EMF pages include the printer's physical offset; GDI playback does not add it.
See the note under <a href="#units">Units</a>.</li>
</ul>''')
    add('<h3 id="n-image">The IMAGE control</h3>')
    add('''<ul class="b">
<li>An IMAGE shows a metafile at 96 dpi of its frame, and its <code>HVSCROLL</code> range is the
picture's natural size. Rendering the twin with the display size as its frame is what makes scroll
positions pixels.</li>
<li>The scroll bars only take effect once an image is loaded, and the range is only recomputed when the
flags change &mdash; <code>ShowPage</code> switches <code>PROP:HScroll</code> / <code>PROP:VScroll</code>
off and on again after every load, or a zoom change keeps the old range.</li>
<li>The control applies a <code>WM_VSCROLL</code> / <code>SB_THUMBPOSITION</code> lazily: ask for a
position and <code>GetScrollInfo</code> still reports the old one for a while. <code>ScrollLines</code>
remembers what it asked for (<code>PendV</code>, <code>PendFromV</code>) and continues from there when the
control has not caught up, or two wheel notches in one tick land on the same spot.</li>
</ul>''')
    add('<h3 id="n-wheel">The mouse wheel</h3>')
    add('''<p>Windows sends <code>WM_MOUSEWHEEL</code> to the control under the cursor (or with focus), and
Clarion's control procedures swallow it &mdash; subclassing the frame with <code>PROP:WndProc</code>
never sees the message. EmfPreview installs a per-thread <code>WH_GETMESSAGE</code> hook when the window
opens (<code>Open</code>), routes wheel messages for any control of a registered preview window to that
window's <code>TakeWheel</code>, and rewrites the message to <code>WM_NULL</code> when handled. Two
details: test <code>BAND(wParam, PM_REMOVE)</code> rather than equality, because <code>PeekMessage</code>
adds <code>PM_QS_*</code> bits; and the registry of open windows is plain module data behind a critical
section &mdash; see the next point for why.</p>''')
    add('<h3 id="n-runtime">The runtime and the compiler</h3>')
    add('''<ul class="b">
<li><b><code>THREAD</code>ed module-level data in a class module crashes at start-up</b> in this build.
The hook registry is a plain queue guarded by <code>NewCriticalSection()</code>.</li>
<li>A class declared with <code>DLL(_xDllMode_)</code> whose define is missing from the project
<b>GPFs on first use</b> (the VMT is garbage). EmfPreview therefore links unconditionally &mdash;
<code>MODULE('EmfPreview.CLW'),LINK('EmfPreview.CLW')</code>, no DLL-mode parameters &mdash; and each
module of a multi-DLL suite carries its own copy. An application that still references
<code>EmfPreviewClass</code> after the template is removed compiles and runs.</li>
<li><code>TOANSI(u, 0FDE9h)</code> (UTF-8) must be <b>assigned to a STRING first</b>. Inside a
<code>&amp;</code> concatenation the expression is evaluated wide and narrowed through the ANSI code
page, and the UTF-8 is gone.</li>
<li><code>UPPER</code> and <code>INSTRING</code> are Unicode-aware on <code>USTRING</code>, which is
what makes the case-insensitive search a one-liner.</li>
<li>The compiler rejects LF-only source files. Keep <code>.inc</code>, <code>.clw</code> and
<code>.tpl</code> as CRLF; <code>test\\crlf.py</code> normalises them after a scripted edit.</li>
<li>Highlights use <code>SetROP2(R2_MASKPEN)</code> and a solid brush: the colour is ANDed over the
page, so black stays black and white becomes the marker colour.</li>
</ul>''')
    add('<h3 id="n-appgen">AppGen and the template</h3>')
    add('''<ul class="b">
<li><code>#SET</code> on another template's prompt &mdash; here <code>%PrintPreviewType</code>, the
ABC global <i>Print Previewer</i> class &mdash; is <b>persisted into the .app</b> by generation. The
extension therefore puts the value back when it is disabled, and its <b>Removing</b> tab explains the
order of operations.</li>
<li>Hand-written TXAs: the header order is <code>VERSION</code>, <code>TODO</code>,
<code>DICTIONARY</code>, <code>PROCEDURE</code>; <code>[ADDITION]</code> blocks have no
<code>[END]</code>; supply <code>%ClassItem</code> / <code>%ClassLines</code> for derived objects; progress
controls need <code>#ORIG(&hellip;)</code>. A TXA that gets one of these wrong imports without an error
and silently drops the section.</li>
</ul>''')

    add('<h2 id="limits"><span class="k">Notes</span>Known limits</h2>')
    add('''<ul class="b">
<li>A hit's rectangle is measured with the item's font on the screen DC
(<code>GetTextExtentPoint32W</code>); exotic fonts or justified TEXT controls can be a few pixels off.</li>
<li>Whole-word search treats only spaces as word boundaries.</li>
<li>Text marks live for the preview session; nothing persists them (the INI manager keeps window, zoom
and sidebar only).</li>
<li>Search runs over the report's own pages; export still goes through the ABC target selector
(<b>Save as</b>).</li>
<li>Index text is capped at 260 UTF-16 units per item, and a search at 5&nbsp;000 hits.</li>
</ul>''')

    add('<h2 id="next2"><span class="k">Guide</span>Where to go next</h2>')
    add(nextcards(['template-guide.html', 'reference.html', 'getting-started.html']))

    return page('programmers-guide.html',
                "EmfPreview Programmer's Guide",
                'Volume 2', "Programmer's Guide",
                'How the pages become a searchable index and a highlighted twin, how to derive and drive '
                'the class, and what the Clarion 12 Unicode engine does that the code has to work around.',
                ['<b>%d</b> lines of class source' % CLWLEN, '<b>4</b> coordinate spaces',
                 '<b>%d</b> engine and runtime notes' % 13],
                [('Concepts', [('model', 'Pages, twins and the text index'), ('units', 'Units'),
                               ('hits-marks', 'Hits, marks and page marks')]),
                 ('How to', [('howto', 'Recipes'), ('derive', 'Derive the class'),
                             ('remember', 'Remember the window'), ('print-marked', 'Print marked pages'),
                             ('classic', 'Classic fallback'), ('index-only', 'Index without the window'),
                             ('colours', 'Colours')]),
                 ('Using it', [('keys', 'Keyboard and mouse')]),
                 ('Notes', [('notes', 'Clarion 12 Unicode notes'), ('n-engine', 'The report engine'),
                            ('n-image', 'The IMAGE control'), ('n-wheel', 'The mouse wheel'),
                            ('n-runtime', 'Runtime and compiler'), ('n-appgen', 'AppGen and the template'),
                            ('limits', 'Known limits')]),
                 ('', [('next2', 'Where to go next')])],
                ''.join(B))


# =====================================================================
#  3  TEMPLATE GUIDE
# =====================================================================
S_GEN_SAMPLE = """
!  ThisWindow.Init, priority 8490 - what the report-options extension writes
!  for a report whose global prompts are at their defaults:
! EMF Unicode Previewer options
Previewer.ShowSidebar = 1
Previewer.SidebarWidth = 190
Previewer.InitialZoom = EmfPrv:Zoom:FitWidth
Previewer.ClickMarks = 1
Previewer.PrintMarks = 1
Previewer.SearchMatchCase = 0
Previewer.WheelLines = 3
Previewer.HighlightColor = 7795199
Previewer.MarkColor = 16770725
Previewer.CurrentColor = 30975
Previewer.PageMarkColor = 761589
Previewer.AccentColor = 15429407
Previewer.PaperShadow = 5854802
Previewer.SidebarColor = 16118254
Previewer.Title = 'Customers - EMF Unicode previewer'

!  ... and with "Use the EMF previewer for this report" unticked:
! EMF Unicode Previewer: this report uses the classic ABC preview window
Previewer.ClassicMode = True
"""

S_SWAP = """
#ATSTART
  #IF(NOT %EmfPrvDisable AND %EmfPrvReplaceAll)
    #SET(%PrintPreviewType,'EmfPreviewClass')
  #ELSIF(%PrintPreviewType = 'EmfPreviewClass')
    #SET(%PrintPreviewType,'PrintPreviewClass')
  #ENDIF
#ENDAT
"""

def prompt_rows(prompts):
    rows = []
    for p in prompts:
        d = esc(p['default'])
        if p.get('swatch'):
            d = '<span class="sw" style="background:%s"></span>%s <span class="mono" style="color:var(--faint)">%s</span>' % (
                p['swatch'], d, p['swatch'])
        rows.append(['<b>%s</b>' % esc(p['label']), esc(p['kind']), '<code>%s</code>' % esc(p['symbol']), d,
                     esc(p['enable']) if p['enable'] else '&mdash;'])
    return rows

def build_template_guide():
    B = []; add = B.append
    G = TPLX['extensions'][0]; R = TPLX['extensions'][1]

    add('<h2 id="two"><span class="k">Templates</span>The two extensions</h2>')
    add('<p>One template file, <code>EmfPreview.tpl</code>, family <code>%s</code>: <i>%s</i>.</p>' % (esc(TPLX['family']), esc(TPLX['desc'])))
    add(table(['Extension', 'Put it on', 'What it does'], [
      ['<code>%s</code><br><span style="color:var(--soft)">%s</span>' % (esc(G['name']), esc(G['desc'])),
       'the application, once',
       'includes <code>EmfPreview.INC</code>, sets the global <i>Print Previewer</i> class to '
       '<code>EmfPreviewClass</code>, and holds the defaults every report inherits &mdash; sidebar, zoom, '
       'marks, wheel, colours'],
      ['<code>%s</code><br><span style="color:var(--soft)">%s</span>' % (esc(R['name']), esc(R['desc'])),
       'a Report procedure (%s; requires <code>%s</code>)' % (esc(R['restrict'] or 'any procedure'), esc(R['req'])),
       'a window title for this report, local overrides of the global options, or <i>Use</i> unticked to '
       'fall back to the classic ABC window'],
    ]))
    add('''<p>Nothing needs the second extension. With only the global one every report procedure gets the
EMF previewer with the global settings. Add the report extension where a report wants a title of its own,
different settings, or the classic window.</p>''')

    add('<h2 id="global"><span class="k">Templates</span>The global extension</h2>')
    add('<p>Three tabs. Every prompt and its default, read out of the template:</p>')
    for tab in G['tabs']:
        if not tab['prompts']: continue
        add('<h3 id="g-%s">%s tab</h3>' % (slug(tab['name']), esc(tab['name'])))
        if tab['name'] == 'Colors':
            add('<p>All seven are <code>COLORREF</code> values, <code>00BBGGRR</code>. The swatch shows the default as it paints.</p>')
        add(table(['Prompt', 'Kind', 'Symbol', 'Default', 'Enabled when'], prompt_rows(tab['prompts'])))
    add('<h3 id="removing">Removing tab</h3>')
    add('''<p>Not a prompt &mdash; a page of instructions, because the swap the extension performs outlives it. The
extension sets <b>Global Properties &rarr; Classes &rarr; Report &rarr; Print Previewer</b> from
<code>PrintPreviewClass</code> to <code>EmfPreviewClass</code>, and Clarion <b>stores that value in the
.app</b>. Delete the extension and the reports keep the EmfPreview previewer.</p>
<ol class="b">
<li>Tick <b>Disable this template</b> on the General tab.</li>
<li>Generate once &mdash; the Print Previewer class is put back to <code>PrintPreviewClass</code>.</li>
<li>Delete the extension and generate again.</li>
</ol>
<p>Already deleted it? Set the Print Previewer class back by hand and generate all. The class is linked
into every module that uses it, so a leftover reference compiles and runs rather than GPFing; the
<code>testapp\\removal.txa</code> and <code>disable.txa</code> builds are the regression tests for both
paths.</p>''')
    add('<h3 id="swap">How the class swap works</h3>')
    add('''<p>ABC report procedures declare their previewer from the global symbol
<code>%PrintPreviewType</code>. The extension sets it at the start of every generation and restores it
when disabled or when <i>Replace</i> is off, so the value the .app keeps is always consistent with the
extension's own settings:</p>''')
    add(code(S_SWAP, 'template'))
    add('<p>Multi-DLL suites: add the global extension to every application. Each module links its own copy of the class; there is nothing to export.</p>')

    add('<h2 id="report"><span class="k">Templates</span>The report extension</h2>')
    add('<p>Accepted on %s. No tabs; the prompts nest under two check boxes:</p>' % esc(R['restrict'] or 'any procedure'))
    for tab in R['tabs']:
        add(table(['Prompt', 'Kind', 'Symbol', 'Default', 'Enabled when'], prompt_rows(tab['prompts'])))
    add('''<p>With <i>Override the global options</i> off, the five local prompts are ignored and the global
values are generated. The sidebar width, wheel lines and colours always come from the global extension.</p>''')

    add('<h2 id="embeds"><span class="k">Templates</span>Where the code lands</h2>')
    add('<p>No embed points of its own &mdash; the template only writes into existing ABC points:</p>')
    rows = []
    for ext in TPLX['extensions']:
        for a in ext['ats']:
            pt = a['point'] + ((",'%s'" % a['sub']) if a['sub'] else '') + ((",'%s'" % a['sig']) if a['sig'] else '')
            rows.append(['<code>%s</code>' % esc(ext['name']), '<code>%s</code>' % esc(pt),
                         a['priority'] or '&mdash;', '<code>%s</code>' % esc(a['where']) if a['where'] else '&mdash;'])
        if ext['atstart']:
            rows.append(['<code>%s</code>' % esc(ext['name']), '<code>#ATSTART</code>', '&mdash;',
                         'runs before generation: the class swap' if ext is G else
                         'runs before generation: resolves the zoom drop to an equate or a percent'])
    add(table(['Extension', 'Embed point', 'Priority', 'Condition'], rows))
    add('''<p>Priority 8490 in <code>WindowManager.Init</code> is after the report template has created the
<code>Previewer</code> object and before the window opens, so the options are in place for
<code>Display</code>.</p>''')

    add('<h2 id="generated"><span class="k">Templates</span>What gets generated</h2>')
    add(code(S_GEN_SAMPLE))
    add('<p>The generating block itself, from the template:</p>')
    add(code(_generated_block(), 'template'))
    add(note('cla', 'Regenerate to pick up template changes',
        '<p>Prompt changes reach the source on the next <b>generate</b>. Class changes are in '
        '<code>EmfPreview.clw</code> and reach the EXE on the next <b>compile</b> &mdash; and because the '
        'class is linked, not a DLL, every module that uses it has to be rebuilt.</p>'))

    add('<h2 id="next3"><span class="k">Templates</span>Where to go next</h2>')
    add(nextcards(['reference.html', 'programmers-guide.html', 'getting-started.html']))

    nprompts = sum(len(t['prompts']) for e in TPLX['extensions'] for t in e['tabs'])
    ntabs = len([t for t in G['tabs']])
    return page('template-guide.html',
                'EmfPreview Template Guide',
                'Volume 3', 'Template Guide',
                'Both extensions, every tab and prompt with its default, the class swap and how to undo it, '
                'and what the generator actually writes into the report procedure.',
                ['<b>2</b> extensions', '<b>%d</b> tabs' % ntabs, '<b>%d</b> prompts' % nprompts,
                 '<b>%d</b> embed points' % sum(len(e['ats']) for e in TPLX['extensions'])],
                [('This volume', [('two', 'The two extensions'), ('global', 'The global extension')] +
                                 [('g-' + slug(t['name']), t['name']) for t in G['tabs'] if t['prompts']] +
                                 [('removing', 'Removing'), ('swap', 'The class swap'),
                                  ('report', 'The report extension'), ('embeds', 'Where the code lands'),
                                  ('generated', 'What gets generated'), ('next3', 'Where to go next')])],
                ''.join(B))


# =====================================================================
#  4  REFERENCE
# =====================================================================
def methrow(key, name, sig, doc, attrs):
    u = USAGE.get(key)
    if not u: MISSING.append(key)
    tags = ''.join('<span class="tag%s">%s</span>' % (' tag--v' if a == 'VIRTUAL' else '', a) for a in attrs)
    return ('<tr class="fn" data-k="%s"><td class="fn__n"><code>%s</code>%s</td>'
            '<td class="fn__s"><code>%s</code>%s%s</td></tr>'
            % (esc((name + ' ' + doc).lower()), esc(name), tags, esc(sig),
               '<p class="fn__d">%s</p>' % esc(doc) if doc else '',
               usecode(u) if u else ''))

def proprow(pr, prefix=''):
    key = pr['name']
    u = PROPS.get(key)
    if not u: MISSING.append(prefix + key)
    t = pr['type'].replace(',PROTECTED', '')
    tag = '<span class="tag">PROTECTED</span>' if pr['protected'] else ''
    return ('<tr class="fn" data-k="%s"><td class="fn__n"><code>%s</code>%s</td>'
            '<td class="fn__s"><code>%s</code>%s%s</td></tr>'
            % (esc((key + ' ' + pr['note']).lower()), esc(key), tag, esc(t),
               '<p class="fn__d">%s</p>' % esc(pr['note']) if pr['note'] else '',
               usecode(u) if u else ''))

def fntable(rows):
    return '<div class="tw"><table class="fns"><tbody>%s</tbody></table></div>' % ''.join(rows)

def sig_of(m):
    return '%s(%s)%s' % (m['name'], m['parms'], (',' + ','.join(m['attrs'])) if m['attrs'] else '')

def build_reference():
    B = []; add = B.append

    # ---- EmfPreviewClass
    add('<h2 id="prev"><span class="k">Classes</span>EmfPreviewClass</h2>')
    add('''<p>Declared in <code>EmfPreview.inc</code>, implemented in <code>EmfPreview.clw</code>, derived from
<code>%s</code> so everything ABC gives a previewer &mdash; <code>Init</code>, <code>ImageQueue</code>,
<code>CurrentPage</code>, <code>PagesToPrint</code>, <code>PrintOK</code>, <code>Errors</code>,
<code>Translator</code>, <code>AskPrintPages</code>, the target selector &mdash; is still there. This
volume lists what EmfPreview adds. Each entry carries a worked line of Clarion; the tables are read
out of the include file and cannot drift from the code.</p>''' % esc(PREV['parent']))
    add(code(PREV['head'].replace(',MODULE', ',|\n                        MODULE')))

    sections = []
    for pr in PREV['props']:
        if pr['section'] not in sections: sections.append(pr['section'])
    intro = {
      'options (set before Display)': 'Public. Set them before <code>Display</code>; the template writes every one of them from its prompts.',
      'state': 'Mostly <code>PROTECTED</code> &mdash; what a derived class reads while the window is open. The three <code>&hellip;Text</code> strings are the toolbar\'s <code>USE</code> variables.',
      'field equates (PROTECTED so a derived class can drive the window)': 'The <code>USE</code> equates of every control on the preview window, captured in <code>Display</code>, so a derived class can hide, disable, retitle or post to any of them.',
    }
    for s in sections:
        add('<h3 id="prev-%s">%s</h3>' % (slug(s.split(' (')[0]), esc(s.split(' (')[0].capitalize())))
        if s in intro: add('<p>%s</p>' % intro[s])
        add(fntable([proprow(p) for p in PREV['props'] if p['section'] == s]))

    msections = []
    for m in PREV['meths']:
        if m['section'] not in msections: msections.append(m['section'])
    mintro = {
      'ABC overrides': 'The <code>PrintPreviewClass</code> entry points. Every one starts with <code>IF SELF.ClassicMode THEN RETURN PARENT&hellip;</code>, so the fallback is exact.',
      'navigation / view': 'What the toolbar, the keys and the wheel call. All virtual.',
      'search / marks': '<code>Find</code> fills <code>Hits</code>; everything else moves through them or turns them into marks.',
      'rendering': 'The twin metafile and the GDI measurements behind the highlights.',
      'hooks': 'Empty or thin by design &mdash; the places a derived class is expected to take over.',
    }
    for s in msections:
        add('<h3 id="prev-m-%s">%s</h3>' % (slug(s), esc(s[0].upper() + s[1:])))
        if s in mintro: add('<p>%s</p>' % mintro[s])
        add(fntable([methrow(m['name'], m['name'], sig_of(m), m['note'], m['attrs'])
                     for m in PREV['meths'] if m['section'] == s]))

    # ---- EmfTextIndexClass
    add('<h2 id="idx"><span class="k">Classes</span>EmfTextIndexClass</h2>')
    add('''<p>The text index. Implements <code>%s</code>, so the shipped parser can be pointed at it, and keeps
the result in two queues. The previewer owns one (<code>Index</code>); a program that only wants the
text of a printed report uses it alone.</p>''' % ' and '.join('<code>%s</code>' % esc(i) for i in INDEX['implements']))
    add(code(INDEX['head'].replace(',MODULE', ',|\n                        MODULE')))
    add('<h3 id="idx-props">Properties</h3>')
    add(fntable([proprow(p, 'EmfTextIndexClass.') for p in INDEX['props']]))
    add('<h3 id="idx-meths">Methods</h3>')
    add(fntable([methrow('EmfTextIndexClass.' + m['name'], m['name'], sig_of(m), m['note'], m['attrs'])
                 for m in INDEX['meths']]))
    add('<h3 id="idx-iface">Interface callbacks</h3>')
    add('''<p>Implemented for the parser to call; not part of the API you use. These are the ones that put
text into the index &mdash; every other <code>Process&hellip;</code> callback is an empty body:</p>''')
    add(table(['Callback', 'Lane', 'Collects'], [
      ['<code>ProcessString</code> / <code>ProcessStringW</code>', 'ANSI / wide', 'STRING controls'],
      ['<code>ProcessText</code> / <code>ProcessTextW</code>', 'ANSI / wide', 'each line of a TEXT control'],
      ['<code>ProcessCheck</code> / <code>ProcessCheckW</code>', 'ANSI / wide', 'the prompt of a CHECK'],
      ['<code>ProcessRadio</code> / <code>ProcessRadioW</code>', 'ANSI / wide', 'the prompt of a RADIO'],
      ['<code>ProcessGroup</code> / <code>ProcessGroupW</code>', 'ANSI / wide', 'the caption of a GROUP'],
      ['<code>StartPageProcess</code>', 'both', 'the page box; fills <code>Pages</code> and the current offsets'],
      ['<code>OpenDocumentW</code>', 'wide', 'sets <code>WideRun</code> = 1'],
    ]))

    # ---- queues
    add('<h2 id="queues"><span class="k">Types</span>Queues</h2>')
    add('<p>All <code>TYPE</code>d, declared in the include file. Coordinates are mils from the page frame origin unless the field says otherwise.</p>')
    for q in QUEUES:
        add('<h3 id="q-%s">%s</h3>' % (slug(q['name']), esc(q['name'])))
        if q['doc']: add('<p>%s</p>' % esc(q['doc']))
        add(table(['Field', 'Type', 'Meaning'], [
            ['<code>%s</code>' % esc(f['name']), '<code>%s</code>' % esc(f['type']), esc(f['note']) or '&mdash;']
            for f in q['fields']], 'eq'))

    # ---- equates
    add('<h2 id="eq"><span class="k">Equates</span>Equates</h2>')
    add(table(['Equate', 'Value', 'Meaning'], [
        ['<code>%s</code>' % esc(e['name']), '<span class="v">%s</span>' % esc(e['value']), esc(e['note']) or '&mdash;']
        for e in EQU], 'eq'))

    # ---- template symbols
    add('<h2 id="tsym"><span class="k">Template</span>Template symbols</h2>')
    add('<p>Every prompt symbol in <code>EmfPreview.tpl</code>, with the class property it ends up in. The report extension\'s <code>%EmfPrvL&hellip;</code> symbols shadow the global ones when <i>Override</i> is on.</p>')
    target = {
      '%EmfPrvSidebar': 'ShowSidebar', '%EmfPrvLSidebar': 'ShowSidebar', '%EmfPrvSidebarWidth': 'SidebarWidth',
      '%EmfPrvZoom': 'InitialZoom', '%EmfPrvLZoom': 'InitialZoom', '%EmfPrvClickMarks': 'ClickMarks',
      '%EmfPrvLClickMarks': 'ClickMarks', '%EmfPrvPrintMarks': 'PrintMarks', '%EmfPrvLPrintMarks': 'PrintMarks',
      '%EmfPrvMatchCase': 'SearchMatchCase', '%EmfPrvLMatchCase': 'SearchMatchCase', '%EmfPrvWheelLines': 'WheelLines',
      '%EmfPrvHighlightColor': 'HighlightColor', '%EmfPrvMarkColor': 'MarkColor', '%EmfPrvCurrentColor': 'CurrentColor',
      '%EmfPrvPageMarkColor': 'PageMarkColor', '%EmfPrvAccentColor': 'AccentColor', '%EmfPrvPaperShadow': 'PaperShadow',
      '%EmfPrvSidebarColor': 'SidebarColor', '%EmfPrvTitle': 'Title', '%EmfPrvUse': 'ClassicMode (inverted)',
      '%EmfPrvDisable': '(generation switch)', '%EmfPrvReplaceAll': '%PrintPreviewType', '%EmfPrvOverride': '(prompt switch)',
    }
    rows = []
    for ext in TPLX['extensions']:
        for tab in ext['tabs']:
            for p in tab['prompts']:
                rows.append(['<code>%s</code>' % esc(p['symbol']), esc(ext['name']), esc(p['label']),
                             esc(p['default']) or '&mdash;',
                             '<code>%s</code>' % esc(target[p['symbol']]) if p['symbol'] in target else '&mdash;'])
                if p['symbol'] not in target:
                    PROBLEMS.append('reference.html: template symbol %s has no class property mapping' % p['symbol'])
    add(table(['Symbol', 'Extension', 'Prompt', 'Default', 'Sets'], rows, 'eq'))

    add('<h2 id="next4"><span class="k">Reference</span>Where to go next</h2>')
    add(nextcards(['programmers-guide.html', 'template-guide.html', 'getting-started.html']))

    nav = [('EmfPreviewClass', [('prev', 'EmfPreviewClass')] +
                               [('prev-' + slug(s.split(' (')[0]), s) for s in sections] +
                               [('prev-m-' + slug(s), s) for s in msections]),
           ('EmfTextIndexClass', [('idx', 'EmfTextIndexClass'), ('idx-props', 'Properties'),
                                  ('idx-meths', 'Methods'), ('idx-iface', 'Interface callbacks')]),
           ('Types', [('queues', 'Queues')] + [('q-' + slug(q['name']), q['name']) for q in QUEUES]),
           ('Equates', [('eq', 'Equates')]),
           ('Template', [('tsym', 'Template symbols')]),
           ('', [('next4', 'Where to go next')])]
    return page('reference.html',
                'EmfPreview Reference',
                'Volume 4', 'Reference',
                'Every property, method, queue field, equate and template symbol &mdash; generated from '
                '<code>EmfPreview.inc</code> and <code>EmfPreview.tpl</code>, with a worked line of Clarion '
                'against each member.',
                ['<b>%d</b> methods' % (len(PREV['meths']) + len(INDEX['meths'])),
                 '<b>%d</b> properties' % (len(PREV['props']) + len(INDEX['props'])),
                 '<b>%d</b> queues' % len(QUEUES), '<b>%d</b> equates' % len(EQU),
                 '<b>%d</b> template symbols' % len(rows)],
                nav, ''.join(B), showfilter=True)


# =====================================================================
if __name__ == '__main__':
    total = 0
    for fn, kb in (('getting-started.html',   build_getting_started()),
                   ('programmers-guide.html', build_programmers_guide()),
                   ('template-guide.html',    build_template_guide()),
                   ('reference.html',         build_reference())):
        print('  docs/%-24s %6.1f KB' % (fn, kb / 1024.0))
        total += kb
    print('  %-26s %6.1f KB' % ('four volumes', total / 1024.0))
    if MISSING:
        print('  !! no worked example for: ' + ', '.join(sorted(set(MISSING))))
    else:
        print('  every property and method has a worked example')
    if PROBLEMS:
        for line in PROBLEMS: print('  !! ' + line)
    else:
        print('  every nav entry names the heading it lands on')
    if MISSING or PROBLEMS:
        sys.exit(1)
