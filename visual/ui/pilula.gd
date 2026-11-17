extends PanelContainer
# Pílula: cápsula com rótulo opcional e um valor (ex.: "Moedas 120", "Vidas 5").
# Só apresenta; quem decide o valor é quem a usa (a regra mora no Core).

const T = preload("res://visual/tema/cv_tokens.gd")
const Tema = preload("res://visual/tema/cv_tema.gd")

var rotulo: Label
var valor: Label

func _init(texto_rotulo: String = "", texto_valor: String = "", cor_borda: Color = T.OURO) -> void:
	add_theme_stylebox_override("panel", Tema.estilo_pilula(T.VISOR_FUNDO, cor_borda))
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var caixa := HBoxContainer.new()
	caixa.add_theme_constant_override("separation", 8)
	caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(caixa)
	rotulo = _novo_label(T.TAM_FONTE_PEQUENA, T.OURO_CLARO)
	valor = _novo_label(T.TAM_FONTE_CORPO, T.TEXTO)
	caixa.add_child(rotulo)
	caixa.add_child(valor)
	definir(texto_rotulo, texto_valor)

func definir(texto_rotulo: String, texto_valor: String) -> void:
	rotulo.text = texto_rotulo
	rotulo.visible = texto_rotulo != ""
	valor.text = texto_valor

func definir_valor(texto_valor: String) -> void:
	valor.text = texto_valor

func _novo_label(tam: int, cor: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", cor)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
