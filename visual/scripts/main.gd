extends Node2D
# Visual (Arte Funcional): cena raiz. Orquestra HUD e progressão de fases; o tabuleiro em si
# (sprites, seleção, juice) vive em tabuleiro_view.gd. Os membros da view são expostos aqui
# como proxies para manter a API estável (testes e futuras telas).
# Não decide regra: vitória e jogadas válidas quem diz é o Core.

const TabuleiroClass = preload("res://core/src/tabuleiro.gd")
const TabuleiroViewClass = preload("res://visual/scripts/tabuleiro_view.gd")
const T = preload("res://visual/tema/cv_tokens.gd")
const Tema = preload("res://visual/tema/cv_tema.gd")
const BotaoJuicy = preload("res://visual/ui/botao_juicy.gd")
const Pilula = preload("res://visual/ui/pilula.gd")

const FASE_INICIAL: int = 1
const CORES_FASE_INICIAL: int = 2  # Fase 1 = 2 cores; cada fase soma 1
const MAX_CORES: int = 6           # teto: da Fase 5 em diante são sempre 6 cores

# Constantes da view re-exportadas (API estável).
const SEM_SELECAO: int = TabuleiroViewClass.SEM_SELECAO
const CORES: Dictionary = TabuleiroViewClass.CORES
const COR_DESCONHECIDA := TabuleiroViewClass.COR_DESCONHECIDA
const COR_FUNDO_FRIO := TabuleiroViewClass.COR_FUNDO_FRIO
const COR_FUNDO_QUENTE := TabuleiroViewClass.COR_FUNDO_QUENTE
const DURACAO_CALOR: float = TabuleiroViewClass.DURACAO_CALOR
const SQUASH_VELOCIDADE: float = TabuleiroViewClass.SQUASH_VELOCIDADE

const Y_HUD: float = 14.0
const TAM_FONTE_STATUS: int = T.TAM_FONTE_CORPO

var fase: int = FASE_INICIAL
var vista: Node2D  # TabuleiroView
var hud: PanelContainer
var pilula_fase: Pilula
var label_status: Label
var botao_proxima: Button

# --- Proxies para o estado/ações da view ---
var tabuleiro: Tabuleiro:
	get: return vista.tabuleiro
	set(v): vista.tabuleiro = v
var selecionado: int:
	get: return vista.selecionado
var calor: float:
	get: return vista.calor
	set(v): vista.calor = v
var tempo: float:
	get: return vista.tempo
	set(v): vista.tempo = v
var fundo: TextureRect:
	get: return vista.fundo
var tex_tubo: Texture2D:
	get: return vista.tex_tubo
var tex_bloco: Texture2D:
	get: return vista.tex_bloco
var sprites_tubos: Array[Sprite2D]:
	get: return vista.sprites_tubos
var sprites_blocos: Array:
	get: return vista.sprites_blocos

func _ready() -> void:
	vista = TabuleiroViewClass.new()
	vista.montado.connect(_atualizar_hud)
	vista.vitoria_celebrada.connect(_brilhar_hud)
	add_child(vista)
	_montar_hud()
	vista.tabuleiro = TabuleiroClass.new()
	iniciar_fase(FASE_INICIAL)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local := make_input_local(event) as InputEventMouseButton
		clicar_tubo(indice_tubo_em(local.position))
	elif event is InputEventKey and event.pressed and event.keycode == KEY_R:
		reiniciar()
	elif event is InputEventKey and event.pressed and event.keycode in [KEY_N, KEY_ENTER]:
		proxima_fase()

func clicar_tubo(idx: int) -> void:
	vista.clicar_tubo(idx)

func montar() -> void:
	vista.montar()

func rect_tubo(idx: int) -> Rect2:
	return vista.rect_tubo(idx)

func indice_tubo_em(pos: Vector2) -> int:
	return vista.indice_tubo_em(pos)

func cor_visual(cor: int) -> Color:
	return vista.cor_visual(cor)

func cor_fundo() -> Color:
	return vista.cor_fundo()

func alvo_calor() -> float:
	return vista.alvo_calor()

func escala_gelatina(idx: int) -> Vector2:
	return vista.escala_gelatina(idx)

func pulsar_tubo(idx: int) -> void:
	vista.pulsar_tubo(idx)

func celebrar_vitoria() -> void:
	vista.celebrar_vitoria()

# --- HUD "Visor Térmico" ---

func _novo_label(tam: int) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", T.TEXTO)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _montar_hud() -> void:
	hud = PanelContainer.new()
	hud.theme = Tema.criar_tema()
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE  # cliques passam para os tubos
	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 8)
	caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(caixa)
	pilula_fase = Pilula.new("FASE", "1")
	pilula_fase.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	label_status = _novo_label(TAM_FONTE_STATUS)
	caixa.add_child(pilula_fase)
	caixa.add_child(label_status)
	botao_proxima = BotaoJuicy.new()
	botao_proxima.text = "Próxima Fase"
	botao_proxima.pressed.connect(proxima_fase)
	caixa.add_child(botao_proxima)
	add_child(hud)
	hud.resized.connect(_centralizar_hud)

func _centralizar_hud() -> void:
	hud.position = Vector2((get_viewport_rect().size.x - hud.size.x) / 2.0, Y_HUD)

func _atualizar_hud() -> void:
	if hud == null:
		return
	pilula_fase.definir_valor(str(fase))
	var venceu: bool = tabuleiro.is_vitoria()
	label_status.text = "Vitória! (N/Enter: próxima fase)" if venceu else "R: reiniciar fase"
	botao_proxima.visible = venceu
	hud.reset_size()  # encolhe/expande conforme o botão aparece
	_centralizar_hud()

func _brilhar_hud() -> void:
	if hud == null:
		return
	hud.modulate = Color(1.6, 1.6, 1.6)
	hud.create_tween().tween_property(hud, "modulate", Color.WHITE, 0.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# --- Progressão de fases ---

static func cores_da_fase(f: int) -> int:
	return mini(CORES_FASE_INICIAL + f - FASE_INICIAL, MAX_CORES)

func iniciar_fase(f: int) -> void:
	fase = f
	vista.selecionar(SEM_SELECAO)
	tabuleiro.gerar_novo_jogo(cores_da_fase(fase))
	vista.montar()

# R: refaz a fase ATUAL (novo embaralhamento, mesma quantidade de cores).
func reiniciar() -> void:
	iniciar_fase(fase)

# Só avança se o Core disser que é vitória.
func proxima_fase() -> void:
	if tabuleiro.is_vitoria():
		iniciar_fase(fase + 1)
