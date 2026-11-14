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

# Art Bible (docs/legacy/referencia-visual.md): "Geladeira Térmica Stylized".
const COR_FUNDO_FRIO := Color("#CAF0F8")    # geladeira fria (fundo claro)
const COR_FUNDO_QUENTE := Color("#FFD6A5")  # filtro laranja ao esquentar
const COR_BORDA := Color("#0F172A", 0.55)
const COR_BORDA_SELECAO := Color("#FFC300")
const COR_RIM := Color("#0F172A", 0.2)      # rim light: 1px, 20%, por cima do bloco
const COR_BRILHO := Color(1, 1, 1, 0.35)    # overlay branco (dual-layer)
const COR_SOMBRA := Color("#0F172A", 0.18)  # drop shadow "cozy"
const COR_TEXTO := Color("#0F172A")
const COR_DESCONHECIDA := Color("#8D99AE")
const SOMBRA_OFFSET := Vector2(4, 6)
const BORDA_SELECAO: float = 5.0
const DURACAO_CALOR: float = 0.35  # segundos para o fundo esquentar/esfriar
const SQUASH_AMPLITUDE: float = 0.08
const SQUASH_VELOCIDADE: float = 9.0
# Chave = cor do Core (numera a partir de 1). Ciano e Rosa vêm do Art Bible;
# TODO: as outras 7 são provisórias até o D1 resgatar a paleta original.
const CORES: Dictionary = {
	1: Color("#0096C7"),  # Ciano
	2: Color("#E00088"),  # Rosa
	3: Color("#FFB703"),  # Âmbar
	4: Color("#2DC653"),  # Verde
	5: Color("#7B2CBF"),  # Roxo
	6: Color("#FB6107"),  # Laranja
	7: Color("#D62828"),  # Vermelho
	8: Color("#3A0CA3"),  # Anil
	9: Color("#8AC926"),  # Lima
}

var tabuleiro: Tabuleiro
var selecionado: int = SEM_SELECAO
var calor: float = 0.0  # 0 = frio, 1 = quente; animado por tween (só UI)
var tempo: float = 0.0  # relógio da animação de gelatina
var _tween_calor: Tween

func _ready() -> void:
	tabuleiro = TabuleiroClass.new()
	tabuleiro.gerar_novo_jogo(QTD_CORES)
	queue_redraw()

func _process(delta: float) -> void:
	tempo += delta
	if selecionado != SEM_SELECAO or calor > 0.0:
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
		_selecionar(SEM_SELECAO)
	elif selecionado == SEM_SELECAO:
		_selecionar(idx)
	else:
		var origem: int = selecionado
		_selecionar(SEM_SELECAO)
		tabuleiro.mover_liquido(origem, idx)
	queue_redraw()

func reiniciar() -> void:
	_selecionar(SEM_SELECAO)
	tabuleiro.gerar_novo_jogo(QTD_CORES)
	queue_redraw()

# Troca a seleção e anima o fundo térmico até o calor-alvo.
func _selecionar(idx: int) -> void:
	selecionado = idx
	if _tween_calor:
		_tween_calor.kill()
	_tween_calor = create_tween()
	_tween_calor.tween_property(self, "calor", alvo_calor(), DURACAO_CALOR) 		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func alvo_calor() -> float:
	return 0.0 if selecionado == SEM_SELECAO else 1.0

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
	return CORES.get(cor, COR_DESCONHECIDA)

func cor_fundo() -> Color:
	return COR_FUNDO_FRIO.lerp(COR_FUNDO_QUENTE, calor)

# Squash & stretch: só o tubo selecionado "balança" (volume ~constante).
func escala_gelatina(idx: int) -> Vector2:
	if idx != selecionado:
		return Vector2.ONE
	var onda: float = sin(tempo * SQUASH_VELOCIDADE) * SQUASH_AMPLITUDE
	return Vector2(1.0 + onda, 1.0 - onda)

# --- Desenho ---

func _draw() -> void:
	draw_rect(get_viewport_rect(), cor_fundo())
	if tabuleiro == null:
		return
	for i in tabuleiro.tubos.size():
		_desenhar_tubo(i)
	var fonte: Font = ThemeDB.fallback_font
	var texto: String = "Vitória! (R para novo jogo)" if tabuleiro.is_vitoria() else "R: novo jogo"
	draw_string(fonte, Vector2(0, 60), texto, HORIZONTAL_ALIGNMENT_CENTER,
		get_viewport_rect().size.x, 28, COR_TEXTO)

func _desenhar_tubo(idx: int) -> void:
	var r: Rect2 = rect_tubo(idx)
	var tubo: Tube = tabuleiro.tubos[idx]
	var ativo: bool = idx == selecionado
	draw_rect(Rect2(r.position + SOMBRA_OFFSET, r.size), COR_SOMBRA)
	draw_rect(r, Color(1, 1, 1, 0.25))  # vidro
	var escala: Vector2 = escala_gelatina(idx)
	# cores[0] é o fundo do tubo: desenha de baixo para cima.
	for j in tubo.cores.size():
		var base := Rect2(
			r.position.x + FOLGA_BLOCO,
			r.end.y - FOLGA_BLOCO - (j + 1) * ALTURA_BLOCO + 2.0,
			LARGURA_TUBO - 2.0 * FOLGA_BLOCO,
			ALTURA_BLOCO - 2.0)
		# Escala ancorada no centro-base do bloco (a gelatina "senta" no de baixo).
		var tam: Vector2 = base.size * escala
		var bloco := Rect2(Vector2(base.get_center().x - tam.x / 2.0, base.end.y - tam.y), tam)
		draw_rect(bloco, cor_visual(tubo.cores[j]))
		draw_rect(Rect2(bloco.position + Vector2(4, 3), Vector2(bloco.size.x * 0.35, 5)), COR_BRILHO)
		if not ativo:  # o rim light some quando a gelatina "derrete"
			draw_rect(bloco.grow(-0.5), COR_RIM, false, 1.0)
	draw_rect(r, COR_BORDA_SELECAO if ativo else COR_BORDA, false, BORDA_SELECAO if ativo else BORDA)
