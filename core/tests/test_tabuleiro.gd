extends SceneTree

const TubeClass = preload("res://core/src/tube.gd")
const TabuleiroClass = preload("res://core/src/tabuleiro.gd")

var falhas := 0

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

func _init() -> void:
	print("--- Iniciando testes do Tabuleiro ---")

	# --- Movimento simples para tubo vazio ---
	var tab = tabuleiro([tubo([1, 2, 2]), tubo([])])
	ok(tab.mover_liquido(0, 1) == true, "Mover para tubo vazio é válido")
	ok(tab.tubos[0].cores == [1], "Origem fica só com [1]")
	ok(tab.tubos[1].cores == [2, 2], "Destino recebe os 2 blocos do topo")

	# --- Mesma cor no topo ---
	tab = tabuleiro([tubo([3, 5]), tubo([5])])
	ok(tab.mover_liquido(0, 1) == true, "Mover sobre mesma cor é válido")
	ok(tab.tubos[0].cores == [3], "Origem perde o 5")
	ok(tab.tubos[1].cores == [5, 5], "Destino fica [5, 5]")

	# --- Limite de espaço livre (3 no topo, só 2 de espaço) ---
	tab = tabuleiro([tubo([4, 4, 4]), tubo([6, 4])])
	ok(tab.mover_liquido(0, 1) == true, "Movimento parcial é válido")
	ok(tab.tubos[0].cores == [4], "Origem mantém 1 bloco que não coube")
	ok(tab.tubos[1].cores == [6, 4, 4, 4], "Destino enche até a capacidade")

	# --- Inválidos: estado não muda ---
	tab = tabuleiro([tubo([]), tubo([1])])
	ok(tab.mover_liquido(0, 1) == false, "Origem vazia é inválido")
	ok(tab.tubos[1].cores == [1], "Destino intacto após origem vazia")

	tab = tabuleiro([tubo([2]), tubo([2, 2, 2, 2])])
	ok(tab.mover_liquido(0, 1) == false, "Destino cheio é inválido")
	ok(tab.tubos[0].cores == [2], "Origem intacta após destino cheio")

	tab = tabuleiro([tubo([1, 2]), tubo([3])])
	ok(tab.mover_liquido(0, 1) == false, "Cores diferentes é inválido")
	ok(tab.tubos[0].cores == [1, 2] and tab.tubos[1].cores == [3], "Nada muda com cores diferentes")

	# --- Bordas ---
	tab = tabuleiro([tubo([1]), tubo([])])
	ok(tab.mover_liquido(0, 0) == false, "Origem == destino é inválido")
	ok(tab.mover_liquido(-1, 1) == false, "Índice negativo é inválido")
	ok(tab.mover_liquido(0, 5) == false, "Índice fora do range é inválido")
	ok(tab.tubos[0].cores == [1], "Nada muda com índices inválidos")

	# --- Capacidades diferentes ---
	tab = tabuleiro([tubo([7, 7, 7], 3), tubo([], 2)])
	ok(tab.mover_liquido(0, 1) == true, "Destino cap 2 aceita parcial")
	ok(tab.tubos[0].cores == [7] and tab.tubos[1].cores == [7, 7], "Move só 2 para cap 2")

	# --- Multicor [2, 1, 1]: só o bloco contíguo do topo se move ---
	tab = tabuleiro([tubo([2, 1, 1]), tubo([])])
	ok(tab.calcular_quantidade(0, 1) == 2, "Multicor [2,1,1] move 2 (não 3)")
	ok(tab.mover_liquido(0, 1) == true, "Multicor [2,1,1] para vazio é válido")
	ok(tab.tubos[0].cores == [2] and tab.tubos[1].cores == [1, 1], "Origem [2], destino [1,1]")
	ok(tab.mover_liquido(0, 1) == false, "Depois, 2 sobre 1 é inválido")

	# --- Topo uniforme [1, 1, 1] para vazio move 3 ---
	tab = tabuleiro([tubo([1, 1, 1]), tubo([])])
	ok(tab.mover_liquido(0, 1) == true, "[1,1,1] para vazio é válido")
	ok(tab.tubos[0].is_vazio() and tab.tubos[1].cores == [1, 1, 1], "Move os 3 blocos")

	# --- get_espaco_livre ---
	ok(tubo([]).get_espaco_livre() == 4, "Tubo vazio cap 4 tem 4 livres")
	ok(tubo([1, 2, 3]).get_espaco_livre() == 1, "Tubo com 3 tem 1 livre")
	ok(tubo([1, 1, 1, 1, 1]).get_espaco_livre() == 0, "Acima da capacidade não fica negativo")

	if falhas == 0:
		print("OK: Todos os testes passaram!")
	else:
		print("FALHOU: ", falhas, " teste(s)")

	quit(0 if falhas == 0 else 1)
