extends PanelContainer
# Dock inferior roxo com borda dourada: Desfazer, Dica e +1 Tubo, cada um com badge vermelho.
# Não decide regra: os botões só emitem a intenção; main.gd chama o Core e chama atualizar().

signal desfazer_pedido
signal dica_pedida
signal tubo_pedido

const T = preload("res://visual/tema/cv_tokens.gd")
const Tema = preload("res://visual/tema/cv_tema.gd")
const BotaoJuicy = preload("res://visual/ui/botao_juicy.gd")
const Badge = preload("res://visual/ui/badge.gd")

const TAM_BOTAO_PODER := Vector2(180, 84)

var botao_desfazer: Button
var botao_dica: Button
var botao_tubo: Button
var badge_desfazer: Label
var badge_dica: Label
var badge_tubo: Label

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP  # clique no dock não vaza para os tubos
	var e := Tema.estilo_pilula(T.ROXO_ESCURO, T.OURO)
	e.set_corner_radius_all(T.RAIO_PAINEL + 14)
	e.content_margin_top = 14
	e.content_margin_bottom = 14
	add_theme_stylebox_override("panel", e)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 14)
	linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(linha)
	var d := _poder("Desfazer", T.BOTAO_SECUNDARIO, linha)
	botao_desfazer = d[0]; badge_desfazer = d[1]
	var h := _poder("Dica", T.BOTAO_OURO, linha)
	botao_dica = h[0]; badge_dica = h[1]
	var t := _poder("+1 Tubo", T.BOTAO_PRIMARIO, linha)
	botao_tubo = t[0]; badge_tubo = t[1]
	botao_desfazer.pressed.connect(func() -> void: desfazer_pedido.emit())
	botao_dica.pressed.connect(func() -> void: dica_pedida.emit())
	botao_tubo.pressed.connect(func() -> void: tubo_pedido.emit())
	badge_dica.visible = false  # o Core ainda não tem quantidade de dicas (economia: Fase 5)

# Botão + badge no canto superior direito. Retorna [botao, badge].
func _poder(texto: String, cor: Color, pai: Control) -> Array:
	var moldura := Control.new()
	moldura.custom_minimum_size = TAM_BOTAO_PODER
	moldura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var b: Button = BotaoJuicy.new()
	b.text = texto
	b.cor_base = cor
	b.custom_minimum_size = TAM_BOTAO_PODER
	b.set_anchors_preset(Control.PRESET_FULL_RECT)
	moldura.add_child(b)
	var badge := Badge.new()
	badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	badge.position = Vector2(TAM_BOTAO_PODER.x - Badge.TAMANHO * 0.7, -Badge.TAMANHO * 0.4)
	moldura.add_child(badge)
	pai.add_child(moldura)
	return [b, badge]

# Reflete o estado do Core (habilita/desabilita e atualiza os números).
func atualizar(tabuleiro: Tabuleiro) -> void:
	var desfazer_ok: bool = tabuleiro.pode_desfazer()
	botao_desfazer.disabled = not desfazer_ok
	badge_desfazer.definir(tabuleiro.historico.tamanho())
	var vitoria: bool = tabuleiro.is_vitoria()
	botao_dica.disabled = vitoria
	var restantes: int = tabuleiro.MAX_TUBOS_AUXILIARES - tabuleiro.tubos_auxiliares()
	botao_tubo.disabled = not tabuleiro.pode_adicionar_tubo()
	badge_tubo.definir(maxi(restantes, 0))
