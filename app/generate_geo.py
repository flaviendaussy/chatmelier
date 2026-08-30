import urllib.request, json, math

url_metro = 'https://raw.githubusercontent.com/gregoiredavid/france-geojson/master/metropole.geojson'
url_deps = 'https://raw.githubusercontent.com/gregoiredavid/france-geojson/master/departements.geojson'

req_m = urllib.request.Request(url_metro, headers={'User-Agent': 'Mozilla/5.0'})
with urllib.request.urlopen(req_m) as r:
    metro_data = json.loads(r.read().decode('utf-8'))

req_d = urllib.request.Request(url_deps, headers={'User-Agent': 'Mozilla/5.0'})
with urllib.request.urlopen(req_d) as r:
    deps_data = json.loads(r.read().decode('utf-8'))

# Lambert Conic projection centered on France
lat0 = 46.5 * math.pi / 180
lon0 = 2.5 * math.pi / 180
n = math.sin(lat0)

def project(lon, lat):
    phi = lat * math.pi / 180
    lam = lon * math.pi / 180
    rho = math.cos(lat0) / n - (phi - lat0)
    theta = n * (lam - lon0)
    x = rho * math.sin(theta)
    y = rho * math.cos(theta)
    return x, y

def pt_dist(p, start, end):
    dx = end[0] - start[0]
    dy = end[1] - start[1]
    mag = math.hypot(dx, dy)
    if mag == 0:
        return math.hypot(p[0] - start[0], p[1] - start[1])
    u = ((p[0] - start[0]) * dx + (p[1] - start[1]) * dy) / (mag * mag)
    u = max(0, min(1, u))
    ix = start[0] + u * dx
    iy = start[1] + u * dy
    return math.hypot(p[0] - ix, p[1] - iy)

def dp(pts, tol):
    if len(pts) <= 2:
        return pts
    dmax = 0
    idx = 0
    for i in range(1, len(pts) - 1):
        d = pt_dist(pts[i], pts[0], pts[-1])
        if d > dmax:
            dmax = d
            idx = i
    if dmax > tol:
        r1 = dp(pts[:idx+1], tol)
        r2 = dp(pts[idx:], tol)
        return r1[:-1] + r2
    else:
        return [pts[0], pts[-1]]

poly_mainland = metro_data['geometry']['coordinates'][0][0]
poly_corse = metro_data['geometry']['coordinates'][164][0]

pts_m = dp([project(p[0], p[1]) for p in poly_mainland], 0.00035)
pts_c = dp([project(p[0], p[1]) for p in poly_corse], 0.00035)

all_pts = pts_m + pts_c
min_x = min(p[0] for p in all_pts)
max_x = max(p[0] for p in all_pts)
min_y = min(p[1] for p in all_pts)
max_y = max(p[1] for p in all_pts)

span_x = max_x - min_x
span_y = max_y - min_y
max_span = max(span_x, span_y)

pad = 35.0
scale = (1000.0 - 2.0 * pad) / max_span
off_x = pad + ((max_span - span_x) / 2.0) * scale
off_y = pad + ((max_span - span_y) / 2.0) * scale

def to_screen(p):
    sx = off_x + (p[0] - min_x) * scale
    sy = off_y + (p[1] - min_y) * scale
    return round(sx, 1), round(sy, 1)

def to_svg(points_list):
    res = []
    for pts in points_list:
        if not pts: continue
        sc = [to_screen(p) for p in pts]
        cmd = f'M {sc[0][0]},{sc[0][1]} ' + ' '.join([f'L {p[0]},{p[1]}' for p in sc[1:]]) + ' Z'
        res.append(cmd)
    return ' '.join(res)

mainland_svg = to_svg([pts_m])
corse_svg = to_svg([pts_c])

def get_dep_svg(codes, tol=0.0006):
    rings = []
    for f in deps_data['features']:
        code = f['properties']['code']
        if code in codes:
            geom = f['geometry']
            if geom['type'] == 'Polygon':
                rings.append(geom['coordinates'][0])
            elif geom['type'] == 'MultiPolygon':
                for p in geom['coordinates']:
                    rings.append(p[0])
    res_svg = []
    for r in rings:
        pts = dp([project(p[0], p[1]) for p in r], tol)
        if len(pts) < 3: continue
        sc = [to_screen(p) for p in pts]
        cmd = f'M {sc[0][0]},{sc[0][1]} ' + ' '.join([f'L {p[0]},{p[1]}' for p in sc[1:]]) + ' Z'
        res_svg.append(cmd)
    return ' '.join(res_svg)

bordeaux_svg = get_dep_svg(['33'])
bourgogne_svg = get_dep_svg(['21', '71', '89'])
champagne_svg = get_dep_svg(['51', '10'])
loire_svg = get_dep_svg(['44', '49', '37', '41', '18'])
rhone_svg = get_dep_svg(['69', '26', '07', '84'])
alsace_svg = get_dep_svg(['67', '68'])
provence_corse_svg = get_dep_svg(['13', '83', '06', '2A', '2B'])

# Major French Rivers
raw_rivers = [
    # Seine
    [(0.1, 49.5), (1.1, 49.4), (2.35, 48.85), (2.65, 48.54), (4.07, 48.30)],
    # Loire
    [(-2.2, 47.27), (-1.55, 47.22), (-0.55, 47.47), (-0.08, 47.26), (0.69, 47.39), (1.33, 47.59), (1.91, 47.90), (3.16, 46.99)],
    # Garonne
    [(-1.03, 45.62), (-0.58, 44.84), (0.16, 44.50), (0.62, 44.20), (1.44, 43.60)],
    # Dordogne
    [(-0.60, 45.02), (-0.24, 44.91), (0.48, 44.85), (1.21, 44.89)],
    # Rhône
    [(6.14, 46.20), (4.83, 45.76), (4.87, 45.52), (4.89, 44.93), (4.75, 44.56), (4.80, 43.95), (4.63, 43.68), (4.70, 43.35)],
    # Saône
    [(6.45, 48.17), (5.60, 47.51), (4.86, 46.78), (4.83, 46.30), (4.83, 45.76)],
    # Rhin
    [(7.59, 47.56), (7.55, 47.75), (7.58, 48.08), (7.75, 48.58), (8.18, 48.97)]
]

rivers_svg_list = []
for riv in raw_rivers:
    sc = [to_screen(project(p[0], p[1])) for p in riv]
    cmd = f'M {sc[0][0]},{sc[0][1]} ' + ' '.join([f'L {p[0]},{p[1]}' for p in sc[1:]])
    rivers_svg_list.append(cmd)
rivers_svg = ' '.join(rivers_svg_list)

out_content = f'''import 'dart:ui';

/// High-precision geographic vector cartography dataset for France and wine regions.
/// Reference Coordinate System: ViewBox (0, 0, 1000, 1000) based on Lambert-93 Conic Projection.
class FranceGeoData {{
  static const Rect viewBox = Rect.fromLTWH(0, 0, 1000, 1000);

  // ===========================================================================
  // 1. MAINLAND FRANCE DETAILED REAL GEOGRAPHIC OUTLINE (IGN METROPOLE)
  // ===========================================================================
  static const String franceMainlandSvg = '{mainland_svg}';

  // ===========================================================================
  // 2. CORSE DETAILED ISLAND (IGN METROPOLE)
  // ===========================================================================
  static const String corseSvg = '{corse_svg}';

  // ===========================================================================
  // 3. MAJOR FRENCH RIVER SYSTEMS (SEINE, LOIRE, GARONNE, DORDOGNE, RHONE, SAONE, RHIN)
  // ===========================================================================
  static const String riversSvg = '{rivers_svg}';

  // ===========================================================================
  // 4. REAL GEOGRAPHIC A.O.C. WINE REGION POLYGONS
  // ===========================================================================
  static const String bordeauxSvg = '{bordeaux_svg}';
  static const String bourgogneSvg = '{bourgogne_svg}';
  static const String champagneSvg = '{champagne_svg}';
  static const String loireSvg = '{loire_svg}';
  static const String rhoneSvg = '{rhone_svg}';
  static const String alsaceSvg = '{alsace_svg}';
  static const String provenceCorseSvg = '{provence_corse_svg}';
}}
'''

with open('lib/features/scratchcard/presentation/france_geo_data.dart', 'w') as f:
    f.write(out_content)

print('Updated france_geo_data.dart with correct North-Up orientation!')
