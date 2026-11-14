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

# RNG próprio para os testes poderem fixar a semente (rng.seed = X).
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Cria (qtd_cores + 2) tubos, monta qtd_cores tubos com 4 blocos de cor 1..qtd_cores
# e embaralha todos os blocos entre todos os tubos. Repete até nenhum tubo
# começar completo (ou esgotar MAX_TENTATIVAS_GERACAO, mantendo a última tentativa).
# TODO: garantir solvabilidade (validação futura, ver Etapa 5).
func gerar_novo_jogo(qtd_cores: int) -> void:
	assert(qtd_cores > 0, "Tabuleiro: qtd_cores deve ser > 0")
	for tentativa in MAX_TENTATIVAS_GERACAO:
		_montar_resolvido(qtd_cores)
		_embaralhar_blocos()
		if not _algum_tubo_completo():
			return

func _montar_resolvido(qtd_cores: int) -> void:
	var novos: Array[Tube] = []
	for i in qtd_cores + 2:
		var t := Tube.new()
		if i < qtd_cores:
			for j in t.capacidade:
				t.cores.append(i + 1)
		novos.append(t)
	tubos = novos

# Recolhe todos os blocos, embaralha e redistribui cada um num tubo aleatório
# com espaço. Usa cores.append direto: a regra de topo (pode_receber) vale para
# jogadas, não para montar o estado inicial.
func _embaralhar_blocos() -> void:
	var blocos: Array[int] = []
	for t in tubos:
		blocos.append_array(t.cores)
		t.cores.clear()
	for i in range(blocos.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: int = blocos[i]
		blocos[i] = blocos[j]
		blocos[j] = tmp
	for cor in blocos:
		var com_espaco: Array[Tube] = []
		for t in tubos:
			if not t.is_cheio():
				com_espaco.append(t)
		com_espaco[rng.randi_range(0, com_espaco.size() - 1)].cores.append(cor)

func _algum_tubo_completo() -> bool:
	for t in tubos:
		if t.is_completo():
			return true
	return false
