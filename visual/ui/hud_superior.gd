extends HBoxContainer
# HUD superior "Juicy Glossy": pílula de moedas | pílula "Nível X" roxa com borda dourada | engrenagem.
# Só apresenta. O valor das moedas vem de fora (economia é do Core/meta, Fase 5).

signal configuracoes_pedidas

const T = preload("res://visual/tema/cv_tokens.gd")
const Tema = preload("res://visual/tema/cv_tema.gd")
const Pilula = preload("res://visual/ui/pilula.gd")
const BotaoJuicy = preload("res://visual/ui/botao_juicy.gd")
const CAMINHO_MOEDA := "res://visual/assets/blender/icone_moeda.png"

const TAM_ICONE: float = 36.0
const TAM_CONFIG: float = 64.0

var pilula_moedas: Pilula
var pilula_nivel: PanelContainer
var label_nivel: Label
var botao_config: Button

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 12)
	alignment = BoxContainer.ALIGNMENT_CENTER

	pilula_moedas = Pilula.new("", "0")
	if ResourceLoader.exists(CAMINHO_MOEDA):
		var icone := TextureRect.new()
		icone.texture = load(CAMINHO_MOEDA)
		icone.custom_minimum_size = Vector2(TAM_ICONE, TAM_ICONE)
		icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var caixa: HBoxContainer = pilula_moedas.get_child(0)
		caixa.add_child(icone)
		caixa.move_child(icone, 0)
	pilula_moedas.custom_minimum_size = Vector2(150, 52)
	add_child(pilula_moedas)

	pilula_nivel = PanelContainer.new()
	pilula_nivel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pilula_nivel.add_theme_stylebox_override("panel", Tema.estilo_pilula(T.ROXO, T.OURO))
	pilula_nivel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label_nivel = Label.new()
	label_nivel.text = "Nível 1"
	label_nivel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_nivel.add_theme_font_size_override("font_size", T.TAM_FONTE_TITULO)
	label_nivel.add_theme_color_override("font_color", T.TEXTO)
	label_nivel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pilula_nivel.add_child(label_nivel)
	add_child(pilula_nivel)

	botao_config = BotaoJuicy.new()
	botao_config.text = "⚙"
	botao_config.cor_base = T.ROXO
	botao_config.custom_minimum_size = Vector2(TAM_CONFIG, TAM_CONFIG)
	botao_config.add_theme_stylebox_override("normal", _circulo(T.ROXO))
	botao_config.add_theme_stylebox_override("hover", _circulo(T.ROXO.lightened(0.12)))
	botao_config.add_theme_stylebox_override("pressed", _circulo(T.ROXO.darkened(0.08)))
	botao_config.pressed.connect(func() -> void: configuracoes_pedidas.emit())
	add_child(botao_config)

func _circulo(cor: Color) -> StyleBoxFlat:
	var e := Tema.estilo_botao(cor)
	e.set_corner_radius_all(int(TAM_CONFIG))
	return e

func definir_nivel(n: int) -> void:
	label_nivel.text = "Nível %d" % n

func definir_moedas(qtd: int) -> void:
	pilula_moedas.definir_valor(str(qtd))
