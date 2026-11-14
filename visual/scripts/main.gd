extends Node2D
# Visual (Arte Funcional): desenha o Tabuleiro com _draw() e repassa intenções.
# Não decide regra: quem diz se a jogada vale é tabuleiro.mover_liquido().
# O único estado próprio do Visual é qual tubo está selecionado (estado de UI).

const TabuleiroClass = preload("res://core/src/tabuleiro.gd")

const QTD_CORES: int = 3
const SEM_SELECAO: int = -1

const LARGURA_TUBO: float = 60.0
const ALTURA_BLOCO: float = 40.0
const ESPACO_TUBOS: float = 30.0
const BORDA: float = 3.0
const FOLGA_BLOCO: float = 6.0
const ELEVACAO_SELECAO: float = 24.0

const COR_FUNDO := Color(0.12, 0.12, 0.16)
const COR_BORDA := Color(0.85, 0.85, 0.9)
const COR_BORDA_SELECAO := Color(1.0, 0.85, 0.2)
const COR_DESCONHECIDA := Color(0.5, 0.5, 0.5)
# Índice = cor - 1 (o Core numera cores a partir de 1).
const PALETA: Array[Color] = [
	Color(0.90, 0.25, 0.25), Color(0.25, 0.55, 0.95), Color(0.30, 0.80, 0.35),
	Color(0.95, 0.80, 0.20), Color(0.70, 0.35, 0.90), Color(0.95, 0.55, 0.20),
	Color(0.30, 0.85, 0.85), Color(0.95, 0.45, 0.70),
]

var tabuleiro: Tabuleiro
var selecionado: int = SEM_SELECAO

func _ready() -> void:
	tabuleiro = TabuleiroClass.new()
	tabuleiro.gerar_novo_jogo(QTD_CORES)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local := make_input_local(event) as InputEventMouseButton
		clicar_tubo(indice_tubo_em(local.position))
	elif event is InputEventKey and event.pressed and event.keycode == KEY_R:
		reiniciar()

# Intenção do jogador. 1º clique seleciona; 2º clique pede ao Core para verter.
# true -> estado mudou, redesenha; false -> só desmarca (Visual não assume sucesso).
func clicar_tubo(idx: int) -> void:
	if idx == SEM_SELECAO or idx == selecionado:
		selecionado = SEM_SELECAO
	elif selecionado == SEM_SELECAO:
		selecionado = idx
	else:
		var origem: int = selecionado
		selecionado = SEM_SELECAO
		tabuleiro.mover_liquido(origem, idx)
	queue_redraw()

func reiniciar() -> void:
	selecionado = SEM_SELECAO
	tabuleiro.gerar_novo_jogo(QTD_CORES)
	queue_redraw()

# --- Layout (só geometria de tela, nenhuma regra) ---

func rect_tubo(idx: int) -> Rect2:
	var qtd: int = tabuleiro.tubos.size()
	var tela: Vector2 = get_viewport_rect().size
	var altura: float = tabuleiro.tubos[idx].capacidade * ALTURA_BLOCO + FOLGA_BLOCO
	var largura_total: float = qtd * LARGURA_TUBO + (qtd - 1) * ESPACO_TUBOS
	var x: float = (tela.x - largura_total) / 2.0 + idx * (LARGURA_TUBO + ESPACO_TUBOS)
	var y: float = (tela.y - altura) / 2.0
	if idx == selecionado:
		y -= ELEVACAO_SELECAO
	return Rect2(x, y, LARGURA_TUBO, altura)

func indice_tubo_em(pos: Vector2) -> int:
	for i in tabuleiro.tubos.size():
		if rect_tubo(i).grow(ESPACO_TUBOS / 2.0).has_point(pos):
			return i
	return SEM_SELECAO

func cor_visual(cor: int) -> Color:
	if cor >= 1 and cor <= PALETA.size():
		return PALETA[cor - 1]
	return COR_DESCONHECIDA

# --- Desenho ---

func _draw() -> void:
	draw_rect(get_viewport_rect(), COR_FUNDO)
	if tabuleiro == null:
		return
	for i in tabuleiro.tubos.size():
		_desenhar_tubo(i)
	var fonte: Font = ThemeDB.fallback_font
	var texto: String = "Vitória! (R para novo jogo)" if tabuleiro.is_vitoria() else "R: novo jogo"
	draw_string(fonte, Vector2(0, 60), texto, HORIZONTAL_ALIGNMENT_CENTER, get_viewport_rect().size.x, 28)

func _desenhar_tubo(idx: int) -> void:
	var r: Rect2 = rect_tubo(idx)
	var tubo: Tube = tabuleiro.tubos[idx]
	# cores[0] é o fundo do tubo: desenha de baixo para cima.
	for j in tubo.cores.size():
		var bloco := Rect2(
			r.position.x + FOLGA_BLOCO,
			r.end.y - FOLGA_BLOCO - (j + 1) * ALTURA_BLOCO + 2.0,
			LARGURA_TUBO - 2.0 * FOLGA_BLOCO,
			ALTURA_BLOCO - 2.0)
		draw_rect(bloco, cor_visual(tubo.cores[j]))
	var cor_borda: Color = COR_BORDA_SELECAO if idx == selecionado else COR_BORDA
	draw_rect(r, cor_borda, false, BORDA)
