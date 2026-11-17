extends Node2D
# Visual (Arte Funcional): renderiza o Tabuleiro com sprites (assets do D1) e anima o juice.
# Não decide regra: quem diz se a jogada vale é tabuleiro.mover_liquido().
# Estado próprio é só de UI: tubo selecionado, calor do fundo e relógio da gelatina.
# Progressão de fases e HUD ficam em main.gd, que escuta os sinais abaixo.

signal montado             # sprites recriados a partir do Core (HUD pode atualizar)
signal vitoria_celebrada   # celebração começou (HUD pode brilhar junto)

const TabuleiroClass = preload("res://core/src/tabuleiro.gd")
const T = preload("res://visual/tema/cv_tokens.gd")
const TEX_FUNDO: Texture2D = preload("res://visual/assets/fundo_geladeira.jpg")
const TEX_TUBO_BRUTA: Texture2D = preload("res://visual/assets/tubo_vidro.png")
const TEX_BLOCO_BRUTA: Texture2D = preload("res://visual/assets/bloco_gelatina.png")
# Sprites 3D (Blender) com alfa real: preferidos; se faltarem, cai no asset antigo + chroma key.
const CAMINHO_TUBO_3D := "res://visual/assets/blender/tubo_vidro_3d.png"
const CAMINHO_BLOCO_3D := "res://visual/assets/blender/bloco_gelatina_3d.png"

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
const COR_FUNDO_FRIO := T.FUNDO_FRIO
const COR_FUNDO_QUENTE := T.FUNDO_QUENTE
const COR_BORDA_SELECAO := T.OURO
const COR_COMPLETO := T.VERDE_OK
const COR_DESCONHECIDA := T.NEUTRO
const COR_VISOR_BORDA := T.VISOR_BORDA
const CORES: Dictionary = T.CORES_LIQUIDO

const DURACAO_CALOR: float = 0.35  # segundos para o fundo esquentar/esfriar
const SQUASH_AMPLITUDE: float = 0.08
const SQUASH_VELOCIDADE: float = 9.0
const DURACAO_MOVIMENTO: float = 0.15  # deslocamento dos blocos entre tubos (só visual)
const ATRASO_BLOCO: float = 0.04       # escalonamento entre blocos do mesmo despejo
const PUNCH_ESCALA: float = 1.18
const DURACAO_PUNCH: float = 0.35

var tabuleiro: Tabuleiro
var selecionado: int = SEM_SELECAO
var calor: float = 0.0  # 0 = frio, 1 = quente; animado por tween (só UI)
var tempo: float = 0.0  # relógio da animação de gelatina
var _tween_calor: Tween

var tex_tubo: Texture2D
var tex_bloco: Texture2D
var fundo: TextureRect
var camada: Node2D  # tubos e blocos; o _draw() da view (borda, destaque) fica por cima
var sprites_tubos: Array[Sprite2D] = []
var sprites_blocos: Array = []  # [tubo] -> Array[Sprite2D], de baixo para cima

func _ready() -> void:
	tex_tubo = _textura(CAMINHO_TUBO_3D, TEX_TUBO_BRUTA, LIMIAR_TUBO)
	tex_bloco = _textura(CAMINHO_BLOCO_3D, TEX_BLOCO_BRUTA, LIMIAR_BLOCO)
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

func _process(delta: float) -> void:
	tempo += delta
	fundo.modulate = cor_fundo()
	if selecionado != SEM_SELECAO and selecionado < sprites_blocos.size():
		for b: Sprite2D in sprites_blocos[selecionado]:
			b.scale = b.get_meta("escala_base") * escala_gelatina(selecionado)

# Intenção do jogador. 1º clique seleciona; 2º clique pede ao Core para verter.
# Inválida -> só desmarca (Visual não assume sucesso). Sempre remonta a partir do Core.
func clicar_tubo(idx: int) -> void:
	if idx == SEM_SELECAO or idx == selecionado:
		selecionar(SEM_SELECAO)
	elif selecionado == SEM_SELECAO:
		selecionar(idx)
	else:
		var origem: int = selecionado
		selecionar(SEM_SELECAO)
		var antes_origem: int = tabuleiro.tubos[origem].cores.size()
		var antes_destino: int = tabuleiro.tubos[idx].cores.size()
		var moveu: bool = tabuleiro.mover_liquido(origem, idx)
		montar()  # estado do Core já está final; o que segue é só animação
		if moveu:
			_animar_movimento(origem, idx, antes_origem, antes_destino)
		return
	montar()

# --- Juice (só visual: nunca altera o Core nem espera por animação) ---

# Os blocos recém-chegados ao destino nascem na posição que tinham na origem e deslizam.
func _animar_movimento(origem: int, destino: int, antes_origem: int, antes_destino: int) -> void:
	var movidos: int = tabuleiro.tubos[destino].cores.size() - antes_destino
	var r_origem: Rect2 = rect_tubo(origem)
	r_origem.position.y -= ELEVACAO_SELECAO  # saiu do tubo elevado
	for k in movidos:
		var b: Sprite2D = sprites_blocos[destino][antes_destino + k]
		var fim: Vector2 = b.position
		b.position = _sprite_pos(rect_bloco(r_origem, antes_origem - 1 - k))
		b.z_index = 10
		var tw: Tween = b.create_tween()  # preso ao sprite: montar() o descarta junto
		tw.tween_property(b, "position", fim, DURACAO_MOVIMENTO) \
			.set_delay(k * ATRASO_BLOCO).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_callback(func() -> void: b.z_index = 0)
	var fim_total: float = DURACAO_MOVIMENTO + maxi(movidos - 1, 0) * ATRASO_BLOCO
	get_tree().create_timer(fim_total).timeout.connect(_ao_fim_do_movimento.bind(destino))

func _ao_fim_do_movimento(destino: int) -> void:
	if not is_inside_tree() or tabuleiro == null or destino >= tabuleiro.tubos.size():
		return
	if tabuleiro.tubos[destino].is_completo():
		pulsar_tubo(destino)
	if tabuleiro.is_vitoria():
		celebrar_vitoria()

# Scale punch no vidro e nos blocos do tubo.
func pulsar_tubo(idx: int) -> void:
	if not is_inside_tree() or idx >= sprites_tubos.size():
		return
	var alvos: Array = [sprites_tubos[idx]]
	alvos.append_array(sprites_blocos[idx])
	for s: Sprite2D in alvos:
		var base: Vector2 = s.get_meta("escala_base")
		s.scale = base * PUNCH_ESCALA
		s.create_tween().tween_property(s, "scale", base, DURACAO_PUNCH) \
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

# Celebração suave: onda de pulsos pelos tubos e confete leve (o HUD brilha via sinal).
func celebrar_vitoria() -> void:
	if not is_inside_tree():
		return
	for i in sprites_tubos.size():
		get_tree().create_timer(i * 0.07).timeout.connect(pulsar_tubo.bind(i))
	vitoria_celebrada.emit()
	var conf := CPUParticles2D.new()
	conf.position = Vector2(get_viewport_rect().size.x / 2.0, 0.0)
	conf.emitting = true
	conf.one_shot = true
	conf.explosiveness = 0.8
	conf.amount = 40
	conf.lifetime = 2.0
	conf.direction = Vector2.DOWN
	conf.spread = 70.0
	conf.initial_velocity_min = 120.0
	conf.initial_velocity_max = 260.0
	conf.gravity = Vector2(0, 220)
	conf.scale_amount_min = 3.0
	conf.scale_amount_max = 6.0
	var rampa := Gradient.new()
	rampa.colors = PackedColorArray([COR_BORDA_SELECAO, COR_COMPLETO, Color(COR_VISOR_BORDA, 0.0)])
	rampa.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	conf.color_ramp = rampa
	add_child(conf)
	get_tree().create_timer(conf.lifetime + 0.5).timeout.connect(conf.queue_free)

# Troca a seleção e anima o fundo térmico até o calor-alvo.
func selecionar(idx: int) -> void:
	selecionado = idx
	if _tween_calor:
		_tween_calor.kill()
	_tween_calor = create_tween()
	_tween_calor.tween_property(self, "calor", alvo_calor(), DURACAO_CALOR) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func alvo_calor() -> float:
	return 0.0 if selecionado == SEM_SELECAO else 1.0

# --- Assets ---

# Prefere o sprite 3D com alfa real; senão (ausente/não importado) usa o antigo com chroma key.
static func _textura(caminho_3d: String, bruta: Texture2D, limiar: float) -> Texture2D:
	if ResourceLoader.exists(caminho_3d):
		var tex := load(caminho_3d) as Texture2D
		if tex != null:
			return tex
	return chroma_key(bruta, limiar)

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
		var vidro: Sprite2D = _sprite(tex_tubo, r)  # vidro por cima dos blocos
		if tubo.is_completo():
			vidro.modulate = COR_COMPLETO.lerp(Color.WHITE, 0.5)  # brilho sutil
		sprites_tubos.append(vidro)
	montado.emit()
	queue_redraw()

func _sprite_pos(r: Rect2) -> Vector2:
	return Vector2(r.get_center().x, r.end.y)

# Sprite com origem no centro-base: o squash "senta" no bloco de baixo.
func _sprite(tex: Texture2D, r: Rect2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.offset = Vector2(0, -tex.get_height() / 2.0)
	s.position = _sprite_pos(r)
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

# --- Desenho por cima dos sprites: borda de seleção e destaque de tubo completo ---

func _draw() -> void:
	if tabuleiro == null:
		return
	if selecionado != SEM_SELECAO:
		draw_rect(rect_tubo(selecionado), COR_BORDA_SELECAO, false, BORDA_SELECAO)
	for i in tabuleiro.tubos.size():  # destaque dos tubos completos
		if tabuleiro.tubos[i].is_completo():
			draw_rect(rect_tubo(i).grow(3.0), Color(COR_COMPLETO, 0.8), false, 3.0)
