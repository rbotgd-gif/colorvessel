class_name Tube

var capacidade: int = 4
var cores: Array[int] = []

func _init(cap: int = 4):
	capacidade = cap

func is_vazio() -> bool:
	return cores.size() == 0

func is_cheio() -> bool:
	return cores.size() == capacidade

# Corrigido: Só é completo se estiver cheio E todos os blocos forem da mesma cor
func is_completo() -> bool:
	if not is_cheio():
		return false
	var cor_base = cores[0]
	for c in cores:
		if c != cor_base:
			return false
	return true

func get_cor_topo() -> int:
	if is_vazio():
		return -1
	return cores.back()

# Adicionado conforme auditoria: Conta quantos blocos iguais seguidos tem no topo
func contar_topo_igual() -> int:
	if is_vazio():
		return 0
	var cor_topo = get_cor_topo()
	var count = 0
	for i in range(cores.size() - 1, -1, -1):
		if cores[i] == cor_topo:
			count += 1
		else:
			break
	return count

# Adicionado validação de cor inválida (>= 0)
func pode_receber(cor_nova: int) -> bool:
	if is_cheio():
		return false
	if cor_nova < 0:
		return false
	if is_vazio():
		return true
	return get_cor_topo() == cor_nova

func adicionar_cor(cor: int) -> bool:
	if pode_receber(cor):
		cores.append(cor)
		return true
	return false

# Adicionado conforme auditoria: Remove o bloco do topo
func remover_topo() -> int:
	if is_vazio():
		return -1
	return cores.pop_back()
