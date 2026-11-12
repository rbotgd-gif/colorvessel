class_name Tube

var capacidade: int = 4
var cores: Array[int] = []

func _init(cap: int = 4):
	capacidade = cap

func is_vazio() -> bool:
	return cores.size() == 0

func is_completo() -> bool:
	return cores.size() == capacidade

func get_cor_topo() -> int:
	if is_vazio():
		return -1 # -1 significa vazio
	return cores.back()

func pode_receber(cor_nova: int) -> bool:
	if is_completo():
		return false
	if is_vazio():
		return true
	return get_cor_topo() == cor_nova

func adicionar_cor(cor: int) -> bool:
	if pode_receber(cor):
		cores.append(cor)
		return true
	return false
