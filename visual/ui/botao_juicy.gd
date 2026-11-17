extends Button
# Botão "juicy": corpo 3D colorido, brilho glossy e squash ao tocar.
# Animações são só visuais e ignoradas em modo headless (testes).

const T = preload("res://visual/tema/cv_tokens.gd")
const Tema = preload("res://visual/tema/cv_tema.gd")

@export var cor_base: Color = T.BOTAO_PRIMARIO:
	set(v):
		cor_base = v
		_aplicar_estilos()

var _tween: Tween

static func animacoes_ativas() -> bool:
	return DisplayServer.get_name() != "headless"

func _init() -> void:
	custom_minimum_size = T.TAM_BOTAO
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_theme_font_size_override("font_size", T.TAM_FONTE_CORPO)
	_aplicar_estilos()

func _ready() -> void:
	resized.connect(_centralizar_pivo)
	button_down.connect(_ao_apertar)
	button_up.connect(_ao_soltar)
	mouse_entered.connect(_ao_hover.bind(true))
	mouse_exited.connect(_ao_hover.bind(false))
	_centralizar_pivo()

func _aplicar_estilos() -> void:
	add_theme_color_override("font_color", T.TEXTO)
	add_theme_color_override("font_hover_color", Color.WHITE)
	add_theme_color_override("font_pressed_color", Color.WHITE)
	add_theme_color_override("font_disabled_color", T.NEUTRO)
	for estado in ["normal", "hover", "pressed", "disabled"]:
		add_theme_stylebox_override(estado, Tema.estilo_botao(cor_base, estado))
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _centralizar_pivo() -> void:
	pivot_offset = size / 2.0

func _draw() -> void:
	if not disabled:
		Tema.desenhar_gloss(self, Rect2(Vector2.ZERO, size))

func _animar_escala(alvo: float, dur: float, trans: Tween.TransitionType) -> void:
	if not animacoes_ativas() or not is_inside_tree():
		return
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2.ONE * alvo, dur) \
		.set_trans(trans).set_ease(Tween.EASE_OUT)

func _ao_apertar() -> void:
	_animar_escala(T.ESCALA_TOQUE, T.DURACAO_TOQUE, Tween.TRANS_SINE)

func _ao_soltar() -> void:
	_animar_escala(1.0, T.DURACAO_RETORNO, Tween.TRANS_ELASTIC)

func _ao_hover(dentro: bool) -> void:
	if not button_pressed:
		_animar_escala(T.ESCALA_HOVER if dentro and not disabled else 1.0, T.DURACAO_TOQUE, Tween.TRANS_SINE)
