extends SceneTree

const TubeClass = preload("res://core/src/tube.gd")
const TabuleiroClass = preload("res://core/src/tabuleiro.gd")
const SolucionadorClass = preload("res://core/src/solucionador.gd")
const R = SolucionadorClass.Resultado

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

func cores_de(tab: Tabuleiro) -> Array:
	var c: Array = []
	for t in tab.tubos:
		c.append(t.cores.duplicate())
	return c

# Reaplica a solução do BFS com a regra real do Tabuleiro, numa cópia.
func solucao_vence(tab: Tabuleiro, movimentos: Array) -> bool:
	var copia: Array = []
	for t in tab.tubos:
		copia.append(tubo(t.cores, t.capacidade))
	var replay := tabuleiro(copia)
	for m in movimentos:
		if not replay.mover_liquido(m.x, m.y):
			return false
	return replay.is_vitoria()

func _init() -> void:
	print("--- Iniciando testes do Solucionador (BFS) ---")

	# --- Já resolvido ---
	var r: Dictionary = SolucionadorClass.resolver(tabuleiro([tubo([1, 1, 1, 1]), tubo([])]))
	ok(r["resultado"] == R.RESOLVIVEL and r["movimentos"].is_empty(), "Tabuleiro já vencido = RESOLVIVEL com 0 jogadas")

	# --- Resolvível: a solução devolvida vence com a regra real ---
	var tab := tabuleiro([tubo([1, 1, 2, 2]), tubo([2, 2, 1, 1]), tubo([]), tubo([])])
	var antes := cores_de(tab)
	r = SolucionadorClass.resolver(tab)
	ok(r["resultado"] == R.RESOLVIVEL, "[1,1,2,2]+[2,2,1,1]+2 vazios é RESOLVIVEL")
	ok(solucao_vence(tab, r["movimentos"]), "Replay da solução no Tabuleiro chega à vitória")
	ok(r["movimentos"].size() == 3, "BFS acha a solução mínima (3 jogadas)")
	ok(cores_de(tab) == antes, "Solucionador não altera o tabuleiro recebido")

	# --- Impossíveis (deadlock desde o início) ---
	r = SolucionadorClass.resolver(tabuleiro([tubo([1, 2, 1, 2]), tubo([2, 1, 2, 1])]))
	ok(r["resultado"] == R.IMPOSSIVEL, "Dois tubos cheios e misturados, sem vazio = IMPOSSIVEL")
	r = SolucionadorClass.resolver(tabuleiro([tubo([1, 2, 1, 2]), tubo([2, 1, 2, 1]), tubo([], 1)]))
	ok(r["resultado"] == R.IMPOSSIVEL, "Folga de 1 só não basta = IMPOSSIVEL")
	ok(r["movimentos"].is_empty(), "IMPOSSIVEL não devolve movimentos")
	ok(not SolucionadorClass.is_resolvivel(tabuleiro([tubo([1, 2], 2), tubo([2, 1], 2)])), "is_resolvivel = false em deadlock")

	# --- Teto de estados ---
	r = SolucionadorClass.resolver(tabuleiro([tubo([1, 1, 2, 2]), tubo([2, 2, 1, 1]), tubo([]), tubo([])]), 2)
	ok(r["resultado"] == R.LIMITE, "Teto de estados estourado = LIMITE (não comprovado)")

	# --- Gerador consulta o solucionador e rejeita IMPOSSIVEL ---
	var chamadas := [0]
	var gen := TabuleiroClass.new()
	gen.rng.seed = 7
	gen.validador = func(t: Tabuleiro) -> Dictionary:
		chamadas[0] += 1
		if chamadas[0] <= 3:
			return {"resultado": R.IMPOSSIVEL}
		return SolucionadorClass.resolver(t)
	ok(gen.gerar_novo_jogo(3), "Gerador aceita depois que o solucionador aprova")
	ok(chamadas[0] == 4, "Gerador consultou o solucionador e descartou 3 fases IMPOSSIVEL")
	ok(SolucionadorClass.is_resolvivel(gen), "Fase aceita é de fato resolvível")

	# --- Solucionador sempre diz IMPOSSIVEL: esgota e entrega fase vencida, nunca travada ---
	gen = TabuleiroClass.new()
	chamadas[0] = 0
	gen.validador = func(_t: Tabuleiro) -> Dictionary:
		chamadas[0] += 1
		return {"resultado": R.IMPOSSIVEL}
	ok(not gen.gerar_novo_jogo(3), "Esgotar as tentativas devolve false")
	ok(chamadas[0] == TabuleiroClass.MAX_TENTATIVAS_GERACAO, "Tenta exatamente MAX_TENTATIVAS_GERACAO vezes")
	ok(gen.is_vitoria() and gen.tubos.size() == 5, "Sem fase resolvível, cai no tabuleiro resolvido")

	# LIMITE também não é aceito (não comprovado)
	gen = TabuleiroClass.new()
	gen.validador = func(_t: Tabuleiro) -> Dictionary: return {"resultado": R.LIMITE}
	ok(not gen.gerar_novo_jogo(2) and gen.is_vitoria(), "LIMITE nunca é aceito como fase válida")

	# --- Gerador real: nenhuma fase entregue é impossível (2 a 6 cores) ---
	for qtd in [2, 3, 4, 5, 6]:
		var todas_ok := true
		for semente in 5:
			gen = TabuleiroClass.new()
			gen.rng.seed = 1000 + semente
			var aceito: bool = gen.gerar_novo_jogo(qtd)
			r = SolucionadorClass.resolver(gen)
			todas_ok = todas_ok and aceito and r["resultado"] == R.RESOLVIVEL \
				and solucao_vence(gen, r["movimentos"]) and not gen.is_vitoria()
		ok(todas_ok, "qtd=%d: 5 fases geradas, todas resolvíveis (replay vence)" % qtd)

	if falhas == 0:
		print("OK: Todos os testes passaram!")
	else:
		print("FALHOU: ", falhas, " teste(s)")

	quit(0 if falhas == 0 else 1)
