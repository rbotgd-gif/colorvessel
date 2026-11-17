extends Node2D
# Visual (Arte Funcional): monta o Tabuleiro com sprites (assets do D1) e repassa intenções.
# Não decide regra: quem diz se a jogada vale é tabuleiro.mover_liquido().
# Estado próprio do Visual é só de UI: tubo selecionado, calor do fundo, relógio da gelatina
# e a fase atual (progressão: quantas cores pedir ao Core; vitória quem diz é o Core).

const TabuleiroClass = preload("res://core/src/tabuleiro.gd")
const TEX_FUNDO: Texture2D = preload("res://visual/assets/fundo_geladeira.jpg")
const TEX_TUBO_BRUTA: Texture2D = preload("res://visual/assets/tubo_vidro.png")
const TEX_BLOCO_BRUTA: Texture2D = preload("res://visual/assets/bloco_gelatina.png")

const FASE_INICIAL: int = 1
const CORES_FASE_INICIAL: int = 2  # Fase 1 = 2 cores; cada fase soma 1
const MAX_CORES: int = 6           # teto: da Fase 5 em diante são sempre 6 cores
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
const COR_TEXTO := Color("#E6FBFF")            # texto claro sobre o visor escuro
const COR_VISOR_FUNDO := Color(0.03, 0.08, 0.12, 0.72)  # escuro translúcido
const COR_VISOR_BORDA := Color(0.22, 0.91, 1.0, 0.65)   # ciano luminoso sutil
const COR_VISOR_BRILHO := Color(0.22, 0.91, 1.0, 0.22)
const COR_COMPLETO := Color("#7CFFB2")         # destaque de tubo completo
const COR_DESCONHECIDA := Color("#8D99AE")
# HUD "Visor Térmico": painel arredondado no topo com fase, status e botão.
const Y_HUD: float = 14.0
const RAIO_VISOR: int = 14
const TAM_FONTE_FASE: int = 32
const TAM_FONTE_STATUS: int = 24
const TAM_BOTAO := Vector2(200, 44)
const DURACAO_CALOR: float = 0.35  # segundos para o fundo esquentar/esfriar
const SQUASH_AMPLITUDE: float = 0.08
const SQUASH_VELOCIDADE: float = 9.0
const DURACAO_MOVIMENTO: float = 0.15  # deslocamento dos blocos entre tubos (só visual)
const ATRASO_BLOCO: float = 0.04       # escalonamento entre blocos do mesmo despejo
const PUNCH_ESCALA: float = 1.18
const DURACAO_PUNCH: float = 0.35
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
var fase: int = FASE_INICIAL
var botao_proxima: Button
var hud: PanelContainer
var label_fase: Label
var label_status: Label
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
	_montar_hud()
	tabuleiro = TabuleiroClass.new()
	iniciar_fase(FASE_INICIAL)

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
	elif event is InputEventKey and event.pressed and event.keycode in [KEY_N, KEY_ENTER]:
		proxima_fase()

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

# Celebração suave: onda de pulsos pelos tubos, brilho no visor e confete leve.
func celebrar_vitoria() -> void:
	if not is_inside_tree():
		return
	for i in sprites_tubos.size():
		get_tree().create_timer(i * 0.07).timeout.connect(pulsar_tubo.bind(i))
	if hud:
		hud.modulate = Color(1.6, 1.6, 1.6)
		hud.create_tween().tween_property(hud, "modulate", Color.WHITE, 0.8) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
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

# --- HUD "Visor Térmico" ---

func _estilo_visor(brilho: float = 1.0, raio: int = RAIO_VISOR) -> StyleBoxFlat:
	var e := StyleBoxFlat.new()
	e.bg_color = COR_VISOR_FUNDO
	e.set_border_width_all(2)
	e.border_color = Color(COR_VISOR_BORDA, minf(COR_VISOR_BORDA.a * brilho, 1.0))
	e.set_corner_radius_all(raio)
	e.shadow_color = Color(COR_VISOR_BRILHO, minf(COR_VISOR_BRILHO.a * brilho, 1.0))
	e.shadow_size = 8
	e.content_margin_left = 20
	e.content_margin_right = 20
	e.content_margin_top = 8
	e.content_margin_bottom = 10
	return e

func _novo_label(tam: int) -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", COR_TEXTO)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _montar_hud() -> void:
	hud = PanelContainer.new()
	hud.add_theme_stylebox_override("panel", _estilo_visor())
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE  # cliques passam para os tubos
	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 6)
	caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(caixa)
	label_fase = _novo_label(TAM_FONTE_FASE)
	label_status = _novo_label(TAM_FONTE_STATUS)
	caixa.add_child(label_fase)
	caixa.add_child(label_status)
	botao_proxima = Button.new()
	botao_proxima.text = "Próxima Fase"
	botao_proxima.custom_minimum_size = TAM_BOTAO
	botao_proxima.add_theme_color_override("font_color", COR_TEXTO)
	botao_proxima.add_theme_color_override("font_hover_color", Color.WHITE)
	botao_proxima.add_theme_stylebox_override("normal", _estilo_visor(1.0, 10))
	botao_proxima.add_theme_stylebox_override("hover", _estilo_visor(1.5, 10))
	botao_proxima.add_theme_stylebox_override("pressed", _estilo_visor(2.0, 10))
	botao_proxima.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	botao_proxima.pressed.connect(proxima_fase)
	caixa.add_child(botao_proxima)
	add_child(hud)
	hud.resized.connect(_centralizar_hud)

func _centralizar_hud() -> void:
	hud.position = Vector2((get_viewport_rect().size.x - hud.size.x) / 2.0, Y_HUD)

func _atualizar_hud() -> void:
	if hud == null:
		return
	label_fase.text = "Fase: %d" % fase
	var venceu: bool = tabuleiro.is_vitoria()
	label_status.text = "Vitória! (N/Enter: próxima fase)" if venceu else "R: reiniciar fase"
	botao_proxima.visible = venceu
	hud.reset_size()  # encolhe/expande conforme o botão aparece
	_centralizar_hud()

# --- Progressão de fases ---

static func cores_da_fase(f: int) -> int:
	return mini(CORES_FASE_INICIAL + f - FASE_INICIAL, MAX_CORES)

func iniciar_fase(f: int) -> void:
	fase = f
	_selecionar(SEM_SELECAO)
	tabuleiro.gerar_novo_jogo(cores_da_fase(fase))
	montar()

# R: refaz a fase ATUAL (novo embaralhamento, mesma quantidade de cores).
func reiniciar() -> void:
	iniciar_fase(fase)

# Só avança se o Core disser que é vitória.
func proxima_fase() -> void:
	if tabuleiro.is_vitoria():
		iniciar_fase(fase + 1)

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
		var vidro: Sprite2D = _sprite(tex_tubo, r)  # vidro por cima dos blocos
		if tubo.is_completo():
			vidro.modulate = COR_COMPLETO.lerp(Color.WHITE, 0.5)  # brilho sutil
		sprites_tubos.append(vidro)
	_atualizar_hud()
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
