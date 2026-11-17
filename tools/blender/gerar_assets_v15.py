"""Gera assets 3D (PNG RGBA 512x512, fundo transparente) para o ColorVessel.

Uso:
  "C:\\Program Files\\Blender Foundation\\Blender 5.3\\blender.exe" --background --python tools/blender/gerar_assets_v15.py

Saida: visual/assets/blender/{tubo_vidro_3d,bloco_gelatina_3d,icone_moeda,icone_coracao}.png
"""
import math
import os
import sys

import bpy
import bmesh
from mathutils import Vector

RES = 512
SAMPLES = 96


def _raiz_projeto():
    try:
        aqui = os.path.dirname(os.path.abspath(__file__))
    except NameError:
        aqui = os.getcwd()
    cand = os.path.abspath(os.path.join(aqui, "..", ".."))
    if os.path.isdir(os.path.join(cand, "visual")):
        return cand
    return os.getcwd()


OUT_DIR = os.path.join(_raiz_projeto(), "visual", "assets", "blender")


# ---------------------------------------------------------------- utilidades
def limpar_cena():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    for blk in (bpy.data.meshes, bpy.data.materials, bpy.data.curves):
        for item in list(blk):
            blk.remove(item)


def set_in(node, nomes, valor):
    """Define o primeiro input existente dentre `nomes` (compat. entre versoes)."""
    if isinstance(nomes, str):
        nomes = [nomes]
    for n in nomes:
        if n in node.inputs:
            node.inputs[n].default_value = valor
            return True
    return False


def material(nome, cor, rough=0.2, metal=0.0, transm=0.0, ior=1.45,
             coat=0.0, sss=0.0, alpha=1.0):
    m = bpy.data.materials.new(nome)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    set_in(b, "Base Color", cor)
    set_in(b, "Roughness", rough)
    set_in(b, "Metallic", metal)
    set_in(b, ["Transmission Weight", "Transmission"], transm)
    set_in(b, "IOR", ior)
    set_in(b, ["Coat Weight", "Clearcoat"], coat)
    set_in(b, ["Coat Roughness", "Clearcoat Roughness"], 0.03)
    set_in(b, ["Subsurface Weight", "Subsurface"], sss)
    set_in(b, "Subsurface Radius", (0.6, 0.6, 0.6))
    set_in(b, "Specular IOR Level", 0.6)
    set_in(b, "Alpha", alpha)
    return m


def malha_de(nome, verts, faces, mat, smooth=True, subsurf=0):
    me = bpy.data.meshes.new(nome)
    me.from_pydata(verts, [], faces)
    me.update()
    ob = bpy.data.objects.new(nome, me)
    bpy.context.collection.objects.link(ob)
    ob.data.materials.append(mat)
    if smooth:
        for p in me.polygons:
            p.use_smooth = True
    if subsurf:
        s = ob.modifiers.new("sub", "SUBSURF")
        s.levels = subsurf
        s.render_levels = subsurf
    return ob


def revolucao(nome, perfil, mat, seg=96, subsurf=0):
    """Gira um perfil [(r, z), ...] em torno do eixo Z."""
    verts, faces = [], []
    n = len(perfil)
    for i in range(seg):
        a = 2 * math.pi * i / seg
        ca, sa = math.cos(a), math.sin(a)
        for r, z in perfil:
            verts.append((r * ca, r * sa, z))
    for i in range(seg):
        j = (i + 1) % seg
        for k in range(n - 1):
            faces.append((i * n + k, j * n + k, j * n + k + 1, i * n + k + 1))
    ob = malha_de(nome, verts, faces, mat, True, subsurf)
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(ob.data)
    bm.free()
    return ob


def arco(cx, cz, r, a0, a1, passos):
    return [(cx + r * math.cos(math.radians(a0 + (a1 - a0) * t / passos)),
             cz + r * math.sin(math.radians(a0 + (a1 - a0) * t / passos)))
            for t in range(passos + 1)]


def luz_area(nome, loc, alvo, energia, tam, cor=(1, 1, 1)):
    d = bpy.data.lights.new(nome, "AREA")
    d.energy = energia
    d.size = tam
    d.color = cor
    ob = bpy.data.objects.new(nome, d)
    bpy.context.collection.objects.link(ob)
    ob.location = loc
    direc = Vector(alvo) - Vector(loc)
    ob.rotation_euler = direc.to_track_quat("-Z", "Y").to_euler()
    return ob


def configurar_estudio(escala_ortho, centro_z=0.0):
    sc = bpy.context.scene
    # Mundo: gradiente cinza claro -> reflexos limpos no vidro/ouro
    w = bpy.data.worlds.new("estudio")
    w.use_nodes = True
    bg = w.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = (0.9, 0.92, 0.95, 1)
    bg.inputs["Strength"].default_value = 0.6
    sc.world = w

    # Camera ortografica frontal (olhando para +Y)
    cd = bpy.data.cameras.new("cam")
    cd.type = "ORTHO"
    cd.ortho_scale = escala_ortho
    cam = bpy.data.objects.new("cam", cd)
    bpy.context.collection.objects.link(cam)
    cam.location = (0, -10, centro_z)
    cam.rotation_euler = (math.radians(90), 0, 0)
    sc.camera = cam

    alvo = (0, 0, centro_z)
    luz_area("key", (-3.5, -5, centro_z + 4), alvo, 900, 4, (1.0, 0.97, 0.92))
    luz_area("fill", (4, -5, centro_z + 0.5), alvo, 350, 5, (0.9, 0.95, 1.0))
    luz_area("rim", (3, 3, centro_z + 3), alvo, 600, 3)
    # Softbox estreita lateral para reflexo especular vertical no vidro
    luz_area("strip", (-4.5, -2.5, centro_z), alvo, 500, 1.2)

    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = SAMPLES
    sc.cycles.use_denoising = True
    sc.cycles.max_bounces = 12
    sc.cycles.transparent_max_bounces = 16
    sc.cycles.transmission_bounces = 12
    sc.render.film_transparent = True
    sc.render.resolution_x = RES
    sc.render.resolution_y = RES
    sc.render.resolution_percentage = 100
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGBA"
    sc.render.image_settings.color_depth = "8"
    try:
        sc.view_settings.view_transform = "Standard"
    except Exception:
        pass


def renderizar(nome_arquivo):
    os.makedirs(OUT_DIR, exist_ok=True)
    caminho = os.path.join(OUT_DIR, nome_arquivo)
    bpy.context.scene.render.filepath = caminho
    bpy.ops.render.render(write_still=True)
    print("[gerar_assets_v15] gerado:", caminho)


# ------------------------------------------------------------------- assets
def asset_tubo():
    limpar_cena()
    vidro = material("vidro", (0.92, 0.97, 1.0, 1), rough=0.02, transm=1.0,
                     ior=1.5, coat=0.5)
    raio, esp, alt = 0.8, 0.07, 3.2
    ri = raio - esp
    rb = 0.35  # raio da base suave
    rr = esp / 2  # raio do arredondamento da borda
    # Perfil fechado (parede de vidro com espessura): centro da base externa ->
    # parede externa -> borda arredondada -> parede interna -> fundo interno.
    p = [(0.0, 0.0)]
    p += arco(raio - rb, rb, rb, -90, 0, 8)[0:]           # base externa suave
    p += [(raio, alt - 0.05)]
    p += arco(raio - rr, alt - 0.05, rr, 0, 180, 8)[1:]   # borda superior
    p += [(ri, rb + 0.12)]
    p += arco(ri - rb * 0.8, rb * 0.8 + esp, rb * 0.8, 0, -90, 8)[1:]  # fundo interno
    p = [(max(r, 0.0), z) for r, z in p]
    ob = revolucao("tubo", p, vidro, seg=128, subsurf=1)
    ob.location = (0, 0, -alt / 2)
    # Leve liquido-sombra no fundo para dar leitura de volume (muito sutil)
    configurar_estudio(4.0)
    renderizar("tubo_vidro_3d.png")


def asset_gelatina():
    limpar_cena()
    gel = material("gelatina", (0.93, 0.93, 0.95, 1), rough=0.12, transm=0.35,
                   ior=1.38, coat=1.0, sss=0.6)
    seg_a, ribs = 192, 24
    h, R = 1.1, 1.45
    # Perfil lateral (z, raio base) com bordas arredondadas
    perfil = []
    perfil.append((0.0, 0.0))
    for r, z in arco(R - 0.3, 0.3, 0.3, -90, 0, 8):
        perfil.append((z, r))
    for r, z in arco(R - 0.3, h - 0.3, 0.3, 0, 90, 8)[1:]:
        perfil.append((z, r))
    perfil.append((h, 0.0))
    verts, faces = [], []
    n = len(perfil)
    for i in range(seg_a):
        a = 2 * math.pi * i / seg_a
        for z, r in perfil:
            # canelado: so na faixa lateral (longe dos polos)
            lateral = 1.0 if 0.01 < r < R + 1 and R - 0.31 < r else 0.0
            mod = 1.0 + lateral * 0.045 * math.cos(ribs * a)
            verts.append((r * mod * math.cos(a), r * mod * math.sin(a), z))
    for i in range(seg_a):
        j = (i + 1) % seg_a
        for k in range(n - 1):
            faces.append((i * n + k, j * n + k, j * n + k + 1, i * n + k + 1))
    ob = malha_de("gelatina", verts, faces, gel, True, 1)
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(ob.data)
    bm.free()
    ob.location = (0, 0, -h / 2)
    ob.rotation_euler = (math.radians(-62), 0, 0)  # vista 3/4 superior
    # recentra apos rotacao
    configurar_estudio(4.0)
    renderizar("bloco_gelatina_3d.png")


def asset_moeda():
    limpar_cena()
    ouro = material("ouro", (1.0, 0.68, 0.12, 1), rough=0.18, metal=1.0, coat=0.4)
    ouro_claro = material("ouro_rel", (1.0, 0.8, 0.28, 1), rough=0.12, metal=1.0, coat=0.5)
    R, esp = 1.5, 0.28
    # Moeda com aro elevado
    perfil = [(0.0, 0.0)]
    perfil += arco(R - 0.12, 0.12, 0.12, -90, 0, 6)
    perfil += [(R, esp - 0.12)]
    perfil += arco(R - 0.12, esp - 0.12, 0.12, 0, 90, 6)[1:]
    perfil += [(R - 0.3, esp), (R - 0.34, esp - 0.05), (R - 0.4, esp - 0.05), (0.0, esp - 0.05)]
    moeda = revolucao("moeda", perfil, ouro, seg=128, subsurf=1)
    # Aro interno com sulco
    # Estrela em relevo
    pts = []
    for i in range(10):
        r = 0.82 if i % 2 == 0 else 0.36
        a = math.radians(90 + 36 * i)
        pts.append((r * math.cos(a), r * math.sin(a)))
    bm = bmesh.new()
    vs = [bm.verts.new((x, y, esp - 0.05)) for x, y in pts]
    f = bm.faces.new(vs)
    r = bmesh.ops.extrude_face_region(bm, geom=[f])
    nv = [e for e in r["geom"] if isinstance(e, bmesh.types.BMVert)]
    bmesh.ops.translate(bm, verts=nv, vec=(0, 0, 0.16))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new("estrela")
    bm.to_mesh(me)
    bm.free()
    est = bpy.data.objects.new("estrela", me)
    bpy.context.collection.objects.link(est)
    est.data.materials.append(ouro_claro)
    bv = est.modifiers.new("bev", "BEVEL")
    bv.width = 0.05
    bv.segments = 4
    bv.limit_method = "ANGLE"
    sb = est.modifiers.new("sub", "SUBSURF")
    sb.levels = 1
    sb.render_levels = 2
    for p in me.polygons:
        p.use_smooth = True
    # Eixo Z da moeda -> aponta para a camera (-Y)
    for ob in (moeda, est):
        ob.rotation_euler = (math.radians(90), 0, 0)
        ob.location = (0, 0.1, 0)
        ob.rotation_euler = (math.radians(90), 0, math.radians(0))
    # Giro leve para brilho do aro
    for ob in (moeda, est):
        ob.rotation_euler = (math.radians(90 + 0), math.radians(0), math.radians(-12))
    configurar_estudio(3.8)
    # Mundo com mais contraste para o metal
    bpy.context.scene.world.node_tree.nodes["Background"].inputs["Strength"].default_value = 1.0
    renderizar("icone_moeda.png")


def asset_coracao():
    limpar_cena()
    verm = material("coracao", (0.9, 0.04, 0.1, 1), rough=0.08, coat=1.0, sss=0.25)
    pts = []
    N = 96
    for i in range(N):
        t = 2 * math.pi * i / N
        x = 16 * math.sin(t) ** 3
        y = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
        pts.append((x * 0.11, y * 0.11))
    cu = bpy.data.curves.new("coracao", "CURVE")
    cu.dimensions = "2D"
    cu.fill_mode = "BOTH"
    cu.extrude = 0.28
    cu.bevel_depth = 0.14
    cu.bevel_resolution = 8
    sp = cu.splines.new("POLY")
    sp.points.add(N - 1)
    for i, (x, y) in enumerate(pts):
        sp.points[i].co = (x, y, 0, 1)
    sp.use_cyclic_u = True
    ob = bpy.data.objects.new("coracao", cu)
    bpy.context.collection.objects.link(ob)
    ob.data.materials.append(verm)
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    bpy.ops.object.convert(target="MESH")
    ob = bpy.context.view_layer.objects.active
    for p in ob.data.polygons:
        p.use_smooth = True
    sb = ob.modifiers.new("sub", "SUBSURF")
    sb.levels = 1
    sb.render_levels = 2
    ob.rotation_euler = (math.radians(90), 0, 0)
    ob.location = (0, 0, -0.1)
    configurar_estudio(3.4)
    bpy.context.scene.world.node_tree.nodes["Background"].inputs["Strength"].default_value = 1.0
    renderizar("icone_coracao.png")


def main():
    print("[gerar_assets_v15] Blender", bpy.app.version_string, "->", OUT_DIR)
    for fn in (asset_tubo, asset_gelatina, asset_moeda, asset_coracao):
        fn()
    print("[gerar_assets_v15] concluido")


if __name__ == "__main__":
    main()
