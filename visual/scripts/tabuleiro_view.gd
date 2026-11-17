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

# Layout (viewport 720x1280): a grade fica centrada na faixa Y 340..920.
const ZONA_Y_TOPO: float = 340.0
const ZONA_Y_BASE: float = 920.0
const MARGEM_LATERAL: float = 48.0
const ESPACO_TUBOS: float = 24.0
const ESPACO_FILAS: float = 24.0
const MAX_POR_FILA: int = 5
const LARGURA_TUBO_MAX: float = 110.0
const PROPORCAO_TUBO: float = 3.6      # altura / largura do vidro visível (bounding box)
const MARGEM_INTERNA: float = 0.14     # fração da largura, de cada lado, entre vidro e gelatina
const FOLGA_VERTICAL: float = 0.05     # fração da altura: base e topo do tubo sem gelatina
const ELEVACAO_SELECAO: float = 24.0
const BORDA_SELECAO: float = 5.0
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
const DURACAO_IDA: float = 0.28        # arco até a boca do destino
const DURACAO_VOLTA: float = 0.25      # retorno suave à posição original
const DURACAO_JATO_BASE: float = 0.15
const DURACAO_JATO_POR_BLOCO: float = 0.08
const ALTURA_ARCO: float = 50.0
const INCLINACAO_DESPEJO: float = 0.9  # rad (~52°)
const FOLGA_BOCA: float = 14.0
const DURACAO_BRILHO: float = 0.5

var tabuleiro: Tabuleiro
var selecionado: int = SEM_SELECAO
var calor: float = 0.0  # 0 = frio, 1 = quente; animado por tween (só UI)
var tempo: float = 0.0  # relógio da animação de gelatina
var _tween_calor: Tween
var _animando: bool = false  # true só durante o despejo visual

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
	if _animando:  # bloqueio curto: só dura o despejo visual (nunca em headless)
		return
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

static func modo_headless() -> bool:
	return OS.has_feature("headless") or DisplayServer.get_name() == "headless"

# Despejo fluido: o tubo de origem sobe em arco até a boca do destino, inclina, solta um jato
# colorido enquanto os blocos "enchem" o destino e volta suave. Só visual; o Core já está final.
# Em headless não há animação nem bloqueio: o desfecho roda na hora.
func _animar_movimento(origem: int, destino: int, _antes_origem: int, antes_destino: int) -> void:
	if modo_headless() or not is_inside_tree():
		_ao_fim_do_movimento(destino)
		return
	var movidos: int = tabuleiro.tubos[destino].cores.size() - antes_destino
	var cor: Color = cor_visual(tabuleiro.tubos[destino].cores[antes_destino])
	var r_o: Rect2 = rect_tubo(origem)
	var r_d: Rect2 = rect_tubo(destino)
	var sinal: float = 1.0 if r_d.get_center().x >= r_o.get_center().x else -1.0
	var angulo: float = INCLINACAO_DESPEJO * sinal
	var altura: float = r_o.size.y
	var p0: Vector2 = Vector2(r_o.get_center().x, r_o.end.y)
	var boca_final: Vector2 = Vector2(r_d.get_center().x - sinal * 8.0, r_d.position.y - FOLGA_BOCA)
	var p1: Vector2 = boca_final - Vector2(sin(angulo), -cos(angulo)) * altura
	var topo: float = rect_bloco(r_d, antes_destino + movidos - 1).position.y  # nível final do líquido

	# Pivô na base do tubo: leva junto o vidro e os blocos que sobraram na origem.
	var pivo := Node2D.new()
	pivo.position = p0
	pivo.z_index = 20
	camada.add_child(pivo)
	var filhos: Array = [sprites_tubos[origem]]
	filhos.append_array(sprites_blocos[origem])
	for s: Sprite2D in filhos:
		s.reparent(pivo)  # mantém a posição global; o pivô ainda não está rotacionado
	var novos: Array[Sprite2D] = []
	for k in movidos:  # blocos que chegam: crescem de baixo para cima durante o jato
		var b: Sprite2D = sprites_blocos[destino][antes_destino + k]
		b.scale = Vector2(b.scale.x, 0.0)
		novos.append(b)
	var jato := Line2D.new()
	jato.width = 9.0
	jato.default_color = cor
	jato.begin_cap_mode = Line2D.LINE_CAP_ROUND
	jato.end_cap_mode = Line2D.LINE_CAP_ROUND
	jato.z_index = 15
	jato.visible = false
	camada.add_child(jato)

	_animando = true
	var tw: Tween = create_tween()
	tw.tween_method(_pose_despejo.bind(pivo, p0, p1, angulo), 0.0, 1.0, DURACAO_IDA) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var dur_jato: float = DURACAO_JATO_BASE + movidos * DURACAO_JATO_POR_BLOCO
	tw.tween_method(_pose_jato.bind(jato, boca_final, topo, novos), 0.0, 1.0, dur_jato)
	tw.tween_method(_pose_despejo.bind(pivo, p0, p1, angulo), 1.0, 0.0, DURACAO_VOLTA) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.finished.connect(_fim_animacao.bind(destino))

# t: 0 = tubo parado na origem, 1 = inclinado sobre o destino. Arco = parábola sobre a reta.
func _pose_despejo(t: float, pivo: Node2D, p0: Vector2, p1: Vector2, angulo: float) -> void:
	if not is_instance_valid(pivo):
		return
	pivo.position = p0.lerp(p1, t) + Vector2(0.0, -sin(PI * t) * ALTURA_ARCO)
	pivo.rotation = angulo * t

# u: 0..1 do jato. 0-0.2 o fio cresce até a superfície; 0.2-0.8 flui; 0.8-1 o fio some.
func _pose_jato(u: float, jato: Line2D, boca_final: Vector2, topo: float, novos: Array[Sprite2D]) -> void:
	if not is_instance_valid(jato):
		return
	var alvo: Vector2 = Vector2(boca_final.x, topo)
	var cresce: float = clampf(u / 0.2, 0.0, 1.0)
	var some: float = clampf((u - 0.8) / 0.2, 0.0, 1.0)
	jato.visible = u < 1.0
	jato.points = PackedVector2Array([boca_final.lerp(alvo, some), boca_final.lerp(alvo, cresce)])
	var enche: float = clampf((u - 0.2) / 0.6, 0.0, 1.0)
	for k in novos.size():
		var b: Sprite2D = novos[k]
		if is_instance_valid(b):
			var base: Vector2 = b.get_meta("escala_base")
			b.scale = Vector2(base.x, base.y * clampf(enche * novos.size() - k, 0.0, 1.0))

func _fim_animacao(destino: int) -> void:
	_animando = false
	if is_instance_valid(camada) and tabuleiro != null:
		montar()  # estado limpo e definitivo (pivô, jato e escalas descartados)
	_ao_fim_do_movimento(destino)

func _ao_fim_do_movimento(destino: int) -> void:
	if not is_inside_tree() or tabuleiro == null or destino >= tabuleiro.tubos.size():
		return
	if tabuleiro.tubos[destino].is_completo():
		pulsar_tubo(destino)
		if not modo_headless():
			_brilho_completo(destino)
	if tabuleiro.is_vitoria():
		celebrar_vitoria()

# Tubo completo (4 iguais): halo colorido que expande e some + partículas leves saindo da boca.
func _brilho_completo(idx: int) -> void:
	if idx >= sprites_tubos.size():
		return
	var r: Rect2 = rect_tubo(idx)
	var cor: Color = cor_visual(tabuleiro.tubos[idx].cores[0])
	var meio: Vector2 = r.size / 2.0
	var halo := Polygon2D.new()
	halo.position = r.get_center()
	halo.color = Color(cor.lerp(Color.WHITE, 0.5), 0.45)
	halo.polygon = PackedVector2Array([-meio, Vector2(meio.x, -meio.y), meio, Vector2(-meio.x, meio.y)])
	halo.z_index = 12
	add_child(halo)
	var tw: Tween = halo.create_tween().set_parallel(true)
	tw.tween_property(halo, "scale", Vector2(1.5, 1.2), DURACAO_BRILHO) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(halo, "modulate:a", 0.0, DURACAO_BRILHO)
	tw.chain().tween_callback(halo.queue_free)
	var p := CPUParticles2D.new()
	p.position = Vector2(r.get_center().x, r.position.y)
	p.one_shot = true
	p.emitting = true
	p.explosiveness = 0.9
	p.amount = 14
	p.lifetime = 0.8
	p.direction = Vector2.UP
	p.spread = 60.0
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 140.0
	p.gravity = Vector2(0, 260)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.color = cor.lerp(Color.WHITE, 0.4)
	p.z_index = 12
	add_child(p)
	get_tree().create_timer(p.lifetime + 0.3).timeout.connect(p.queue_free)

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

# Recorte útil (bounding box dos pixels não transparentes) da textura, em cache.
var _recortes: Dictionary = {}

func _recorte(tex: Texture2D) -> Rect2:
	if not _recortes.has(tex):
		var img: Image = tex.get_image()
		if img.is_compressed():
			img.decompress()
		_recortes[tex] = Rect2(img.get_used_rect())
	return _recortes[tex]

# Sprite cujo recorte útil preenche exatamente r, com origem no centro-base do recorte
# (o squash "senta" no bloco de baixo).
func _sprite(tex: Texture2D, r: Rect2) -> Sprite2D:
	var rec: Rect2 = _recorte(tex)
	var s := Sprite2D.new()
	s.texture = tex
	var tam: Vector2 = tex.get_size()
	s.offset = tam / 2.0 - Vector2(rec.get_center().x, rec.end.y)
	s.position = Vector2(r.get_center().x, r.end.y)
	s.scale = r.size / rec.size
	s.set_meta("escala_base", s.scale)
	camada.add_child(s)
	return s

# --- Layout (só geometria de tela, nenhuma regra) ---

# Retângulo do vidro visível (recorte útil do sprite), em grade centrada na zona de jogo.
func rect_tubo(idx: int) -> Rect2:
	var qtd: int = tabuleiro.tubos.size()
	var tela: Vector2 = get_viewport_rect().size
	var filas: int = ceili(float(qtd) / MAX_POR_FILA)
	var por_fila: int = ceili(float(qtd) / filas)
	var largura: float = minf(LARGURA_TUBO_MAX,
		(tela.x - 2.0 * MARGEM_LATERAL - (por_fila - 1) * ESPACO_TUBOS) / por_fila)
	var zona: float = ZONA_Y_BASE - ZONA_Y_TOPO
	largura = minf(largura, (zona - (filas - 1) * ESPACO_FILAS) / filas / PROPORCAO_TUBO)
	var altura: float = largura * PROPORCAO_TUBO
	var fila: int = idx / por_fila
	var col: int = idx % por_fila
	var na_fila: int = mini(por_fila, qtd - fila * por_fila)  # última fila pode ter menos
	var x: float = (tela.x - (na_fila * largura + (na_fila - 1) * ESPACO_TUBOS)) / 2.0 		+ col * (largura + ESPACO_TUBOS)
	var bloco_total: float = filas * altura + (filas - 1) * ESPACO_FILAS
	var y: float = (ZONA_Y_TOPO + ZONA_Y_BASE - bloco_total) / 2.0 + fila * (altura + ESPACO_FILAS)
	if idx == selecionado:
		y -= ELEVACAO_SELECAO
	return Rect2(x, y, largura, altura)

# Bloco j (0 = fundo) dentro do tubo r: 14% de margem de cada lado, nunca encosta no vidro.
func rect_bloco(r: Rect2, j: int) -> Rect2:
	var cap: int = tabuleiro.tubos[0].capacidade
	var folga_y: float = r.size.y * FOLGA_VERTICAL
	var alt: float = (r.size.y - 2.0 * folga_y) / cap
	var folga_x: float = r.size.x * MARGEM_INTERNA
	return Rect2(
		r.position.x + folga_x,
		r.end.y - folga_y - (j + 1) * alt + 1.0,
		r.size.x - 2.0 * folga_x,
		alt - 2.0)

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
