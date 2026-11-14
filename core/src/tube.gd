class_name Tube
extends RefCounted
# Core puro: sem Node, sem cena, sem sinais. Tube é só dado + regra local.
# Sinais do contrato (pour_*, tube_completed etc.) pertencem ao tabuleiro, não ao tubo.

const COR_VAZIA: int = -1

var capacidade: int = 4
var cores: Array[int] = []

func _init(cap: int = 4) -> void:
	assert(cap > 0, "Tube: capacidade deve ser > 0")
	capacidade = cap

func is_vazio() -> bool:
	return cores.is_empty()

# >= em vez de ==: se o estado for montado direto (ex.: gerador/testes) acima da
# capacidade, o tubo continua sendo tratado como cheio e não aceita mais cor.
func is_cheio() -> bool:
	return cores.size() >= capacidade

# Quantos blocos ainda cabem (nunca negativo, mesmo com estado acima da capacidade).
func get_espaco_livre() -> int:
	return maxi(capacidade - cores.size(), 0)

# Só é completo se estiver cheio E todos os blocos forem da mesma cor.
func is_completo() -> bool:
	if not is_cheio():
		return false
	var cor_base: int = cores[0]
	for c in cores:
		if c != cor_base:
			return false
	return true

func get_cor_topo() -> int:
	if is_vazio():
		return COR_VAZIA
	return cores.back()

# Conta quantos blocos iguais seguidos existem no topo.
func contar_topo_igual() -> int:
	if is_vazio():
		return 0
	var cor_topo: int = get_cor_topo()
	var count: int = 0
	for i in range(cores.size() - 1, -1, -1):
		if cores[i] == cor_topo:
			count += 1
		else:
			break
	return count

func pode_receber(cor_nova: int) -> bool:
	if cor_nova < 0:
		return false
	if is_cheio():
		return false
	if is_vazio():
		return true
	return get_cor_topo() == cor_nova

func adicionar_cor(cor: int) -> bool:
	if pode_receber(cor):
		cores.append(cor)
		return true
	return false

# Remove o bloco do topo e devolve a cor (COR_VAZIA se o tubo estiver vazio).
func remover_topo() -> int:
	if is_vazio():
		return COR_VAZIA
	return cores.pop_back()
