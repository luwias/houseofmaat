# The House of Ma'at – a templom procedurális felépítése Blenderben.
# Futtatás:
#   blender --background --python tools/blender/build_temple.py -- assets/models
# Kimenet: temple.glb (7 terem), prop_k08.glb, prop_ship.glb
#
# Elnevezési konvenciók (a Godot-oldal ezekre épít):
#   Room_<id>          – terem gyökér
#   Interact_<id>      – kattintható csoport (a Godot AABB-ből ütközőt épít)
#   Cam_<room>/Look_<room> – kamera nézőpont és célpont
#   Light_<room>_<n>   – fáklya/láng fényforrás helye
#   Ghost_<room>_<n>   – szellemek útvonalpontjai (magas Duat)
#   Crack_*, Rubble_*  – alacsony Ma'at esetén láthatók
#   Plant_*, Water_*, Lotus_* – az Ankh-értékre reagálnak
#   Orb_*, Clue_*, Seal_* – állapotfüggő láthatóság
#   Az anyagneveket (Sandstone, Gold, Glyph, ...) a Godot saját anyagokra cseréli.

import bpy, bmesh, math, random, sys, os

argv = sys.argv
OUT_DIR = argv[argv.index("--") + 1] if "--" in argv else "."
os.makedirs(OUT_DIR, exist_ok=True)
random.seed(1337)

bpy.ops.wm.read_factory_settings(use_empty=True)

# ---------------------------------------------------------------- anyagok
MATS = {}


def mat(name, rgb, metal=0.0, rough=0.85, emit=0.0):
    if name in MATS:
        return MATS[name]
    m = bpy.data.materials.new(name)
    try:
        m.use_nodes = True
    except Exception:
        pass
    m.diffuse_color = (*rgb, 1.0)
    nt = m.node_tree
    if nt:
        for n in nt.nodes:
            if n.type == 'BSDF_PRINCIPLED':
                n.inputs['Base Color'].default_value = (*rgb, 1.0)
                n.inputs['Metallic'].default_value = metal
                n.inputs['Roughness'].default_value = rough
                if emit > 0:
                    n.inputs['Emission Color'].default_value = (*rgb, 1.0)
                    n.inputs['Emission Strength'].default_value = emit
    MATS[name] = m
    return m


SAND = mat("Sandstone", (0.76, 0.60, 0.42))
LIME = mat("Limestone", (0.86, 0.82, 0.72))
BASALT = mat("Basalt", (0.08, 0.08, 0.10), rough=0.6)
GOLD = mat("Gold", (0.83, 0.62, 0.20), metal=1.0, rough=0.3)
LAPIS = mat("Lapis", (0.10, 0.17, 0.46), rough=0.5)
TURQ = mat("Turquoise", (0.18, 0.60, 0.58), rough=0.5)
OCHRE = mat("Ochre", (0.72, 0.45, 0.18))
REDOCHRE = mat("RedOchre", (0.55, 0.20, 0.12))
GLYPH = mat("Glyph", (0.78, 0.63, 0.44))
WATER = mat("Water", (0.10, 0.35, 0.45), rough=0.05)
PLANT = mat("Plant", (0.25, 0.45, 0.18))
WOOD = mat("Wood", (0.35, 0.22, 0.12))
PAPYRUS = mat("Papyrus", (0.85, 0.76, 0.55))
FLAME = mat("Flame", (1.0, 0.60, 0.20), emit=8.0)
CRACK = mat("Crack", (0.03, 0.03, 0.03))
STAR = mat("Star", (1.0, 0.90, 0.60), emit=4.0)
MEMORY = mat("Memory", (0.30, 0.90, 0.85), emit=3.0)
VOID = mat("Void", (0.0, 0.0, 0.0))
SANDFLOOR = mat("SandFloor", (0.80, 0.68, 0.45))
LOTUS = mat("Lotus", (0.92, 0.55, 0.66))
NIGHT = mat("Night", (0.02, 0.03, 0.09))
CLAY = mat("Clay", (0.62, 0.38, 0.24))
LINEN = mat("Linen", (0.92, 0.89, 0.80))

# ---------------------------------------------------------------- segédek
PARENT = [None]


def finish(o, name, m):
    o.name = name
    if m is not None and o.data is not None and hasattr(o.data, "materials"):
        o.data.materials.clear()
        o.data.materials.append(m)
    if PARENT[0] is not None:
        o.parent = PARENT[0]
    return o


def active():
    return bpy.context.view_layer.objects.active


def box(name, loc, size, m, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    o = active()
    o.scale = size
    return finish(o, name, m)


def cyl(name, loc, r, h, m, verts=16, rot=(0, 0, 0), smooth=True, scale=(1, 1, 1)):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=h, location=loc, rotation=rot)
    o = active()
    o.scale = scale
    if smooth:
        bpy.ops.object.shade_smooth()
    return finish(o, name, m)


def cone(name, loc, r1, r2, h, m, verts=16, rot=(0, 0, 0), scale=(1, 1, 1), smooth=True):
    bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r1, radius2=r2, depth=h, location=loc, rotation=rot)
    o = active()
    o.scale = scale
    if smooth:
        bpy.ops.object.shade_smooth()
    return finish(o, name, m)


def sphere(name, loc, r, m, seg=16, ring=8, scale=(1, 1, 1)):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=ring, radius=r, location=loc)
    o = active()
    o.scale = scale
    bpy.ops.object.shade_smooth()
    return finish(o, name, m)


def ico(name, loc, r, m, sub=1, scale=(1, 1, 1), rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub, radius=r, location=loc, rotation=rot)
    o = active()
    o.scale = scale
    return finish(o, name, m)


def torus(name, loc, R, r, m, rot=(0, 0, 0), major_seg=48, minor_seg=8):
    bpy.ops.mesh.primitive_torus_add(major_radius=R, minor_radius=r, location=loc, rotation=rot,
                                     major_segments=major_seg, minor_segments=minor_seg)
    o = active()
    bpy.ops.object.shade_smooth()
    return finish(o, name, m)


def empty(name, loc=(0, 0, 0)):
    bpy.ops.object.empty_add(type='PLAIN_AXES', location=loc)
    o = active()
    o.name = name
    if PARENT[0] is not None:
        o.parent = PARENT[0]
    return o


def join(objs, name):
    objs = [o for o in objs if o is not None]
    if not objs:
        return None
    bpy.ops.object.select_all(action='DESELECT')
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    if len(objs) > 1:
        bpy.ops.object.join()
    o = active()
    o.name = name
    o.select_set(False)
    return o


def flip(o):
    bm = bmesh.new()
    bm.from_mesh(o.data)
    bmesh.ops.reverse_faces(bm, faces=bm.faces)
    bm.to_mesh(o.data)
    bm.free()


class Group:
    """Az összes közben létrehozott objektumot egy origóban álló üres alá rendezi."""

    def __init__(self, name):
        self.name = name

    def __enter__(self):
        self.prev = PARENT[0]
        e = empty(self.name)
        PARENT[0] = e
        return e

    def __exit__(self, *a):
        PARENT[0] = self.prev


def mapper(plane, origin, sign=1.0):
    ox, oy, oz = origin
    if plane == 'floor':
        return lambda u, v: (ox + u, oy + v, oz)
    if plane == 'wall_x':  # a fal síkja YZ, normál ±X
        return lambda u, v: (ox, oy + u, oz + v)
    return lambda u, v: (ox + u, oy, oz + v)  # wall_y


def crack(name, plane, origin, length=2.2):
    """Cikcakkos repedés vékony hasábokból."""
    f = mapper(plane, origin)
    parts = []
    u, v = 0.0, 0.0
    ang = random.uniform(0, math.tau)
    travelled = 0.0
    i = 0
    while travelled < length:
        seg = random.uniform(0.25, 0.6)
        ang += random.uniform(-0.9, 0.9)
        nu, nv = u + math.cos(ang) * seg, v + math.sin(ang) * seg
        mu, mv = (u + nu) / 2, (v + nv) / 2
        p = f(mu, mv)
        if plane == 'floor':
            o = box(f"{name}_p{i}", (p[0], p[1], p[2] + 0.01), (seg, 0.05, 0.03), CRACK, rot=(0, 0, ang))
        elif plane == 'wall_x':
            o = box(f"{name}_p{i}", p, (0.04, seg, 0.05), CRACK, rot=(ang, 0, 0))
        else:
            o = box(f"{name}_p{i}", p, (seg, 0.04, 0.05), CRACK, rot=(0, -ang, 0))
        parts.append(o)
        # mellékág
        if random.random() < 0.3:
            ba = ang + random.choice([-1, 1]) * random.uniform(0.6, 1.2)
            bl = seg * 0.6
            bu, bv = nu + math.cos(ba) * bl / 2, nv + math.sin(ba) * bl / 2
            bp = f(bu, bv)
            if plane == 'floor':
                parts.append(box(f"{name}_b{i}", (bp[0], bp[1], bp[2] + 0.01), (bl, 0.035, 0.03), CRACK, rot=(0, 0, ba)))
            elif plane == 'wall_x':
                parts.append(box(f"{name}_b{i}", bp, (0.04, bl, 0.035), CRACK, rot=(ba, 0, 0)))
            else:
                parts.append(box(f"{name}_b{i}", bp, (bl, 0.04, 0.035), CRACK, rot=(0, -ba, 0)))
        u, v = nu, nv
        travelled += seg
        i += 1
    return join(parts, name)


def rubble(name, center, count=5, spread=0.8):
    parts = []
    for i in range(count):
        p = (center[0] + random.uniform(-spread, spread), center[1] + random.uniform(-spread, spread),
             center[2] + 0.08)
        r = random.uniform(0.08, 0.22)
        parts.append(ico(f"{name}_{i}", p, r, SAND, sub=1,
                         scale=(1, random.uniform(0.7, 1.3), random.uniform(0.5, 0.9)),
                         rot=(random.random(), random.random(), random.random())))
    return join(parts, name)


def stars(name, center, size, z, count, m=STAR):
    parts = []
    for i in range(count):
        p = (center[0] + random.uniform(-size[0] / 2, size[0] / 2),
             center[1] + random.uniform(-size[1] / 2, size[1] / 2), z)
        parts.append(ico(f"{name}_{i}", p, random.uniform(0.07, 0.14), m, sub=1, scale=(1, 1, 0.3)))
    return join(parts, name)


def kheker_frieze(name, start, end, z, axis):
    """Egyiptomi kheker-fríz: váltakozó lapis/türkiz/arany függőleges elemek."""
    parts = []
    n = int(abs((end - start)) / 0.55)
    for i in range(n):
        t = start + (end - start) * (i + 0.5) / n
        m = [LAPIS, TURQ, GOLD, OCHRE][i % 4]
        if axis == 'y':
            loc = (z[0], t, z[1])
            parts.append(box(f"{name}_{i}", loc, (0.12, 0.32, 1.1), m))
        else:
            loc = (t, z[0], z[1])
            parts.append(box(f"{name}_{i}", loc, (0.32, 0.12, 1.1), m))
    return join(parts, name)


def column(name, x, y, height=8.4, glyph=True, broken=False, tilt=0.0):
    parts = []
    parts.append(cyl(f"{name}_base", (x, y, 0.3), 1.2, 0.6, LIME, verts=24))
    h = height
    parts.append(cyl(f"{name}_shaft", (x, y, 0.6 + h / 2), 0.9, h, SAND, verts=24, rot=(tilt, 0, 0)))
    if not broken:
        for (zz, m) in [(1.2, LAPIS), (1.5, GOLD), (h - 0.2, LAPIS), (h + 0.1, TURQ)]:
            parts.append(cyl(f"{name}_band{zz}", (x, y, zz), 0.93, 0.18, m, verts=24))
        if glyph:
            parts.append(cyl(f"{name}_glyph", (x, y, 3.9), 0.915, 2.6, GLYPH, verts=24))
        parts.append(cone(f"{name}_cap", (x, y, 0.6 + h + 0.95), 0.9, 1.6, 1.9, TURQ, verts=24))
        parts.append(cyl(f"{name}_capband", (x, y, 0.6 + h + 0.35), 1.12, 0.14, GOLD, verts=24))
        parts.append(box(f"{name}_abacus", (x, y, 0.6 + h + 2.15), (2.4, 2.4, 0.5), LIME))
    return join(parts, name)


def brazier(name, loc, light_name):
    x, y, z = loc
    parts = []
    for k in range(3):
        a = k * math.tau / 3
        parts.append(cyl(f"{name}_leg{k}", (x + math.cos(a) * 0.22, y + math.sin(a) * 0.22, z + 0.6), 0.05, 1.25,
                         GOLD, verts=8, rot=(math.sin(a) * 0.18, -math.cos(a) * 0.18, 0)))
    parts.append(cone(f"{name}_bowl", (x, y, z + 1.4), 0.22, 0.62, 0.42, GOLD, verts=20))
    parts.append(torus(f"{name}_rim", (x, y, z + 1.61), 0.62, 0.04, GOLD))
    b = join(parts, name)
    ico(f"Flame_{name}", (x, y, z + 1.85), 0.32, FLAME, sub=2, scale=(1, 1, 1.8))
    empty(light_name, (x, y, z + 2.4))
    return b


def door(gid, center, axis, width=3.2, height=6.2, sealed=False, facing=1):
    """Kapuzat pülonszerű kerettel. axis='x': a falsík YZ (oldalfal)."""
    cx, cy, cz = center
    with Group(f"Interact_door_{gid}"):
        if axis == 'x':
            box(f"Door_{gid}_void", (cx + 0.1 * facing, cy, cz + height / 2), (0.3, width, height), VOID)
            for s in (-1, 1):
                box(f"Door_{gid}_jamb{s}", (cx - 0.15 * facing, cy + s * (width / 2 + 0.4), cz + height / 2 + 0.3),
                    (0.5, 0.8, height + 0.6), LIME)
            box(f"Door_{gid}_lintel", (cx - 0.15 * facing, cy, cz + height + 0.8), (0.55, width + 1.8, 1.0), LIME)
            box(f"Door_{gid}_glyph", (cx - 0.44 * facing, cy, cz + height + 0.8), (0.05, width + 1.2, 0.7), GLYPH)
            box(f"Door_{gid}_cornice", (cx - 0.25 * facing, cy, cz + height + 1.5), (0.8, width + 2.2, 0.4), GOLD)
            if sealed:
                box(f"Seal_{gid}", (cx - 0.05 * facing, cy, cz + height / 2), (0.3, width, height), BASALT)
        else:
            box(f"Door_{gid}_void", (cx, cy + 0.1 * facing, cz + height / 2), (width, 0.3, height), VOID)
            for s in (-1, 1):
                box(f"Door_{gid}_jamb{s}", (cx + s * (width / 2 + 0.4), cy - 0.15 * facing, cz + height / 2 + 0.3),
                    (0.8, 0.5, height + 0.6), LIME)
            box(f"Door_{gid}_lintel", (cx, cy - 0.15 * facing, cz + height + 0.8), (width + 1.8, 0.55, 1.0), LIME)
            box(f"Door_{gid}_glyph", (cx, cy - 0.44 * facing, cz + height + 0.8), (width + 1.2, 0.05, 0.7), GLYPH)
            box(f"Door_{gid}_cornice", (cx, cy - 0.25 * facing, cz + height + 1.5), (width + 2.2, 0.8, 0.4), GOLD)
            if sealed:
                box(f"Seal_{gid}", (cx, cy - 0.05 * facing, cz + height / 2), (width, 0.3, height), BASALT)


def statue_seated(name, loc, facing_y=-1, head_mat=LAPIS, feather=True):
    x, y, z = loc
    f = facing_y
    parts = [
        box(f"{name}_ped", (x, y, z + 0.6), (2.0, 2.4, 1.2), BASALT),
        box(f"{name}_throne", (x, y - f * 0.25, z + 1.9), (1.5, 1.7, 1.4), LIME),
        box(f"{name}_throneback", (x, y - f * 0.95, z + 2.6), (1.5, 0.3, 2.8), LIME),
        box(f"{name}_torso", (x, y - f * 0.45, z + 3.4), (0.95, 0.65, 1.6), LIME),
        box(f"{name}_lap", (x, y + f * 0.15, z + 2.75), (0.95, 1.2, 0.4), LINEN),
        box(f"{name}_shins", (x, y + f * 0.7, z + 2.0), (0.9, 0.35, 1.1), LIME),
        box(f"{name}_collar", (x, y - f * 0.45, z + 4.05), (1.05, 0.72, 0.25), GOLD),
        sphere(f"{name}_head", (x, y - f * 0.45, z + 4.55), 0.36, LIME),
        box(f"{name}_wig", (x, y - f * 0.55, z + 4.45), (0.82, 0.62, 0.95), head_mat),
    ]
    for s in (-1, 1):
        parts.append(box(f"{name}_arm{s}", (x + s * 0.55, y - f * 0.1, z + 3.2), (0.22, 0.9, 0.25), LIME))
    if feather:
        parts.append(cone(f"{name}_feather", (x, y - f * 0.55, z + 5.4), 0.13, 0.03, 1.1, GOLD, verts=8,
                          scale=(0.45, 1, 1), rot=(f * 0.15, 0, 0)))
    return join(parts, name)


def standing_god(name, loc, kind, facing_y=-1):
    """Thot (íbisz) vagy Anubisz (sakál) stilizált állószobra."""
    x, y, z = loc
    f = facing_y
    parts = [
        box(f"{name}_ped", (x, y, z + 0.5), (1.8, 1.8, 1.0), LIME),
        cone(f"{name}_kilt", (x, y, z + 1.9), 0.75, 0.45, 1.8, LINEN, verts=4, rot=(0, 0, math.pi / 4)),
        box(f"{name}_torso", (x, y, z + 3.4), (0.95, 0.55, 1.3), BASALT),
        box(f"{name}_collar", (x, y, z + 4.0), (1.15, 0.65, 0.22), GOLD),
        box(f"{name}_neck", (x, y, z + 4.3), (0.32, 0.32, 0.4), BASALT),
        box(f"{name}_staff", (x + 0.75, y + f * 0.15, z + 3.2), (0.08, 0.08, 4.2), GOLD),
    ]
    for s in (-1, 1):
        parts.append(box(f"{name}_arm{s}", (x + s * 0.6, y, z + 3.3), (0.2, 0.25, 1.2), BASALT))
    if kind == 'ibis':
        parts.append(sphere(f"{name}_head", (x, y, z + 4.75), 0.34, BASALT))
        parts.append(cone(f"{name}_beak", (x, y + f * 0.75, z + 4.45), 0.09, 0.01, 1.1, GOLD, verts=8,
                          rot=(-f * 1.9, 0, 0)))
        parts.append(box(f"{name}_wig", (x, y - f * 0.15, z + 4.55), (0.7, 0.5, 0.8), LAPIS))
    else:
        parts.append(box(f"{name}_head", (x, y, z + 4.75), (0.5, 0.6, 0.5), BASALT))
        parts.append(box(f"{name}_snout", (x, y + f * 0.5, z + 4.65), (0.26, 0.6, 0.26), BASALT))
        for s in (-1, 1):
            parts.append(cone(f"{name}_ear{s}", (x + s * 0.18, y - f * 0.05, z + 5.25), 0.14, 0.02, 0.6, BASALT,
                              verts=4))
        parts.append(box(f"{name}_wig", (x, y - f * 0.1, z + 4.55), (0.66, 0.4, 0.75), GOLD))
    return join(parts, name)


def room_shell(rid, c, size, height, wall_m, floor_m, ceil_m=LAPIS, ceiling=True, star_count=40, front=True):
    cx, cy = c
    w, l = size
    box(f"{rid}_floor", (cx, cy, -0.25), (w, l, 0.5), floor_m)
    box(f"{rid}_wallL", (cx - w / 2 - 0.5, cy, height / 2), (1, l, height), wall_m)
    box(f"{rid}_wallR", (cx + w / 2 + 0.5, cy, height / 2), (1, l, height), wall_m)
    box(f"{rid}_wallB", (cx, cy + l / 2 + 0.5, height / 2), (w + 2, 1, height), wall_m)
    if front:
        box(f"{rid}_wallF", (cx, cy - l / 2 - 0.5, height / 2), (w + 2, 1, height), wall_m)
    if ceiling:
        box(f"{rid}_ceiling", (cx, cy, height + 0.5), (w + 2, l + 2, 1), ceil_m)
        if star_count:
            stars(f"{rid}_stars", (cx, cy), (w - 1, l - 1), height - 0.03, star_count)
    # lábazat és aranycsík
    for s in (-1, 1):
        box(f"{rid}_dado{s}", (cx + s * (w / 2 - 0.08), cy, 0.6), (0.18, l, 1.2), OCHRE)
        box(f"{rid}_trim{s}", (cx + s * (w / 2 - 0.12), cy, 1.25), (0.2, l, 0.09), GOLD)
    box(f"{rid}_dadoB", (cx, cy + l / 2 - 0.08, 0.6), (w, 0.18, 1.2), OCHRE)
    box(f"{rid}_trimB", (cx, cy + l / 2 - 0.12, 1.25), (w, 0.2, 0.09), GOLD)


# ================================================================ 1. ÍTÉLET CSARNOKA
def build_hall():
    with Group("Room_hall"):
        W, L, H = 26, 34, 13
        room_shell("Hall", (0, 0), (W, L), H, SAND, BASALT, star_count=110)
        # mennyezeti gerendák
        for i, y in enumerate(range(-15, 17, 6)):
            box(f"Hall_beam{i}", (0, y, H - 0.25), (W, 0.6, 0.5), GOLD)
        # padlóintarzia – a mérleghez vezető lapis út
        box("Hall_path", (0, -2, 0.02), (4, 26, 0.04), LAPIS)
        for s in (-1, 1):
            box(f"Hall_pathgold{s}", (s * 2.1, -2, 0.03), (0.16, 26, 0.05), GOLD)
        for i in range(12):
            box(f"Hall_tile{i}", (0, -14 + i * 2.2, 0.035), (0.6, 0.6, 0.04), TURQ, rot=(0, 0, math.pi / 4))
        # fal-hieroglifasávok és fríz
        for s in (-1, 1):
            box(f"Hall_glyphband{s}", (s * (W / 2 - 0.05), 0, 4.6), (0.1, L - 4, 2.6), GLYPH)
            box(f"Hall_glyphframeT{s}", (s * (W / 2 - 0.09), 0, 6.0), (0.12, L - 4, 0.12), GOLD)
            box(f"Hall_glyphframeB{s}", (s * (W / 2 - 0.09), 0, 3.2), (0.12, L - 4, 0.12), GOLD)
            kheker_frieze(f"Hall_frieze{s}", -16, 16, (s * (W / 2 - 0.1), H - 1.6), 'y')
        kheker_frieze("Hall_friezeB", -12.5, 12.5, (L / 2 - 0.1, H - 1.6), 'x')
        # oszlopsorok és architráv
        for s in (-1, 1):
            for i, y in enumerate([-12, -6.5, -1, 4.5, 10]):
                column(f"Hall_col{s}_{i}", s * 7.5, y)
            box(f"Hall_architrave{s}", (s * 7.5, -1, 11.7), (1.8, 26, 0.8), SAND)
            box(f"Hall_architravegold{s}", (s * 7.5, -1, 11.25), (1.85, 26, 0.12), GOLD)
        # emelvény
        for i, (w, l) in enumerate([(10, 8), (8, 6.4), (6, 5)]):
            box(f"Hall_dais{i}", (0, 7.5, 0.175 + i * 0.35), (w, l, 0.35), LIME)
            box(f"Hall_daisedge{i}", (0, 7.5 - l / 2, 0.33 + i * 0.35), (w, 0.08, 0.05), GOLD)
        torus("Hall_maatring", (0, 7.5, 1.06), 2.2, 0.05, GOLD)
        # a Ma'at mérlege
        with Group("Interact_scales"):
            z = 1.05
            cyl("Scales_base", (0, 7.5, z + 0.15), 0.6, 0.3, GOLD, verts=24)
            cyl("Scales_pole", (0, 7.5, z + 1.9), 0.09, 3.2, GOLD, verts=12)
            sphere("Scales_knob", (0, 7.5, z + 3.6), 0.16, GOLD)
            box("Scales_beam", (0, 7.5, z + 3.35), (3.7, 0.12, 0.12), GOLD)
            for s in (-1, 1):
                for k in (-1, 1):
                    cyl(f"Scales_chain{s}{k}", (s * 1.8 + k * 0.25, 7.5, z + 2.7), 0.015, 1.3, GOLD, verts=6,
                        rot=(0, -k * 0.19, 0))
                cyl(f"Scales_pan{s}", (s * 1.8, 7.5, z + 2.05), 0.55, 0.06, GOLD, verts=24)
            cone("Scales_feather", (-1.8, 7.5, z + 2.55), 0.11, 0.02, 0.9, LINEN, verts=8, scale=(0.35, 1, 1))
            sphere("Scales_heart", (1.8, 7.5, z + 2.25), 0.18, REDOCHRE)
        # nagykapu az Asztrális Kamrához, felette szárnyas napkorong
        door("astral", (0, L / 2 - 0.05, 0), 'y', width=4.4, height=8.0, facing=1)
        cyl("Hall_sundisk", (0, L / 2 - 0.25, 11.0), 0.95, 0.3, GOLD, verts=32, rot=(math.pi / 2, 0, 0))
        for s in (-1, 1):
            box(f"Hall_wing{s}", (s * 2.6, L / 2 - 0.2, 11.0), (3.4, 0.2, 0.55), LAPIS)
            box(f"Hall_wingt{s}", (s * 2.4, L / 2 - 0.28, 10.65), (2.9, 0.15, 0.25), TURQ)
            box(f"Hall_wingg{s}", (s * 2.6, L / 2 - 0.3, 11.28), (3.4, 0.12, 0.08), GOLD)
        # ülő Ma'at-szobrok a kapu két oldalán
        statue_seated("Hall_statueL", (-5.6, 14.6, 0), facing_y=-1)
        statue_seated("Hall_statueR", (5.6, 14.6, 0), facing_y=-1)
        # oldalkapuk
        door("archive", (-W / 2 + 0.05, -7, 0), 'x', facing=-1)
        door("hieroglyphs", (-W / 2 + 0.05, 6, 0), 'x', facing=-1)
        door("memories", (W / 2 - 0.05, -7, 0), 'x', facing=1)
        door("garden", (W / 2 - 0.05, 6, 0), 'x', facing=1)
        door("forgotten", (-9.6, L / 2 - 0.05, 0), 'y', width=2.6, height=5.0, sealed=True, facing=1)
        # parázstartók
        for i, (x, y) in enumerate([(-4, -4), (4, -4), (-4, 3), (4, 3)]):
            brazier(f"Hall_brazier{i}", (x, y, 0), f"Light_hall_{i}")
        for i, (x, y) in enumerate([(-11, -14), (11, -14), (-11, 12), (11, 12)]):
            empty(f"Light_hall_w{i}", (x, y, 6))
        # repedések és törmelék (alacsony Ma'at)
        for i in range(8):
            crack(f"Crack_hall_f{i}", 'floor', (random.uniform(-10, 10), random.uniform(-14, 12), 0.0),
                  length=random.uniform(1.5, 3.5))
        for i in range(5):
            crack(f"Crack_hall_wl{i}", 'wall_x', (-W / 2 + 0.02, random.uniform(-14, 14), random.uniform(1.5, 10)),
                  length=random.uniform(1.5, 3.0))
            crack(f"Crack_hall_wr{i}", 'wall_x', (W / 2 - 0.02, random.uniform(-14, 14), random.uniform(1.5, 10)),
                  length=random.uniform(1.5, 3.0))
        for i in range(10):
            s = random.choice([-1, 1])
            rubble(f"Rubble_hall_{i}", (s * 7.5 + random.uniform(-1.6, 1.6), random.uniform(-12, 10), 0))
        for i, p in enumerate([(-4, -10, 1.5), (4, -2, 1.8), (-3, 4, 1.6), (5, -12, 1.4), (-10, 0, 2.0), (10, 2, 2.0)]):
            empty(f"Ghost_hall_{i}", p)
        empty("Cam_hall", (0, -14.8, 3.5))
        empty("Look_hall", (0, 8.0, 3.4))


# ================================================================ 2. LELKEK ARCHÍVUMA
def shelf(name, loc, axis, facing=1):
    x, y, z = loc
    parts = []
    w, d, h = 3.4, 0.8, 6.0
    if axis == 'x':  # a polc hossza x mentén, a falnak háttal y-ban
        parts.append(box(f"{name}_frame", (x, y, h / 2), (w, d, h), WOOD))
        for k in range(5):
            zz = 0.6 + k * 1.15
            parts.append(box(f"{name}_cavity{k}", (x, y - 0.06, zz + 0.5), (w - 0.25, d - 0.1, 0.92), BASALT))
            for j in range(8):
                parts.append(cyl(f"{name}_scroll{k}_{j}", (x - w / 2 + 0.35 + j * 0.38, y - 0.12, zz + 0.2), 0.13,
                                 0.7, PAPYRUS, verts=8, rot=(math.pi / 2, 0, 0)))
    else:
        parts.append(box(f"{name}_frame", (x, y, h / 2), (d, w, h), WOOD))
        for k in range(5):
            zz = 0.6 + k * 1.15
            parts.append(box(f"{name}_cavity{k}", (x - facing * 0.06, y, zz + 0.5), (d - 0.1, w - 0.25, 0.92), BASALT))
            for j in range(8):
                parts.append(cyl(f"{name}_scroll{k}_{j}", (x - facing * 0.12, y - w / 2 + 0.35 + j * 0.38, zz + 0.2), 0.13, 0.7,
                                 PAPYRUS, verts=8, rot=(0, math.pi / 2, 0)))
    return join(parts, name)


def oil_lamp(name, loc, light):
    x, y, z = loc
    p = [cyl(f"{name}_stand", (x, y, z + 0.8), 0.06, 1.6, GOLD, verts=8),
         cyl(f"{name}_foot", (x, y, z + 0.05), 0.3, 0.1, GOLD, verts=16),
         cone(f"{name}_cup", (x, y, z + 1.7), 0.08, 0.3, 0.2, GOLD, verts=16)]
    join(p, name)
    ico(f"Flame_{name}", (x, y, z + 1.9), 0.13, FLAME, sub=2, scale=(1, 1, 1.8))
    empty(light, (x, y, z + 2.2))


def build_archive():
    cx, cy = -60, 0
    with Group("Room_archive"):
        W, L, H = 20, 24, 9
        room_shell("Archive", (cx, cy), (W, L), H, SAND, LIME, star_count=50)
        for i in range(5):
            box(f"Archive_floorinlay{i}", (cx, cy - 10 + i * 5, 0.02), (W - 2, 0.12, 0.04), OCHRE)
        for s in (-1, 1):
            box(f"Archive_glyphband{s}", (cx + s * (W / 2 - 0.05), cy, 7.3), (0.1, L - 2, 1.2), GLYPH)
            kheker_frieze(f"Archive_frieze{s}", cy - 11.5, cy + 11.5, (cx + s * (W / 2 - 0.1), H - 0.8), 'y')
        # polcok
        with Group("Interact_shelves"):
            for j, x in enumerate([-6.0, -2.0, 2.0, 6.0]):
                shelf(f"Archive_shelfB{j}", (cx + x, cy + L / 2 - 0.45, 0), 'x')
        for s in (-1, 1):
            for j, y in enumerate([-6.5, -2.5, 1.5, 5.5]):
                shelf(f"Archive_shelf{s}_{j}", (cx + s * (W / 2 - 0.45), cy + y, 0), 'y', facing=s)
        # olvasóasztal a nyomok tekercseivel
        with Group("Interact_table"):
            box("Archive_tabletop", (cx, cy + 1, 0.95), (4.2, 2.4, 0.16), WOOD)
            for sx in (-1, 1):
                for sy in (-1, 1):
                    box(f"Archive_leg{sx}{sy}", (cx + sx * 1.9, cy + 1 + sy * 1.0, 0.45), (0.18, 0.18, 0.9), WOOD)
            box("Archive_papyrus", (cx, cy + 1, 1.04), (2.4, 1.5, 0.02), PAPYRUS)
            cyl("Archive_inkpot", (cx + 1.6, cy + 1.6, 1.12), 0.1, 0.18, BASALT, verts=12)
            for k in range(9):
                a = k / 9 * math.tau
                cyl(f"Clue_{k + 1}", (cx + math.cos(a) * 1.55, cy + 1 + math.sin(a) * 0.8, 1.12), 0.07, 0.5,
                    MEMORY, verts=8, rot=(0, math.pi / 2, a))
        for i, (x, y) in enumerate([(-4, -8), (4, -8), (-4, 6), (4, 6)]):
            oil_lamp(f"Archive_lamp{i}", (cx + x, cy + y, 0), f"Light_archive_{i}")
        for i in range(6):
            crack(f"Crack_archive_{i}", 'wall_x', (cx + random.choice([-1, 1]) * (W / 2 - 0.02),
                                                   cy + random.uniform(-10, 10), random.uniform(1, 7)))
        for i in range(4):
            rubble(f"Rubble_archive_{i}", (cx + random.uniform(-7, 7), cy + random.uniform(-9, 9), 0), 4)
        for i, p in enumerate([(-5, -6, 1.5), (5, -2, 1.6), (0, 7, 1.5)]):
            empty(f"Ghost_archive_{i}", (cx + p[0], cy + p[1], p[2]))
        empty("Cam_archive", (cx, cy - 10.5, 3.6))
        empty("Look_archive", (cx, cy + 6, 2.0))


# ================================================================ 3. EMLÉKEK KAMRÁJA
def build_memories():
    cx, cy = 60, 0
    with Group("Room_memories"):
        W, L, H = 18, 20, 10
        room_shell("Memories", (cx, cy), (W, L), H, BASALT, BASALT, ceil_m=NIGHT, star_count=90)
        torus("Memories_ring", (cx, cy + 2, 0.02), 6.8, 0.06, TURQ, major_seg=64)
        torus("Memories_ring2", (cx, cy + 2, 0.02), 7.2, 0.03, GOLD, major_seg=64)
        for s in (-1, 1):
            box(f"Memories_glyph{s}", (cx + s * (W / 2 - 0.05), cy, 4.5), (0.1, L - 2, 4.0), GLYPH)
        box("Memories_glyphB", (cx, cy + L / 2 - 0.05, 4.5), (W - 2, 0.1, 4.0), GLYPH)
        with Group("Interact_pool"):
            cyl("Memories_poolrim", (cx, cy + 2, 0.25), 3.0, 0.5, LIME, verts=48)
            cyl("Water_memories", (cx, cy + 2, 0.46), 2.75, 0.06, WATER, verts=48)
            torus("Memories_poolgold", (cx, cy + 2, 0.5), 3.0, 0.05, GOLD, major_seg=64)
        for i in range(6):
            a = math.pi * (0.1 + 0.8 * i / 5)
            px, py = cx + math.cos(a) * 6.0, cy + 2 + math.sin(a) * 6.0
            cyl(f"Memories_ped{i}", (px, py, 0.6), 0.45, 1.2, LIME, verts=16)
            torus(f"Memories_pedgold{i}", (px, py, 1.2), 0.45, 0.03, GOLD)
            ico(f"Orb_{i + 1}", (px, py, 1.95), 0.35, MEMORY, sub=2)
        for i in range(4):
            crack(f"Crack_memories_{i}", 'floor', (cx + random.uniform(-6, 6), cy + random.uniform(-7, 7), 0.0))
        for i, p in enumerate([(-4, -4, 1.6), (4, 5, 1.8), (0, -6, 1.6)]):
            empty(f"Ghost_memories_{i}", (cx + p[0], cy + p[1], p[2]))
        empty("Light_memories_0", (cx, cy + 2, 3.0))
        empty("Cam_memories", (cx, cy - 8.6, 3.8))
        empty("Look_memories", (cx, cy + 3, 1.2))


# ================================================================ 4. NÁDMEZŐ KERTJE
def reed_cluster(name, loc, n=9):
    x, y, z = loc
    parts = []
    for i in range(n):
        h = random.uniform(1.4, 2.6)
        px, py = x + random.uniform(-0.6, 0.6), y + random.uniform(-0.6, 0.6)
        parts.append(cone(f"{name}_r{i}", (px, py, z + h / 2), 0.05, 0.015, h, PLANT, verts=5,
                          rot=(random.uniform(-0.12, 0.12), random.uniform(-0.12, 0.12), 0), smooth=False))
        if random.random() < 0.5:
            parts.append(ico(f"{name}_h{i}", (px, py, z + h + 0.1), 0.12, OCHRE, sub=1, scale=(1, 1, 1.6)))
    return join(parts, name)


def palm(name, loc):
    x, y, z = loc
    parts = []
    hz = z
    for k in range(6):
        parts.append(cone(f"{name}_t{k}", (x, y, hz + 0.45), 0.24 - k * 0.015, 0.2 - k * 0.015, 0.9, WOOD, verts=8))
        hz += 0.85
    for k in range(8):
        a = k * math.tau / 8
        parts.append(box(f"{name}_leaf{k}", (x + math.cos(a) * 1.1, y + math.sin(a) * 1.1, hz - 0.2),
                         (2.2, 0.45, 0.05), PLANT, rot=(0, 0.45, a)))
    return join(parts, name)


def build_garden():
    cx, cy = 0, -60
    with Group("Room_garden"):
        W, L = 32, 30
        box("Garden_floor", (cx, cy, -0.25), (W, L, 0.5), SANDFLOOR)
        for s in (-1, 1):
            box(f"Garden_wall{s}", (cx + s * (W / 2 + 0.4), cy, 1.25), (0.8, L, 2.5), LIME)
            box(f"Garden_walltop{s}", (cx + s * (W / 2 + 0.4), cy, 2.55), (1.0, L, 0.12), GOLD)
        box("Garden_wallB", (cx, cy + L / 2 + 0.4, 1.25), (W + 1.6, 0.8, 2.5), LIME)
        box("Garden_wallF", (cx, cy - L / 2 - 0.4, 1.25), (W + 1.6, 0.8, 2.5), LIME)
        # pülonkapu a háttérben
        for s in (-1, 1):
            cone(f"Garden_pylon{s}", (cx + s * 4.2, cy + L / 2 + 0.6, 4.5), 3.0, 2.2, 9, SAND, verts=4,
                 rot=(0, 0, math.pi / 4), scale=(1, 0.35, 1), smooth=False)
        box("Garden_gate", (cx, cy + L / 2 + 0.7, 3.2), (2.8, 1.2, 6.4), LAPIS)
        box("Garden_gatelintel", (cx, cy + L / 2 + 0.6, 6.7), (4.0, 1.4, 0.7), GOLD)
        # a gyógyító forrás – medence és csatornák
        with Group("Interact_pool"):
            for s in (-1, 1):
                box(f"Garden_rimx{s}", (cx + s * 5.25, cy + 2, 0.25), (0.5, 7.0, 0.5), LIME)
                box(f"Garden_rimy{s}", (cx, cy + 2 + s * 3.25, 0.25), (11.0, 0.5, 0.5), LIME)
            box("Water_garden", (cx, cy + 2, 0.32), (10.0, 6.0, 0.08), WATER)
        for s in (-1, 1):
            box(f"Water_channel{s}", (cx + s * 9.5, cy + 2, 0.06), (1.2, 22, 0.06), WATER)
            box(f"Garden_channelrim{s}a", (cx + s * 8.75, cy + 2, 0.08), (0.3, 22, 0.16), LIME)
            box(f"Garden_channelrim{s}b", (cx + s * 10.25, cy + 2, 0.08), (0.3, 22, 0.16), LIME)
        for i in range(7):
            lx, ly = cx + random.uniform(-4.2, 4.2), cy + 2 + random.uniform(-2.3, 2.3)
            join([cyl(f"Lotus_{i}_pad", (lx, ly, 0.38), 0.35, 0.02, PLANT, verts=12),
                  cone(f"Lotus_{i}_fl", (lx, ly, 0.5), 0.16, 0.02, 0.25, LOTUS, verts=6)], f"Lotus_{i}")
        # nád és pálmák
        k = 0
        for s in (-1, 1):
            for y in range(-12, 14, 3):
                reed_cluster(f"Plant_reed_{k}", (cx + s * random.uniform(11.5, 14.5), cy + y, 0))
                k += 1
        for i in range(8):
            a = i / 8 * math.tau
            reed_cluster(f"Plant_reed_{k}", (cx + math.cos(a) * 6.8, cy + 2 + math.sin(a) * 4.6, 0), n=6)
            k += 1
        for i, (x, y) in enumerate([(-7, 10), (7, 10), (-13, -10), (13, -10), (-7, -8), (7, -8)]):
            palm(f"Plant_palm_{i}", (cx + x, cy + y, 0))
        for i in range(10):
            p = (cx + random.uniform(-14, 14), cy + random.uniform(-13, 13), 0)
            ico(f"Plant_bush_{i}", (p[0], p[1], 0.3), random.uniform(0.4, 0.7), PLANT, sub=2, scale=(1, 1, 0.7))
        for i in range(5):
            crack(f"Crack_garden_{i}", 'floor', (cx + random.uniform(-12, 12), cy + random.uniform(-12, 12), 0.0))
        for i, p in enumerate([(-4, -6, 1.2), (5, 6, 1.4), (-9, 2, 1.2), (9, -3, 1.3)]):
            empty(f"Ghost_garden_{i}", (cx + p[0], cy + p[1], p[2]))
        empty("Cam_garden", (cx, cy - 14.0, 4.4))
        empty("Look_garden", (cx, cy + 4, 0.6))


# ================================================================ 5. HIEROGLIFÁK KAMRÁJA
def build_hieroglyphs():
    cx, cy = 0, 60
    with Group("Room_hieroglyphs"):
        W, L, H = 20, 20, 11
        room_shell("Hiero", (cx, cy), (W, L), H, LIME, SAND, star_count=60)
        for s in (-1, 1):
            for r in range(3):
                box(f"Hiero_panel{s}_{r}", (cx + s * (W / 2 - 0.05), cy, 2.2 + r * 2.7), (0.1, L - 2, 2.3), GLYPH)
                box(f"Hiero_panelgold{s}_{r}", (cx + s * (W / 2 - 0.08), cy, 3.42 + r * 2.7), (0.12, L - 2, 0.1), GOLD)
        for r in range(3):
            box(f"Hiero_panelB_{r}", (cx, cy + L / 2 - 0.05, 2.2 + r * 2.7), (W - 2, 0.1, 2.3), GLYPH)
        with Group("Interact_obelisk"):
            box("Hiero_obeliskbase", (cx, cy + 2, 0.4), (2.6, 2.6, 0.8), BASALT)
            cone("Hiero_obelisk", (cx, cy + 2, 4.8), 1.0, 0.62, 8.0, GLYPH, verts=4, rot=(0, 0, math.pi / 4),
                 smooth=False)
            cone("Hiero_pyramidion", (cx, cy + 2, 9.25), 0.62, 0.0, 0.9, GOLD, verts=4, rot=(0, 0, math.pi / 4),
                 smooth=False)
        with Group("Interact_tablets"):
            for i, x in enumerate([-5.5, 5.5]):
                box(f"Hiero_stela{i}", (cx + x, cy + 5, 1.4), (1.6, 0.4, 2.8), BASALT)
                cyl(f"Hiero_stelatop{i}", (cx + x, cy + 5, 2.8), 0.8, 0.4, BASALT, verts=24, rot=(math.pi / 2, 0, 0))
                box(f"Hiero_stelaface{i}", (cx + x, cy + 4.78, 1.6), (1.3, 0.05, 2.2), GLYPH)
        for i, (x, y) in enumerate([(-7, -6), (7, -6), (-7, 6), (7, 6)]):
            oil_lamp(f"Hiero_lamp{i}", (cx + x, cy + y, 0), f"Light_hieroglyphs_{i}")
        for i in range(6):
            crack(f"Crack_hiero_{i}", 'wall_x', (cx + random.choice([-1, 1]) * (W / 2 - 0.02),
                                                 cy + random.uniform(-8, 8), random.uniform(1, 9)))
        for i, p in enumerate([(-4, -4, 1.5), (4, 3, 1.7)]):
            empty(f"Ghost_hieroglyphs_{i}", (cx + p[0], cy + p[1], p[2]))
        empty("Cam_hieroglyphs", (cx, cy - 8.8, 3.6))
        empty("Look_hieroglyphs", (cx, cy + 4, 3.4))


# ================================================================ 6. ELFELEDETT SZÁRNY
def build_forgotten():
    cx, cy = -60, 60
    with Group("Room_forgotten"):
        W, L, H = 20, 26, 9
        room_shell("Forgotten", (cx, cy), (W, L), H, BASALT, BASALT, ceil_m=NIGHT, star_count=0)
        for s in (-1, 1):
            box(f"Forgotten_glyph{s}", (cx + s * (W / 2 - 0.05), cy, 4.0), (0.1, L - 2, 2.0), GLYPH)
        # törött oszlopok
        for i, (x, y) in enumerate([(-6, -6), (6, -6), (-6, 2), (6, 2), (-6, 9), (6, 9)]):
            column(f"Forgotten_col{i}", cx + x, cy + y, height=random.uniform(2.0, 6.0), broken=True,
                   tilt=random.uniform(-0.06, 0.06))
        cyl("Forgotten_fallen", (cx + 3.5, cy - 2, 0.9), 0.9, 4.5, SAND, verts=20, rot=(0, math.pi / 2, 0.4))
        # szarkofágok kitörölt nevekkel
        with Group("Interact_sarcophagi"):
            for i, x in enumerate([-3.6, -1.2, 1.2, 3.6]):
                box(f"Sarc_{i + 1}", (cx + x, cy + 1, 0.55), (1.3, 2.7, 1.1), BASALT)
                box(f"Sarc_{i + 1}_lid", (cx + x, cy + 1.1, 1.18), (1.4, 2.8, 0.18), BASALT)
                box(f"Sarc_{i + 1}_name", (cx + x, cy - 0.38, 0.6), (0.9, 0.04, 0.7), GLYPH)
        for i, x in enumerate([-3.6, -1.2, 1.2, 3.6]):
            box(f"Sarc_back{i}", (cx + x, cy + 6, 0.55), (1.3, 2.7, 1.1), BASALT)
        # a lepecsételt belső ajtó
        with Group("Interact_mystery_door"):
            box("Seal_mystery", (cx, cy + L / 2 - 0.2, 3.0), (4.0, 0.4, 6.0), BASALT)
            torus("Forgotten_sealring", (cx, cy + L / 2 - 0.45, 3.4), 1.0, 0.07, GOLD, rot=(math.pi / 2, 0, 0))
            box("Forgotten_sealglyph", (cx, cy + L / 2 - 0.42, 1.4), (2.0, 0.05, 0.8), GLYPH)
        for i in range(10):
            crack(f"Crack_forgotten_{i}", 'floor', (cx + random.uniform(-8, 8), cy + random.uniform(-11, 11), 0.0),
                  length=3.0)
        for i in range(8):
            rubble(f"Rubble_forgotten_{i}", (cx + random.uniform(-8, 8), cy + random.uniform(-11, 11), 0), 6)
        for i, p in enumerate([(-5, -8, 1.5), (5, -4, 1.7), (-3, 4, 1.6), (4, 9, 1.8), (0, -2, 2.0)]):
            empty(f"Ghost_forgotten_{i}", (cx + p[0], cy + p[1], p[2]))
        empty("Light_forgotten_0", (cx, cy - 2, 4.0))
        empty("Light_forgotten_1", (cx, cy + 8, 4.0))
        empty("Cam_forgotten", (cx, cy - 11.5, 3.4))
        empty("Look_forgotten", (cx, cy + 6, 1.8))


# ================================================================ 7. ASZTRÁLIS KAMRA
def build_astral():
    cx, cy = 60, 60
    with Group("Room_astral"):
        dome = sphere("Astral_dome", (cx, cy, 0), 14.0, NIGHT, seg=48, ring=24)
        flip(dome)
        box("Astral_ground", (cx, cy, -0.6), (30, 30, 1.0), BASALT)
        parts = []
        for i in range(220):
            th = random.uniform(0, math.tau)
            ph = random.uniform(0.08, math.pi / 2 - 0.05)
            r = 13.7
            parts.append(ico(f"Astral_star{i}", (cx + math.cos(th) * math.cos(ph) * r,
                                                 cy + math.sin(th) * math.cos(ph) * r, math.sin(ph) * r),
                             random.uniform(0.05, 0.12), STAR, sub=1))
        join(parts, "Astral_stars")
        cyl("Astral_platform", (cx, cy, 0.25), 9.0, 0.5, BASALT, verts=64)
        torus("Astral_ring", (cx, cy, 0.52), 7.0, 0.08, GOLD, major_seg=96)
        torus("Astral_ring2", (cx, cy, 0.52), 3.2, 0.06, TURQ, major_seg=64)
        for i in range(12):
            a = i / 12 * math.tau
            box(f"Astral_mark{i}", (cx + math.cos(a) * 7.0, cy + math.sin(a) * 7.0, 0.53), (0.6, 0.12, 0.04),
                GOLD, rot=(0, 0, a))
        with Group("Interact_altar"):
            box("Astral_altar", (cx, cy + 1, 1.1), (1.6, 1.0, 1.2), LIME)
            box("Astral_altartop", (cx, cy + 1, 1.75), (1.8, 1.2, 0.1), GOLD)
            cone("Astral_bowl", (cx, cy + 1, 1.95), 0.15, 0.4, 0.3, GOLD, verts=16)
            ico("Flame_astral", (cx, cy + 1, 2.25), 0.2, MEMORY, sub=2, scale=(1, 1, 1.8))
        empty("Light_astral_0", (cx, cy + 1, 3.0))
        with Group("Interact_thoth"):
            standing_god("Astral_thoth", (cx - 5.0, cy + 5.2, 0.5), 'ibis')
        with Group("Interact_anubis"):
            standing_god("Astral_anubis", (cx + 5.0, cy + 5.2, 0.5), 'jackal')
        with Group("Interact_maat"):
            statue_seated("Astral_maat", (cx, cy + 7.2, 0.5), facing_y=-1, head_mat=LAPIS)
        for i, p in enumerate([(-4, -3, 2.0), (4, -2, 2.2), (0, 4, 2.6)]):
            empty(f"Ghost_astral_{i}", (cx + p[0], cy + p[1], p[2]))
        empty("Cam_astral", (cx, cy - 8.5, 3.4))
        empty("Look_astral", (cx, cy + 4, 2.8))


# ================================================================ kellékek a 3D-s vizsgálathoz
def build_props():
    global PARENT
    # K08 – kettős pecsét agyagtáblán
    for o in list(bpy.data.objects):
        o.select_set(False)
    objs = []
    PARENT[0] = None
    objs.append(box("Prop_K08_tablet", (0, 0, 0), (1.7, 1.15, 0.24), CLAY))
    objs.append(cyl("Prop_K08_sealA", (-0.38, 0.05, 0.13), 0.33, 0.05, REDOCHRE, verts=32))
    objs.append(cyl("Prop_K08_sealB", (0.36, -0.02, 0.135), 0.35, 0.06, CLAY, verts=32, scale=(1.04, 0.98, 1)))
    objs.append(torus("Prop_K08_ringA", (-0.38, 0.05, 0.16), 0.3, 0.02, REDOCHRE))
    objs.append(torus("Prop_K08_ringB", (0.36, -0.02, 0.17), 0.32, 0.025, BASALT))
    for i in range(6):
        objs.append(box(f"Prop_K08_glyph{i}", (-0.7 + i * 0.28, -0.45, 0.125), (0.12, 0.06, 0.02), BASALT))
        objs.append(box(f"Prop_K08_glyphb{i}", (-0.7 + i * 0.28, 0.45, 0.125), (0.1, 0.05, 0.02), BASALT))
    objs.append(box("Prop_K08_crack", (0.0, 0.0, 0.123), (0.04, 0.9, 0.02), BASALT, rot=(0, 0, 0.3)))
    # a hátoldalon egy rejtett jel – a csak forgatással látható „arany kéz”
    objs.append(box("Prop_K08_handpalm", (0.0, 0.0, -0.125), (0.26, 0.3, 0.02), GOLD))
    for i in range(4):
        objs.append(box(f"Prop_K08_finger{i}", (-0.09 + i * 0.06, 0.24, -0.125), (0.04, 0.2, 0.02), GOLD))
    k08 = join(objs, "Prop_K08")
    export_selected(k08, "prop_k08.glb")
    k08.hide_set(True)

    # hajó (K12 hajójegyzék kísérője)
    objs = []
    hull = sphere("Prop_ship_hull", (0, 0, 0), 1.0, WOOD, seg=24, ring=12, scale=(2.6, 0.55, 0.45))
    objs.append(hull)
    objs.append(box("Prop_ship_deck", (0, 0, 0.12), (4.2, 0.8, 0.06), PAPYRUS))
    objs.append(cyl("Prop_ship_mast", (0, 0, 1.4), 0.05, 2.6, WOOD, verts=8))
    objs.append(box("Prop_ship_sail", (0.05, 0, 1.6), (0.04, 1.6, 1.8), LINEN, rot=(0, 0, math.pi / 2)))
    objs.append(box("Prop_ship_yard", (0, 0, 2.5), (0.06, 1.8, 0.06), WOOD, rot=(0, 0, math.pi / 2)))
    objs.append(box("Prop_ship_cabin", (-0.9, 0, 0.35), (0.9, 0.6, 0.45), OCHRE))
    objs.append(cyl("Prop_ship_eye", (2.1, 0.0, 0.35), 0.12, 0.62, LAPIS, verts=16, rot=(math.pi / 2, 0, 0)))
    for s in (-1, 1):
        objs.append(box(f"Prop_ship_oar{s}", (-2.1, s * 0.4, 0.3), (1.4, 0.06, 0.06), WOOD, rot=(0, 0.5, s * 0.3)))
    ship = join(objs, "Prop_ship")
    ship.location = (0, 0, 0)
    export_selected(ship, "prop_ship.glb")
    ship.hide_set(True)

    # N06 – két születési karperec (Nefru esete)
    objs = []
    for k, (x, m, mark) in enumerate([(-0.7, TURQ, LAPIS), (0.7, REDOCHRE, GOLD)]):
        objs.append(torus(f"Prop_N06_band{k}", (x, 0, 0), 0.5, 0.05, LINEN, major_seg=48, minor_seg=8))
        for i in range(14):
            a2 = i / 14 * math.tau
            objs.append(ico(f"Prop_N06_bead{k}_{i}", (x + math.cos(a2) * 0.5, math.sin(a2) * 0.5, 0), 0.07,
                            m if i % 3 else GOLD, sub=1))
        # a családjelek: kis agyagtáblácska – az egyiken a jel utólag átkarcolva
        objs.append(box(f"Prop_N06_tag{k}", (x, -0.62, -0.02), (0.26, 0.18, 0.05), CLAY))
        objs.append(box(f"Prop_N06_mark{k}", (x, -0.62, 0.012), (0.14, 0.04, 0.02), mark))
        if k == 1:
            objs.append(box("Prop_N06_scratch", (x, -0.62, 0.02), (0.2, 0.015, 0.02), BASALT, rot=(0, 0, 0.6)))
    n06 = join(objs, "Prop_N06")
    export_selected(n06, "prop_n06.glb")
    n06.hide_set(True)

    # H05 – a magtár kulcsai (Hori esete)
    objs = [torus("Prop_H05_ring", (0, 0, 0), 0.45, 0.04, GOLD, major_seg=48)]
    for k in range(3):
        a2 = -math.pi / 2 + (k - 1) * 0.45
        cx, cy = math.cos(a2) * 0.45, math.sin(a2) * 0.45
        ln = 1.1 + k * 0.15
        dx, dy = math.cos(a2), math.sin(a2)
        objs.append(cyl(f"Prop_H05_shaft{k}", (cx + dx * ln / 2, cy + dy * ln / 2, 0), 0.045, ln, GOLD if k != 1 else WOOD,
                        verts=10, rot=(0, math.pi / 2, a2)))
        tx, ty = cx + dx * ln, cy + dy * ln
        for t in range(2 + k):
            objs.append(box(f"Prop_H05_tooth{k}_{t}", (tx - dx * 0.12 * t + dy * 0.08, ty - dy * 0.12 * t - dx * 0.08, 0),
                            (0.06, 0.06, 0.06), GOLD if k != 1 else WOOD))
    # a középső, fa kulcson Panehsy jele
    objs.append(box("Prop_H05_tag", (0.0, -1.1, 0.0), (0.22, 0.14, 0.04), CLAY))
    objs.append(box("Prop_H05_tagmark", (0.0, -1.1, 0.025), (0.12, 0.03, 0.02), GOLD))
    h05 = join(objs, "Prop_H05")
    export_selected(h05, "prop_h05.glb")
    h05.hide_set(True)


def export_selected(obj, filename):
    bpy.ops.object.select_all(action='DESELECT')
    obj.hide_set(False)
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT_DIR, filename), export_format='GLB',
                              use_selection=True, export_apply=True, export_yup=True)
    print("EXPORTED", filename)


# ================================================================ futtatás
build_props()
for o in list(bpy.data.objects):
    if o.name.startswith("Prop_"):
        bpy.data.objects.remove(o, do_unlink=True)

if "props" in argv:
    sys.exit(0)

build_hall()
build_archive()
build_memories()
build_garden()
build_hieroglyphs()
build_forgotten()
build_astral()

bpy.ops.object.select_all(action='DESELECT')
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT_DIR, "temple.glb"), export_format='GLB',
                          use_selection=False, export_apply=True, export_yup=True)
print("EXPORTED temple.glb, objects:", len(bpy.data.objects))
