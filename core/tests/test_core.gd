extends SceneTree

# Correção do auditor: evita falha de class_name no headless
const TubeClass = preload("res://core/src/tube.gd")

var falhas := 0

func ok(cond: bool, nome: String) -> void:
	if not cond:
		falhas += 1
		push_error("FALHOU: " + nome)
	else:
		print("OK: ", nome)

func _init() -> void:
	print("--- Iniciando testes do Core ---")
	
	var tubo = TubeClass.new()
	
	# --- Testes Básicos ---
	ok(tubo.is_vazio() == true, "Tubo deve começar vazio")
	ok(tubo.adicionar_cor(1) == true, "Tubo deve aceitar a primeira cor")
	ok(tubo.get_cor_topo() == 1, "O topo deve ser a cor 1")
	ok(tubo.adicionar_cor(-1) == false, "Tubo deve recusar cor inválida (-1)")
	ok(tubo.adicionar_cor(2) == false, "Tubo deve recusar cor diferente")
	
	# --- Teste de Capacidade Diferente (Auditoria) ---
	var tubo_curto = TubeClass.new(2)
	ok(tubo_curto.adicionar_cor(5) == true, "Tubo cap 2 aceita cor 5")
	ok(tubo_curto.is_completo() == false, "Tubo cap 2 com 1 bloco não está completo")
	tubo_curto.adicionar_cor(5)
	ok(tubo_curto.is_completo() == true, "Tubo cap 2 com 2 blocos iguais está completo")
	
	# --- Teste do Bug Silencioso (Tubo Cheio e Misturado) ---
	var tubo_misturado = TubeClass.new()
	tubo_misturado.adicionar_cor(1)
	tubo_misturado.adicionar_cor(2)
	tubo_misturado.adicionar_cor(1)
	tubo_misturado.adicionar_cor(2)
	ok(tubo_misturado.is_cheio() == true, "Tubo misturado deve estar CHEIO")
	ok(tubo_misturado.is_completo() == false, "Tubo misturado NÃO deve estar COMPLETO")
	
	# --- Teste de Remoção e Contagem de Topo ---
	var tubo_teste = TubeClass.new()
	tubo_teste.adicionar_cor(7)
	tubo_teste.adicionar_cor(7)
	tubo_teste.adicionar_cor(8)
	ok(tubo_teste.contar_topo_igual() == 1, "Deve haver 1 bloco de cor 8 no topo")
	ok(tubo_teste.remover_topo() == 8, "Remover topo deve retornar a cor 8")
	ok(tubo_teste.contar_topo_igual() == 2, "Agora deve haver 2 blocos de cor 7 no topo")
	
	if falhas == 0:
		print("OK: Todos os testes passaram!")
	else:
		print("FALHOU: ", falhas, " teste(s)")
		
	quit(0 if falhas == 0 else 1)
