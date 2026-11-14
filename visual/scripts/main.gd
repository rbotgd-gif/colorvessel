extends Node2D
# Visual (Arte Funcional): monta o Tabuleiro com sprites (assets do D1) e repassa intenções.
# Não decide regra: quem diz se a jogada vale é tabuleiro.mover_liquido().
# Estado próprio do Visual é só de UI: tubo selecionado, calor do fundo, relógio da gelatina.

const TabuleiroClass = preload("res://core/src/tabuleiro.gd")
const TEX_FUNDO: Texture2D = preload("res://visual/assets/fundo_geladeira.jpg")
const TEX_TUBO_BRUTA: Texture2D = preload("res://visual/assets/tubo_vidro.png")
const TEX_BLOCO_BRUTA: Texture2D = preload("res://visual/assets/bloco_gelatina.png")

const QTD_CORES: int = 3
const SEM_SELECAO: int = -1

const LARGURA_TUBO: float = 60.0
const ALTURA_BLOCO: float = 40.0
const ESPACO_TUBOS: float = 30.0
const FOLGA_BLOCO: float = 6.0
const ELEVACAO_SELECAO: float = 24.0
const BORDA_SELECAO: float = 5.0
const ALTURA_PRATELEIRA: float = 0.6  # fração da altura do fundo onde fica a prateleira do meio
# Chroma key: tubo e bloco vieram com fundo escuro opaco (sem alfa).
const RESOLUCAO_CHROMA: int = 256  # reduz antes: rápido e suficiente para o tamanho na tela
const LIMIAR_TUBO: float = 0.5     # vidro: o interior escuro fica quase transparente
const LIMIAR_BLOCO: float = 0.3
const ALFA_MINIMO: float = 0.08    # abaixo disso é ruído do fundo -> 100% transparente

# Art Bible (docs/legacy/referencia-visual.md): "Geladeira Térmica Stylized".
const COR_FUNDO_FRIO := Color.WHITE            # fundo sem filtro
const COR_FUNDO_QUENTE := Color("#FFB077")     # filtro laranja multiplicado ao esquentar
const COR_BORDA_SELECAO := Color("#FFC300")
const COR_TEXTO := Color("#0F172A")
const COR_DESCONHECIDA := Color("#8D99AE")
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

var tex_tubo: Texture2D
var tex_bloco: Texture2D
var fundo: TextureRect
var camada: Node2D  # tubos e blocos; o _draw() do Main (borda, texto) fica por cima
var sprites_tubos: Array[Sprite2D] = []
var sprites_blocos: Array = []  # [tubo] -> Array[Sprite2D], de baixo para cima

func _ready() -> void:
	tex_tubo = chroma_key(TEX_TUBO_BRUTA, LIMIAR_TUBO)
	tex_bloco = chroma_key(TEX_BLOCO_BRUTA, LIMIAR_BLOCO)
	fundo = TextureRect.new()
	fundo.texture = TEX_FUNDO
	fundo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fundo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fundo.size = get_viewport_rect().size
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.show_behind_parent = true
	add_child(fundo)
	camada = Node2D.new()
	camada.show_behind_parent = true
	add_child(camada)
	tabuleiro = TabuleiroClass.new()
	tabuleiro.gerar_novo_jogo(QTD_CORES)
	montar()

func _process(delta: float) -> void:
	tempo += delta
	fundo.modulate = cor_fundo()
	if selecionado != SEM_SELECAO and selecionado < sprites_blocos.size():
		for b: Sprite2D in sprites_blocos[selecionado]:
			b.scale = b.get_meta("escala_base") * escala_gelatina(selecionado)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local := make_input_local(event) as InputEventMouseButton
		clicar_tubo(indice_tubo_em(local.position))
	elif event is InputEventKey and event.pressed and event.keycode == KEY_R:
		reiniciar()

# Intenção do jogador. 1º clique seleciona; 2º clique pede ao Core para verter.
# Inválida -> só desmarca (Visual não assume sucesso). Sempre remonta a partir do Core.
func clicar_tubo(idx: int) -> void:
	if idx == SEM_SELECAO or idx == selecionado:
		_selecionar(SEM_SELECAO)
	elif selecionado == SEM_SELECAO:
		_selecionar(idx)
	else:
		var origem: int = selecionado
		_selecionar(SEM_SELECAO)
		tabuleiro.mover_liquido(origem, idx)
	montar()

func reiniciar() -> void:
	_selecionar(SEM_SELECAO)
	tabuleiro.gerar_novo_jogo(QTD_CORES)
	montar()

# Troca a seleção e anima o fundo térmico até o calor-alvo.
func _selecionar(idx: int) -> void:
	selecionado = idx
	if _tween_calor:
		_tween_calor.kill()
	_tween_calor = create_tween()
	_tween_calor.tween_property(self, "calor", alvo_calor(), DURACAO_CALOR) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func alvo_calor() -> float:
	return 0.0 if selecionado == SEM_SELECAO else 1.0

# --- Assets ---

# Remove o fundo escuro chapado: o alfa cresce com a distância da cor do canto, e a
# cor é "despremultiplicada" sobre esse fundo para o vidro não ficar acinzentado.
static func chroma_key(bruta: Texture2D, limiar: float) -> ImageTexture:
	var img: Image = bruta.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var f: float = float(RESOLUCAO_CHROMA) / maxf(img.get_width(), img.get_height())
	img.resize(int(img.get_width() * f), int(img.get_height() * f), Image.INTERPOLATE_BILINEAR)
	var chave: Color = img.get_pixel(0, 0)
	for y in img.get_height():
		for x in img.get_width():
			var c: Color = img.get_pixel(x, y)
			var d: float = maxf(absf(c.r - chave.r), maxf(absf(c.g - chave.g), absf(c.b - chave.b)))
			var a: float = clampf(d / limiar, 0.0, 1.0)
			if a < ALFA_MINIMO:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				var r: Color = (chave + (c - chave) / a).clamp()
				img.set_pixel(x, y, Color(r.r, r.g, r.b, a))
	return ImageTexture.create_from_image(img.get_region(img.get_used_rect()))

# Recria os sprites a partir do estado do Core (chamado a cada mudança).
func montar() -> void:
	for filho in camada.get_children():
		camada.remove_child(filho)
		filho.queue_free()
	sprites_tubos.clear()
	sprites_blocos.clear()
	for i in tabuleiro.tubos.size():
		var r: Rect2 = rect_tubo(i)
		var tubo: Tube = tabuleiro.tubos[i]
		var linha: Array[Sprite2D] = []
		for j in tubo.cores.size():  # cores[0] é o fundo do tubo
			var b: Sprite2D = _sprite(tex_bloco, rect_bloco(r, j))
			b.modulate = cor_visual(tubo.cores[j])  # tinge a base cinza (dual-layer)
			linha.append(b)
		sprites_blocos.append(linha)
		sprites_tubos.append(_sprite(tex_tubo, r))  # vidro por cima dos blocos
	queue_redraw()

# Sprite com origem no centro-base: o squash "senta" no bloco de baixo.
func _sprite(tex: Texture2D, r: Rect2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.offset = Vector2(0, -tex.get_height() / 2.0)
	s.position = Vector2(r.get_center().x, r.end.y)
	s.scale = r.size / tex.get_size()
	s.set_meta("escala_base", s.scale)
	camada.add_child(s)
	return s

# --- Layout (só geometria de tela, nenhuma regra) ---

# Y da prateleira do meio, seguindo o "cover" do fundo na tela.
func base_prateleira() -> float:
	var tela: Vector2 = get_viewport_rect().size
	var tam: Vector2 = TEX_FUNDO.get_size()
	var escala: float = maxf(tela.x / tam.x, tela.y / tam.y)
	return tela.y / 2.0 + (ALTURA_PRATELEIRA - 0.5) * tam.y * escala

func rect_tubo(idx: int) -> Rect2:
	var qtd: int = tabuleiro.tubos.size()
	var tela: Vector2 = get_viewport_rect().size
	var altura: float = tabuleiro.tubos[idx].capacidade * ALTURA_BLOCO + FOLGA_BLOCO
	var largura_total: float = qtd * LARGURA_TUBO + (qtd - 1) * ESPACO_TUBOS
	var x: float = (tela.x - largura_total) / 2.0 + idx * (LARGURA_TUBO + ESPACO_TUBOS)
	var y: float = base_prateleira() - altura
	if idx == selecionado:
		y -= ELEVACAO_SELECAO
	return Rect2(x, y, LARGURA_TUBO, altura)

func rect_bloco(r: Rect2, j: int) -> Rect2:
	return Rect2(
		r.position.x + FOLGA_BLOCO,
		r.end.y - FOLGA_BLOCO - (j + 1) * ALTURA_BLOCO + 2.0,
		LARGURA_TUBO - 2.0 * FOLGA_BLOCO,
		ALTURA_BLOCO - 2.0)

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

# --- Desenho por cima dos sprites: borda de seleção e texto ---

func _draw() -> void:
	if tabuleiro == null:
		return
	if selecionado != SEM_SELECAO:
		draw_rect(rect_tubo(selecionado), COR_BORDA_SELECAO, false, BORDA_SELECAO)
	var fonte: Font = ThemeDB.fallback_font
	var texto: String = "Vitória! (R para novo jogo)" if tabuleiro.is_vitoria() else "R: novo jogo"
	draw_string(fonte, Vector2(0, 60), texto, HORIZONTAL_ALIGNMENT_CENTER,
		get_viewport_rect().size.x, 28, COR_TEXTO)
