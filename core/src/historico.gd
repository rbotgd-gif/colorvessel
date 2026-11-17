class_name Historico
extends RefCounted
# Core puro: pilha de snapshots do tabuleiro (base do poder Desfazer).
# Não conhece Tabuleiro nem nós: guarda cópias opacas (Array) e devolve a última.

const LIMITE_PADRAO: int = 200

var limite: int = LIMITE_PADRAO
var _pilha: Array = []

func _init(limite_max: int = LIMITE_PADRAO) -> void:
	assert(limite_max > 0, "Historico: limite deve ser > 0")
	limite = maxi(limite_max, 1)

# Guarda o snapshot (duplicação profunda: mudanças posteriores no original não vazam).
# Estourando o limite, descarta o mais antigo.
func registrar(snapshot: Array) -> void:
	_pilha.append(snapshot.duplicate(true))
	if _pilha.size() > limite:
		_pilha.pop_front()

func pode_desfazer() -> bool:
	return not _pilha.is_empty()

func tamanho() -> int:
	return _pilha.size()

# Remove e devolve o snapshot mais recente; [] se não houver nada a desfazer.
func desfazer() -> Array:
	if _pilha.is_empty():
		return []
	return _pilha.pop_back()

func limpar() -> void:
	_pilha.clear()
