extends Label
# Badge circular de contagem (ex.: poderes restantes). Some quando o valor é 0.

const T = preload("res://visual/tema/cv_tokens.gd")

const TAMANHO: float = 30.0

func _init(cor: Color = T.VERMELHO_ALERTA) -> void:
	custom_minimum_size = Vector2(TAMANHO, TAMANHO)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_font_size_override("font_size", T.TAM_FONTE_PEQUENA)
	add_theme_color_override("font_color", Color.WHITE)
	var e := StyleBoxFlat.new()
	e.bg_color = cor
	e.set_border_width_all(2)
	e.border_color = Color.WHITE
	e.set_corner_radius_all(int(TAMANHO))
	add_theme_stylebox_override("normal", e)

func definir(qtd: int) -> void:
	text = str(qtd)
	visible = qtd > 0
