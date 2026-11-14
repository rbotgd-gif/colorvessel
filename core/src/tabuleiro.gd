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
