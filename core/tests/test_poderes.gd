extends SceneTree
# Poderes do jogador (Fase 2): Desfazer, Dica, +1 Tubo e sinais do contrato.

const TubeClass = preload("res://core/src/tube.gd")
const TabuleiroClass = preload("res://core/src/tabuleiro.gd")
const HistoricoClass = preload("res://core/src/historico.gd")
const SolucionadorClass = preload("res://core/src/solucionador.gd")

var falhas := 0
var eventos: Array = []

func ok(cond: bool, nome: String) -> void:
	if not cond:
		falhas += 1
		push_error("FALHOU: " + nome)
	else:
		print("OK: ", nome)

func tubo(cores: Array, cap: int = 4) -> Tube:
	var t = TubeClass.new(cap)
	t.cores.assign(cores)
	return t

func tabuleiro(lista: Array) -> Tabuleiro:
	var arr: Array[Tube] = []
	arr.assign(lista)
	return TabuleiroClass.new(arr)

func cores_de(tab: Tabuleiro) -> Array:
	var c: Array = []
	for t in tab.tubos:
		c.append(t.cores.duplicate())
	return c

func _init() -> void:
	print("--- Iniciando testes dos Poderes ---")

	# --- Historico puro ---
	var h := HistoricoClass.new(2)
	ok(not h.pode_desfazer() and h.desfazer().is_empty(), "Histórico vazio não desfaz")
	var snap := [[4, [1, 2]]]
	h.registrar(snap)
	snap[0][1].append(9)
	ok(h.desfazer() == [[4, [1, 2]]], "Histórico guarda cópia profunda")
	h.registrar([1]); h.registrar([2]); h.registrar([3])
	ok(h.tamanho() == 2 and h.desfazer() == [3] and h.desfazer() == [2], "Limite descarta o mais antigo")
	h.registrar([1]); h.limpar()
	ok(not h.pode_desfazer(), "limpar esvazia o histórico")

	# --- Desfazer ---
	var tab := tabuleiro([tubo([1, 2]), tubo([2]), tubo([])])
	var inicial := cores_de(tab)
	ok(not tab.desfazer(), "Desfazer sem jogadas devolve false")
	tab.mover_liquido(0, 1)
	tab.mover_liquido(0, 2)
	ok(tab.movimentos_feitos == 2 and tab.pode_desfazer(), "Jogadas válidas entram no histórico")
	tab.mover_liquido(0, 0)  # inválida
	ok(tab.movimentos_feitos == 2, "Jogada inválida não entra no histórico")
	ok(tab.desfazer() and tab.desfazer(), "Desfaz duas jogadas")
	ok(cores_de(tab) == inicial and tab.movimentos_feitos == 0, "Estado e contador voltam ao inicial")
	ok(not tab.pode_desfazer(), "Histórico esgotado")

	# --- Dica ---
	tab = tabuleiro([tubo([1, 1, 2, 2]), tubo([2, 2, 1, 1]), tubo([]), tubo([])])
	var antes := cores_de(tab)
	var d: Vector2i = tab.dica()
	ok(d != TabuleiroClass.SEM_DICA and tab.calcular_quantidade(d.x, d.y) > 0, "Dica é um movimento válido")
	ok(d == SolucionadorClass.resolver(tab)["movimentos"][0], "Dica é o 1º passo do BFS")
	ok(cores_de(tab) == antes and not tab.pode_desfazer(), "Dica não altera tabuleiro nem histórico")
	tab.mover_liquido(d.x, d.y)
	var d2: Vector2i = tab.dica()
	ok(d2 != TabuleiroClass.SEM_DICA, "Dica segue válida após seguir a anterior")
	ok(tabuleiro([tubo([1, 1, 1, 1]), tubo([])]).dica() == TabuleiroClass.SEM_DICA, "Fase vencida: sem dica")
	ok(tabuleiro([tubo([1, 2, 1, 2]), tubo([2, 1, 2, 1])]).dica() == TabuleiroClass.SEM_DICA, "Impossível: sem dica")

	# --- +1 Tubo ---
	tab = tabuleiro([tubo([1, 2, 1, 2]), tubo([2, 1, 2, 1])])
	ok(tab.dica() == TabuleiroClass.SEM_DICA, "Deadlock antes do poder")
	ok(tab.pode_adicionar_tubo() and tab.adicionar_tubo_auxiliar(), "+1 Tubo adiciona")
	ok(tab.tubos.size() == 3 and tab.tubos[2].is_vazio() and tab.tubos[2].capacidade == 4, "Novo tubo vazio com capacidade padrão")
	ok(tab.tubos_auxiliares() == 1 and not tab.adicionar_tubo_auxiliar(), "Limite de 1 auxiliar por fase")
	ok(tab.tubos.size() == 3, "Segunda tentativa não cria tubo")
	ok(tab.desfazer() and tab.tubos.size() == 2, "Desfazer remove o tubo auxiliar")
	ok(tab.movimentos_feitos == 0 and tab.pode_adicionar_tubo(), "Desfazer o tubo não conta jogada e devolve o poder")
	ok(not tabuleiro([tubo([1, 1, 1, 1]), tubo([])]).pode_adicionar_tubo(), "Fase vencida não aceita +1 Tubo")
	tab = tabuleiro([tubo([1, 2]), tubo([2, 1]), tubo([])])
	tab.adicionar_tubo_auxiliar()
	tab.mover_liquido(0, 3)
	ok(tab.tubos[3].cores == [1] or tab.tubos[3].cores == [2], "Tubo auxiliar recebe líquido")
	tab.desfazer(); tab.desfazer()
	ok(tab.tubos.size() == 3 and cores_de(tab) == [[1, 2], [2, 1], []], "Desfazer em cadeia restaura tubos e cores")
	tab.gerar_novo_jogo(3)
	ok(tab.tubos_auxiliares() == 0 and tab.tubos.size() == 5 and not tab.pode_desfazer(), "Nova fase zera histórico e auxiliares")

	# --- Sinais do contrato ---
	tab = tabuleiro([tubo([1, 1, 1]), tubo([1]), tubo([2])])
	tab.pour_started.connect(func(f, t): eventos.append(["started", f, t]))
	tab.pour_finished.connect(func(f, t, c): eventos.append(["finished", f, t, c]))
	tab.pour_invalid.connect(func(f, t, r): eventos.append(["invalid", f, t, r]))
	tab.tube_completed.connect(func(i, c): eventos.append(["completed", i, c]))
	tab.level_won.connect(func(n): eventos.append(["won", n]))
	tab.state_changed.connect(func(s): eventos.append(["state", s["tubos"].size()]))
	tab.mover_liquido(1, 2)
	ok(eventos == [["invalid", 1, 2, "cor_diferente"]], "pour_invalid com motivo")
	eventos.clear()
	tab.mover_liquido(1, 0)
	ok(eventos == [["started", 1, 0], ["finished", 1, 0, 1], ["completed", 0, 1], ["state", 3]],
		"Ordem: started, finished, completed, state_changed (sem level_won com tubo 2 incompleto)")
	eventos.clear()
	tab = tabuleiro([tubo([1, 1, 1]), tubo([1])])
	tab.level_won.connect(func(n): eventos.append(["won", n]))
	tab.mover_liquido(1, 0)
	ok(eventos == [["won", 1]], "level_won com total de jogadas")
	eventos.clear()
	tab.state_changed.connect(func(_s): eventos.append("state"))
	tab.desfazer()
	ok(eventos == ["state"], "Desfazer emite state_changed")
	tab.adicionar_tubo_auxiliar()
	ok(eventos == ["state", "state"], "+1 Tubo emite state_changed")

	if falhas == 0:
		print("OK: Todos os testes passaram!")
	else:
		print("FALHOU: ", falhas, " teste(s)")
	quit(0 if falhas == 0 else 1)
