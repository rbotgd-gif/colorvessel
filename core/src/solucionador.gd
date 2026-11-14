class_name Solucionador
extends RefCounted
# Core puro: BFS (busca em largura) sobre estados do Tabuleiro.
# Usa a própria regra do Tabuleiro (calcular_quantidade/mover_liquido): sem regra duplicada.

enum Resultado { RESOLVIVEL, IMPOSSIVEL, LIMITE }

# Teto de estados visitados. Acima disso a busca para e devolve LIMITE
# (não comprovado: o gerador trata como "não serve" e tenta outra fase).
const MAX_ESTADOS_PADRAO: int = 50000

# Devolve { "resultado": Resultado, "movimentos": Array[Vector2i], "estados": int }.
# movimentos = menor sequência (origem, destino) nos índices do tabuleiro original;
# só é preenchido quando RESOLVIVEL. Não altera o tabuleiro recebido.
static func resolver(tab: Tabuleiro, max_estados: int = MAX_ESTADOS_PADRAO) -> Dictionary:
	# Tabuleiro de trabalho: recebe cada estado da fila, testa jogadas e desfaz.
	var atual := _clonar(tab)
	var n := atual.tubos.size()
	# Por chave canônica: [cores de cada tubo, chave do pai, movimento que levou até aqui].
	var visitados := {}
	var chave_inicio := _chave(atual)
	visitados[chave_inicio] = [_copiar_cores(atual), null, Vector2i(-1, -1)]
	if atual.is_vitoria():
		return _resposta(Resultado.RESOLVIVEL, [], 1)
	var fila: Array = [chave_inicio]
	var cabeca := 0

	while cabeca < fila.size():
		var chave = fila[cabeca]
		cabeca += 1
		var estado: Array = visitados[chave][0]
		for i in n:
			atual.tubos[i].cores.assign(estado[i])
		for o in n:
			var origem: Tube = atual.tubos[o]
			if origem.is_vazio() or origem.is_completo():
				continue  # nada a mover / tubo pronto nunca precisa sair
			var uniforme := origem.contar_topo_igual() == origem.cores.size()
			for d in n:
				var qtd := atual.calcular_quantidade(o, d)
				if qtd <= 0:
					continue
				if uniforme and atual.tubos[d].is_vazio():
					continue  # só troca o tubo de lugar: estado equivalente
				atual.mover_liquido(o, d)
				var chave_nova := _chave(atual)
				var nova := not visitados.has(chave_nova)
				var venceu := nova and atual.is_vitoria()
				if nova:
					visitados[chave_nova] = [_copiar_cores(atual), chave, Vector2i(o, d)]
				for i in qtd:  # desfaz a jogada
					origem.cores.append(atual.tubos[d].cores.pop_back())
				if venceu:
					return _resposta(Resultado.RESOLVIVEL, _caminho(visitados, chave_nova), visitados.size())
				if nova:
					if visitados.size() >= max_estados:
						return _resposta(Resultado.LIMITE, [], visitados.size())
					fila.append(chave_nova)
	return _resposta(Resultado.IMPOSSIVEL, [], visitados.size())

static func is_resolvivel(tab: Tabuleiro, max_estados: int = MAX_ESTADOS_PADRAO) -> bool:
	return resolver(tab, max_estados)["resultado"] == Resultado.RESOLVIVEL

static func _clonar(tab: Tabuleiro) -> Tabuleiro:
	var lista: Array[Tube] = []
	for t in tab.tubos:
		var c := Tube.new(t.capacidade)
		c.cores.assign(t.cores)
		lista.append(c)
	return Tabuleiro.new(lista)

static func _copiar_cores(tab: Tabuleiro) -> Array:
	var estado: Array = []
	for t in tab.tubos:
		estado.append(t.cores.duplicate())
	return estado

# Chave canônica: um inteiro por tubo (cores em base 16 + capacidade), ordenados,
# porque a posição dos tubos não muda a solvabilidade. Cores válidas: 0..14.
static func _chave(tab: Tabuleiro) -> PackedInt64Array:
	var chave := PackedInt64Array()
	for t in tab.tubos:
		var codigo: int = 0
		for c in t.cores:
			codigo = codigo * 16 + c + 1
		chave.append(codigo * 16 + t.capacidade)
	chave.sort()
	return chave

static func _caminho(visitados: Dictionary, chave) -> Array[Vector2i]:
	var movimentos: Array[Vector2i] = []
	while visitados[chave][1] != null:
		movimentos.push_front(visitados[chave][2])
		chave = visitados[chave][1]
	return movimentos

static func _resposta(resultado: Resultado, movimentos: Array, estados: int) -> Dictionary:
	return { "resultado": resultado, "movimentos": movimentos, "estados": estados }
