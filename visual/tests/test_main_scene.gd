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
	ok(main.tabuleiro.tubos.size() == 5, "gerar_novo_jogo(3) gera 5 tubos")
	ok(main.selecionado == main.SEM_SELECAO, "Começa sem seleção")

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

	main.reiniciar()
	ok(main.tabuleiro.tubos.size() == 5, "R (reiniciar) gera novo jogo de 5 tubos")

	main.queue_free()
	if falhas == 0:
		print("OK: Todos os testes passaram!")
	else:
		print("FALHOU: ", falhas, " teste(s)")
	quit(0 if falhas == 0 else 1)
