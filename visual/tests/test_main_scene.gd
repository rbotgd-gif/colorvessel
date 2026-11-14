extends SceneTree
# Sanidade do Visual: cena instancia sem erro e o clique só delega ao Core (regra é core/tests/).

const TubeClass = preload("res://core/src/tube.gd")
const TabuleiroClass = preload("res://core/src/tabuleiro.gd")

var falhas := 0

func ok(cond: bool, nome: String) -> void:
	if not cond:
		falhas += 1
		push_error("FALHOU: " + nome)
	else:
		print("OK: ", nome)

func tubo(cores: Array) -> Tube:
	var t = TubeClass.new()
	t.cores.assign(cores)
	return t

func clique_em(main: Node2D, idx: int) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = main.rect_tubo(idx).get_center()
	main._unhandled_input(ev)

func tecla(main: Node2D, codigo: Key) -> void:
	var ev := InputEventKey.new()
	ev.keycode = codigo
	ev.pressed = true
	main._unhandled_input(ev)

# Troca o tabuleiro por um já resolvido (mantém a fase) e atualiza a UI.
func vencer(main: Node2D) -> void:
	var arr: Array[Tube] = [tubo([1, 1, 1, 1]), tubo([])]
	main.tabuleiro = TabuleiroClass.new(arr)
	main.montar()

func _initialize() -> void:
	print("--- Iniciando teste de sanidade da cena principal ---")

	var cena: PackedScene = load("res://visual/scenes/main.tscn")
	ok(cena != null, "main.tscn carrega")
	if cena == null:
		quit(1)
		return
	var main = cena.instantiate()
	ok(main != null and main.get_script() != null, "Cena instancia com main.gd")
	root.add_child(main)
	await process_frame  # em _initialize o root ainda não rodou _ready; espera 1 frame

	ok(main.tabuleiro != null, "_ready cria o Tabuleiro")
	if main.tabuleiro == null:
		quit(1)  # sem Tabuleiro o resto quebraria e o processo ficaria preso
		return
	ok(main.fase == 1, "Jogo começa na Fase 1")
	ok(main.tabuleiro.tubos.size() == 4, "Fase 1 = 2 cores -> 4 tubos")
	ok(main.selecionado == main.SEM_SELECAO, "Começa sem seleção")

	# --- Assets de arte (Etapa 8): nós de imagem existem e têm textura ---
	ok(main.fundo is TextureRect and main.fundo.texture != null, "Fundo da geladeira carregado")
	ok(main.tex_tubo != null and main.tex_bloco != null, "Texturas de tubo e bloco geradas")
	ok(main.sprites_tubos.size() == 4, "Um Sprite2D de vidro por tubo")
	var tubos_ok := true
	for s in main.sprites_tubos:
		tubos_ok = tubos_ok and s != null and s.texture == main.tex_tubo
	ok(tubos_ok, "Sprites de tubo não nulos e com textura")
	var total := 0
	var blocos_ok := true
	for i in main.tabuleiro.tubos.size():
		var cores: Array = main.tabuleiro.tubos[i].cores
		total += cores.size()
		for j in cores.size():
			var b: Sprite2D = main.sprites_blocos[i][j]
			blocos_ok = blocos_ok and b.texture == main.tex_bloco \
				and b.modulate == main.cor_visual(cores[j])
	ok(total == 8 and blocos_ok, "8 blocos com textura e cor (modulate) da paleta")
	for t in [main.tex_tubo, main.tex_bloco]:
		var img: Image = t.get_image()
		var canto: float = img.get_pixel(0, 0).a
		var centro: float = img.get_pixel(img.get_width() / 2, img.get_height() / 2).a
		ok(canto == 0.0 and centro > 0.0, "Chroma key: canto transparente, centro visível")

	# Estado fixo para testar o fluxo de clique sem depender do RNG.
	var arr: Array[Tube] = [tubo([1, 2]), tubo([]), tubo([3])]
	main.tabuleiro = TabuleiroClass.new(arr)

	clique_em(main, 0)
	ok(main.selecionado == 0, "1º clique (mouse) seleciona o tubo 0")
	clique_em(main, 1)
	ok(main.selecionado == main.SEM_SELECAO, "2º clique desmarca após jogada válida")
	ok(arr[0].cores == [1] and arr[1].cores == [2], "Jogada válida chega ao Core")

	main.clicar_tubo(1)
	main.clicar_tubo(2)
	ok(main.selecionado == main.SEM_SELECAO, "Jogada inválida só desmarca")
	ok(arr[1].cores == [2] and arr[2].cores == [3], "Jogada inválida não muda estado")

	main.clicar_tubo(0)
	main.clicar_tubo(0)
	ok(main.selecionado == main.SEM_SELECAO, "Clicar no mesmo tubo desmarca")
	main.clicar_tubo(0)
	main.clicar_tubo(main.indice_tubo_em(Vector2(-100, -100)))
	ok(main.selecionado == main.SEM_SELECAO, "Clicar fora de qualquer tubo desmarca")

	# --- Polimento visual (Etapa 7): paleta, fundo térmico, gelatina ---
	ok(main.cor_visual(1) == Color("#0096C7"), "Cor 1 é o Ciano do Art Bible")
	ok(main.cor_visual(2) == Color("#E00088"), "Cor 2 é o Rosa do Art Bible")
	ok(main.cor_visual(99) == main.COR_DESCONHECIDA, "Cor fora da paleta cai no neutro")
	var unicas := {}
	for c in main.CORES.values():
		unicas[c] = true
	ok(main.CORES.size() == 9 and unicas.size() == 9, "Paleta tem 9 cores distintas")

	main.calor = 0.0
	ok(main.cor_fundo() == main.COR_FUNDO_FRIO, "Sem calor o fundo é o frio")
	main.calor = 1.0
	ok(main.cor_fundo().is_equal_approx(main.COR_FUNDO_QUENTE), "Com calor máximo o fundo é o quente")
	main.calor = 0.0

	main.clicar_tubo(0)
	ok(main.alvo_calor() == 1.0, "Selecionar um tubo mira o fundo quente")
	ok(main.escala_gelatina(1) == Vector2.ONE, "Tubo não selecionado não balança")
	main.tempo = PI / (2.0 * main.SQUASH_VELOCIDADE)  # pico da onda
	var e: Vector2 = main.escala_gelatina(0)
	ok(e.x > 1.0 and e.y < 1.0, "Tubo selecionado faz squash & stretch")
	await create_timer(main.DURACAO_CALOR + 0.15).timeout
	ok(is_equal_approx(main.calor, 1.0), "Tween leva o fundo até o quente")
	main.clicar_tubo(0)
	ok(main.alvo_calor() == 0.0, "Desmarcar mira o fundo frio")
	await create_timer(main.DURACAO_CALOR + 0.15).timeout
	ok(is_equal_approx(main.calor, 0.0), "Tween devolve o fundo ao frio")

	# --- Progressão de fases (Etapa 9) ---
	ok(main.cores_da_fase(1) == 2 and main.cores_da_fase(5) == 6, "Fase 1 = 2 cores, Fase 5 = 6")
	ok(main.cores_da_fase(6) == 6 and main.cores_da_fase(20) == 6, "Limite de 6 cores")

	main.iniciar_fase(1)
	ok(not main.botao_proxima.visible, "Botão Próxima Fase escondido sem vitória")
	main.proxima_fase()
	ok(main.fase == 1, "Sem vitória, Próxima Fase não avança")

	for esperado in [2, 3, 4, 5, 6, 7]:
		vencer(main)
		ok(main.botao_proxima.visible, "Vitória mostra o botão Próxima Fase")
		main.botao_proxima.pressed.emit()
		var cores: int = mini(esperado + 1, 6)
		ok(main.fase == esperado and main.tabuleiro.tubos.size() == cores + 2,
			"Avança para a Fase %d com %d cores" % [esperado, cores])
	ok(main.tabuleiro.tubos.size() == 8, "Após a Fase 5 continua com 6 cores (8 tubos)")

	main.iniciar_fase(3)
	tecla(main, KEY_R)
	ok(main.fase == 3 and main.tabuleiro.tubos.size() == 6, "R reinicia a fase ATUAL (Fase 3)")
	vencer(main)
	tecla(main, KEY_N)
	ok(main.fase == 4 and main.tabuleiro.tubos.size() == 7, "Tecla N avança de fase")

	main.queue_free()
	if falhas == 0:
		print("OK: Todos os testes passaram!")
	else:
		print("FALHOU: ", falhas, " teste(s)")
	quit(0 if falhas == 0 else 1)
