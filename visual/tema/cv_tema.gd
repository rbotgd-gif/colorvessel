extends RefCounted
# Tema programático "Juicy Glossy": fábrica de StyleBoxes e do Theme global.
# Sem arquivos .tres: tudo derivado de CVTokens.

const T = preload("res://visual/tema/cv_tokens.gd")

# Fonte opcional: se o arquivo OFL não estiver no projeto, cai na fonte padrão.
static func fonte() -> Font:
	if ResourceLoader.exists(T.FONTE_CAMINHO):
		return load(T.FONTE_CAMINHO) as Font
	return null

# Painel "visor térmico": escuro translúcido, borda ciano e brilho suave.
static func estilo_visor(brilho: float = 1.0, raio: int = T.RAIO_PAINEL) -> StyleBoxFlat:
	var e := StyleBoxFlat.new()
	e.bg_color = T.VISOR_FUNDO
	e.set_border_width_all(2)
	e.border_color = Color(T.VISOR_BORDA, minf(T.VISOR_BORDA.a * brilho, 1.0))
	e.set_corner_radius_all(raio)
	e.shadow_color = Color(T.VISOR_BRILHO, minf(T.VISOR_BRILHO.a * brilho, 1.0))
	e.shadow_size = 8
	e.content_margin_left = T.MARGEM_H
	e.content_margin_right = T.MARGEM_H
	e.content_margin_top = T.MARGEM_V
	e.content_margin_bottom = T.MARGEM_V + 2
	return e

# Pílula: cápsula com borda dourada (contadores de moedas/vidas, rótulos).
static func estilo_pilula(fundo: Color = T.VISOR_FUNDO, borda: Color = T.OURO) -> StyleBoxFlat:
	var e := StyleBoxFlat.new()
	e.bg_color = fundo
	e.set_border_width_all(T.BORDA)
	e.border_color = borda
	e.set_corner_radius_all(T.RAIO_PILULA)
	e.shadow_color = Color(0, 0, 0, 0.35)
	e.shadow_size = 4
	e.shadow_offset = Vector2(0, 2)
	e.content_margin_left = 16
	e.content_margin_right = 16
	e.content_margin_top = 4
	e.content_margin_bottom = 4
	return e

# Botão juicy: corpo colorido, borda dourada e base grossa mais escura (3D).
# estado: "normal" | "hover" | "pressed" | "disabled"
static func estilo_botao(cor: Color, estado: String = "normal") -> StyleBoxFlat:
	var corpo: Color = cor
	var fundo_3d: Color = cor.darkened(0.35)
	var profundidade: int = T.PROFUNDIDADE_BOTAO
	match estado:
		"hover":
			corpo = cor.lightened(0.12)
		"pressed":
			corpo = cor.darkened(0.08)
			profundidade = 2  # afunda
		"disabled":
			corpo = T.NEUTRO.darkened(0.3)
			fundo_3d = corpo.darkened(0.3)
	var e := StyleBoxFlat.new()
	e.bg_color = corpo
	e.set_border_width_all(T.BORDA)
	e.border_width_bottom = T.BORDA + profundidade
	e.border_color = T.OURO if estado != "disabled" else T.NEUTRO
	e.set_corner_radius_all(T.RAIO_BOTAO)
	e.shadow_color = Color(fundo_3d, 0.55)
	e.shadow_size = 6
	e.shadow_offset = Vector2(0, 3)
	e.content_margin_left = T.MARGEM_H
	e.content_margin_right = T.MARGEM_H
	e.content_margin_top = 10
	e.content_margin_bottom = 10 + (T.PROFUNDIDADE_BOTAO - profundidade)
	return e

# Brilho "glossy": faixa clara translúcida na metade superior (desenhada por cima).
static func desenhar_gloss(canvas: CanvasItem, r: Rect2, raio: int = T.RAIO_BOTAO) -> void:
	var faixa := Rect2(r.position + Vector2(6, 4), Vector2(r.size.x - 12, r.size.y * 0.42))
	var e := StyleBoxFlat.new()
	e.bg_color = Color(1, 1, 1, 0.22)
	e.corner_radius_top_left = raio
	e.corner_radius_top_right = raio
	e.corner_radius_bottom_left = raio / 2
	e.corner_radius_bottom_right = raio / 2
	canvas.draw_style_box(e, faixa)

# Theme global (aplicável a qualquer raiz Control): botões, painéis e rótulos.
static func criar_tema() -> Theme:
	var th := Theme.new()
	var f: Font = fonte()
	if f:
		th.default_font = f
	th.default_font_size = T.TAM_FONTE_CORPO
	th.set_color("font_color", "Label", T.TEXTO)
	th.set_font_size("font_size", "Label", T.TAM_FONTE_CORPO)
	th.set_stylebox("panel", "PanelContainer", estilo_visor())
	th.set_color("font_color", "Button", T.TEXTO)
	th.set_color("font_hover_color", "Button", Color.WHITE)
	th.set_color("font_pressed_color", "Button", Color.WHITE)
	th.set_color("font_disabled_color", "Button", T.NEUTRO)
	th.set_stylebox("normal", "Button", estilo_botao(T.BOTAO_SECUNDARIO))
	th.set_stylebox("hover", "Button", estilo_botao(T.BOTAO_SECUNDARIO, "hover"))
	th.set_stylebox("pressed", "Button", estilo_botao(T.BOTAO_SECUNDARIO, "pressed"))
	th.set_stylebox("disabled", "Button", estilo_botao(T.BOTAO_SECUNDARIO, "disabled"))
	th.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	return th
