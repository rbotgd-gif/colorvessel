class_name Tabuleiro
extends RefCounted
# Core puro: sem Node, sem cena. Tabuleiro é dono da lista de tubos e da regra de verter.

# Sinais do contrato Core -> Visual (docs/contrato-core-visual.md).
# tube_selected/tube_deselected pertencem à seleção, que é estado de UI na view.
signal pour_started(from: int, to: int)
signal pour_finished(from: int, to: int, color: int)
signal pour_invalid(from: int, to: int, reason: String)
signal tube_completed(index: int, color: int)
signal level_won(moves_total: int)
signal state_changed(state_dict: Dictionary)

const HistoricoClass = preload("res://core/src/historico.gd")

# Poder +1 Tubo: máximo de tubos auxiliares por fase.
const MAX_TUBOS_AUXILIARES: int = 1

var tubos: Array[Tube] = []
var historico = HistoricoClass.new()
var movimentos_feitos: int = 0
# Quantidade de tubos da fase sem auxiliares (define quantos auxiliares já existem).
var _tubos_base: int = 0

func _init(lista_tubos: Array[Tube] = []) -> void:
	tubos = lista_tubos
	_tubos_base = tubos.size()

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

# Jogada do jogador: registra no histórico (Desfazer), emite os sinais do contrato.
func mover_liquido(idx_origem: int, idx_destino: int) -> bool:
	if calcular_quantidade(idx_origem, idx_destino) <= 0:
		pour_invalid.emit(idx_origem, idx_destino, _motivo_invalido(idx_origem, idx_destino))
		return false
	var snapshot := _snapshot()
	pour_started.emit(idx_origem, idx_destino)
	var cor: int = tubos[idx_origem].get_cor_topo()
	mover_sem_historico(idx_origem, idx_destino)
	historico.registrar(snapshot)
	movimentos_feitos += 1
	pour_finished.emit(idx_origem, idx_destino, cor)
	if tubos[idx_destino].is_completo():
		tube_completed.emit(idx_destino, cor)
	state_changed.emit(estado_bruto())
	if is_vitoria():
		level_won.emit(movimentos_feitos)
	return true

# Verte sem histórico nem sinais (usado pelo Solucionador em tabuleiros de trabalho).
func mover_sem_historico(idx_origem: int, idx_destino: int) -> bool:
	var qtd: int = calcular_quantidade(idx_origem, idx_destino)
	if qtd <= 0:
		return false
	var origem: Tube = tubos[idx_origem]
	var destino: Tube = tubos[idx_destino]
	for i in qtd:
		destino.adicionar_cor(origem.remover_topo())
	return true

func _motivo_invalido(idx_origem: int, idx_destino: int) -> String:
	if not _indice_valido(idx_origem) or not _indice_valido(idx_destino):
		return "indice_invalido"
	if idx_origem == idx_destino:
		return "mesmo_tubo"
	if tubos[idx_origem].is_vazio():
		return "origem_vazia"
	if tubos[idx_destino].is_cheio():
		return "destino_cheio"
	return "cor_diferente"

# Estado bruto para a view desenhar (sem referências ao Core).
func estado_bruto() -> Dictionary:
	var lista: Array = []
	for t in tubos:
		lista.append({"capacidade": t.capacidade, "cores": t.cores.duplicate()})
	return {"tubos": lista, "movimentos": movimentos_feitos}

# Snapshot = [[capacidade, cores], ...] — inclui capacidade porque +1 Tubo muda a lista.
func _snapshot() -> Array:
	var snap: Array = []
	for t in tubos:
		snap.append([t.capacidade, t.cores.duplicate()])
	return snap

# --- Poder Desfazer ---

func pode_desfazer() -> bool:
	return historico.pode_desfazer()

# Volta uma jogada (ou a compra do tubo auxiliar). false se não houver histórico.
func desfazer() -> bool:
	if not historico.pode_desfazer():
		return false
	var snap: Array = historico.desfazer()
	var novos: Array[Tube] = []
	for par in snap:
		var t := Tube.new(par[0])
		t.cores.assign(par[1])
		novos.append(t)
	if novos.size() == tubos.size():  # desfazer o tubo auxiliar não é jogada
		movimentos_feitos = maxi(movimentos_feitos - 1, 0)
	tubos = novos
	state_changed.emit(estado_bruto())
	return true

# --- Poder Dica ---

# Próximo movimento da menor solução (BFS) como Vector2i(origem, destino).
# Vector2i(-1, -1) se a fase já está vencida ou não é (comprovadamente) resolvível
# a partir do estado atual. Não altera o tabuleiro.
func dica() -> Vector2i:
	if is_vitoria():
		return SEM_DICA
	var r: Dictionary = SolucionadorClass.resolver(self)
	if r["resultado"] != SolucionadorClass.Resultado.RESOLVIVEL or r["movimentos"].is_empty():
		return SEM_DICA
	return r["movimentos"][0]

const SEM_DICA := Vector2i(-1, -1)

# --- Poder +1 Tubo ---

func tubos_auxiliares() -> int:
	return tubos.size() - _tubos_base

func pode_adicionar_tubo() -> bool:
	return tubos_auxiliares() < MAX_TUBOS_AUXILIARES and not is_vitoria()

# Acrescenta um tubo vazio (capacidade do padrão da fase) ao final. Entra no histórico:
# Desfazer remove o tubo (e devolve o direito de usar o poder). Custo/economia é do meta-game.
func adicionar_tubo_auxiliar() -> bool:
	if not pode_adicionar_tubo():
		return false
	var cap: int = tubos[0].capacidade if not tubos.is_empty() else 4
	historico.registrar(_snapshot())
	tubos.append(Tube.new(cap))
	state_changed.emit(estado_bruto())
	return true

func _reiniciar_sessao() -> void:
	historico.limpar()
	movimentos_feitos = 0
	_tubos_base = tubos.size()

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
	var aceito := _gerar(qtd_cores)
	_reiniciar_sessao()
	state_changed.emit(estado_bruto())
	return aceito

func _gerar(qtd_cores: int) -> bool:
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
