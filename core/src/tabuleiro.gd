class_name Tabuleiro
extends RefCounted
# Core puro: sem Node, sem cena. Tabuleiro é dono da lista de tubos e da regra de verter.

var tubos: Array[Tube] = []

func _init(lista_tubos: Array[Tube] = []) -> void:
	tubos = lista_tubos

func _indice_valido(idx: int) -> bool:
	return idx >= 0 and idx < tubos.size()

# Quantos blocos sairiam de origem para destino (0 = movimento inválido).
func calcular_quantidade(idx_origem: int, idx_destino: int) -> int:
	if not _indice_valido(idx_origem) or not _indice_valido(idx_destino):
		return 0
	if idx_origem == idx_destino:
		return 0
	var origem: Tube = tubos[idx_origem]
	var destino: Tube = tubos[idx_destino]
	if origem.is_vazio() or destino.is_cheio():
		return 0
	if not destino.is_vazio() and destino.get_cor_topo() != origem.get_cor_topo():
		return 0
	return mini(origem.contar_topo_igual(), destino.get_espaco_livre())

func mover_liquido(idx_origem: int, idx_destino: int) -> bool:
	var qtd: int = calcular_quantidade(idx_origem, idx_destino)
	if qtd <= 0:
		return false
	var origem: Tube = tubos[idx_origem]
	var destino: Tube = tubos[idx_destino]
	for i in qtd:
		destino.adicionar_cor(origem.remover_topo())
	return true

# Vitória: todo tubo está vazio ou completo (cheio com uma cor só).
func is_vitoria() -> bool:
	for t in tubos:
		if not t.is_vazio() and not t.is_completo():
			return false
	return true

const MAX_TENTATIVAS_GERACAO: int = 100
const SolucionadorClass = preload("res://core/src/solucionador.gd")

# RNG próprio para os testes poderem fixar a semente (rng.seed = X).
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Quem valida cada fase gerada: func(Tabuleiro) -> Dictionary com "resultado".
# Os testes trocam por um espião para provar que o gerador consulta o solucionador.
var validador: Callable = Callable(SolucionadorClass, "resolver")

# Cria (qtd_cores + 2) tubos, monta qtd_cores tubos com 4 blocos de cor 1..qtd_cores
# e embaralha os blocos só entre esses qtd_cores tubos. Os 2 últimos ficam vazios
# (área de manobra). Só aceita a fase se nenhum tubo começar completo E o
# Solucionador (BFS) disser RESOLVIVEL; senão tenta de novo, até MAX_TENTATIVAS_GERACAO.
# Se esgotar, volta para a última tentativa RESOLVIVEL (mesmo com tubo completo) ou,
# sem nenhuma, para o tabuleiro já resolvido: nunca entrega fase impossível.
# Devolve false só nesse caso de esgotamento.
# Com qtd_cores == 1 o único tubo sempre sai completo: cai no esgotamento (fase [1,1,1,1]).
func gerar_novo_jogo(qtd_cores: int) -> bool:
	assert(qtd_cores > 0, "Tabuleiro: qtd_cores deve ser > 0")
	if qtd_cores <= 0:
		return false  # assert some em build de release; não gera nada.
	var ultima_resolvivel: Array = []
	for tentativa in MAX_TENTATIVAS_GERACAO:
		_montar_resolvido(qtd_cores)
		_embaralhar_blocos(qtd_cores)
		var completo := _algum_tubo_completo()
		if completo and not ultima_resolvivel.is_empty():
			continue  # já há reserva resolvível; não gasta BFS com fase sem desafio
		if validador.call(self)["resultado"] != SolucionadorClass.Resultado.RESOLVIVEL:
			continue
		if not completo:
			return true
		ultima_resolvivel = _copiar_cores()
	if ultima_resolvivel.is_empty():
		_montar_resolvido(qtd_cores)  # último recurso: fase já vencida, nunca travada
	else:
		for i in tubos.size():
			tubos[i].cores.assign(ultima_resolvivel[i])
	push_warning("Tabuleiro: %d tentativas sem fase ideal (qtd_cores=%d)" % [MAX_TENTATIVAS_GERACAO, qtd_cores])
	return false

func _copiar_cores() -> Array:
	var copia: Array = []
	for t in tubos:
		copia.append(t.cores.duplicate())
	return copia

func _montar_resolvido(qtd_cores: int) -> void:
	var novos: Array[Tube] = []
	for i in qtd_cores + 2:
		var t := Tube.new()
		if i < qtd_cores:
			for j in t.capacidade:
				t.cores.append(i + 1)
		novos.append(t)
	tubos = novos

# Recolhe os blocos dos tubos 0..qtd_cores-1, embaralha (Fisher-Yates) e
# redistribui em ordem só nesses tubos, enchendo cada um até a capacidade.
# Os tubos qtd_cores e qtd_cores+1 não são tocados (continuam vazios).
# Usa cores.append direto: a regra de topo (pode_receber) vale para jogadas,
# não para montar o estado inicial.
func _embaralhar_blocos(qtd_cores: int) -> void:
	var blocos: Array[int] = []
	for i in qtd_cores:
		blocos.append_array(tubos[i].cores)
		tubos[i].cores.clear()
	for i in range(blocos.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: int = blocos[i]
		blocos[i] = blocos[j]
		blocos[j] = tmp
	var idx_tubo: int = 0
	for cor in blocos:
		if tubos[idx_tubo].is_cheio():
			idx_tubo += 1
		tubos[idx_tubo].cores.append(cor)

func _algum_tubo_completo() -> bool:
	for t in tubos:
		if t.is_completo():
			return true
	return false
