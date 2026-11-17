extends Node2D
# Visual (Arte Funcional): cena raiz. Orquestra HUD e progressão de fases; o tabuleiro em si
# (sprites, seleção, juice) vive em tabuleiro_view.gd. Os membros da view são expostos aqui
# como proxies para manter a API estável (testes e futuras telas).
# Não decide regra: vitória e jogadas válidas quem diz é o Core.

const TabuleiroClass = preload("res://core/src/tabuleiro.gd")
const TabuleiroViewClass = preload("res://visual/scripts/tabuleiro_view.gd")
const T = preload("res://visual/tema/cv_tokens.gd")
const Tema = preload("res://visual/tema/cv_tema.gd")
const HudSuperior = preload("res://visual/ui/hud_superior.gd")
const DockPoderes = preload("res://visual/ui/dock_poderes.gd")

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


var fase: int = FASE_INICIAL
var vista: Node2D  # TabuleiroView
var hud_superior: HudSuperior
var dock: DockPoderes
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
	move_child(vista, 0)
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

# --- HUD (Juicy Glossy) ---

func _montar_hud() -> void:
	# (CanvasLayer: os anchors resolvem contra a viewport, não contra o Node2D.) HUD, botão "Próxima Fase" e dock vêm da cena (anchors/offsets para 720x1280).
	var tema: Theme = Tema.criar_tema()
	hud_superior = $Interface/HudSuperior
	botao_proxima = $Interface/BotaoProxima
	dock = $Interface/DockPoderes
	for c: Control in [hud_superior, botao_proxima, dock]:
		c.theme = tema
	botao_proxima.pressed.connect(proxima_fase)
	dock.desfazer_pedido.connect(usar_desfazer)
	dock.dica_pedida.connect(usar_dica)
	dock.tubo_pedido.connect(usar_tubo)

func _atualizar_hud() -> void:
	if hud_superior == null:
		return
	hud_superior.definir_nivel(fase)
	botao_proxima.visible = tabuleiro.is_vitoria()
	dock.atualizar(tabuleiro)

func _brilhar_hud() -> void:
	if hud_superior == null:
		return
	hud_superior.modulate = Color(1.6, 1.6, 1.6)
	hud_superior.create_tween().tween_property(hud_superior, "modulate", Color.WHITE, 0.8) 		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# --- Poderes (a regra é do Core; aqui só intenção + remontar a partir do estado) ---

func usar_desfazer() -> bool:
	vista.selecionar(SEM_SELECAO)
	var ok: bool = tabuleiro.desfazer()
	vista.montar()
	return ok

func usar_tubo() -> bool:
	vista.selecionar(SEM_SELECAO)
	var ok: bool = tabuleiro.adicionar_tubo_auxiliar()
	vista.montar()
	return ok

# Destaca a origem da próxima jogada sugerida e pulsa o destino. false se não há dica.
func usar_dica() -> bool:
	var d: Vector2i = tabuleiro.dica()
	if d == Tabuleiro.SEM_DICA:
		return false
	vista.selecionar(d.x)
	vista.montar()
	vista.pulsar_tubo(d.y)
	return true

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
