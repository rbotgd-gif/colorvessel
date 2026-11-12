extends SceneTree

var falhas := 0

func ok(cond: bool, nome: String) -> void:
	if not cond:
		falhas += 1
		push_error("FALHOU: " + nome)
	else:
		print("OK: ", nome)

func _init() -> void:
	print("--- Iniciando testes do Core ---")
	
	var tubo = Tube.new()
	
	ok(tubo.is_vazio() == true, "Tubo deve começar vazio")
	
	var aceitou = tubo.adicionar_cor(1) # 1 = Vermelho
	ok(aceitou == true, "Tubo deve aceitar a primeira cor")
	ok(tubo.get_cor_topo() == 1, "O topo deve ser a cor 1")
	
	# Tenta colocar cor diferente (2 = Azul). O tubo deve RECUSAR.
	var recusou_cor_errada = tubo.adicionar_cor(2)
	ok(recusou_cor_errada == false, "Tubo deve recusar cor diferente")
	ok(tubo.get_cor_topo() == 1, "O topo deve continuar sendo a cor 1")
	
	# Adiciona mais duas cores iguais (1) para chegar a 4 blocos
	tubo.adicionar_cor(1)
	tubo.adicionar_cor(1)
	ok(tubo.is_completo() == true, "Tubo deve estar cheio após 4 blocos iguais")
	
	var recusou_cheio = tubo.adicionar_cor(1)
	ok(recusou_cheio == false, "Tubo cheio deve recusar mais cor")
	
	if falhas == 0:
		print("OK: Todos os testes passaram!")
	else:
		print("FALHOU: ", falhas, " teste(s)")
		
	quit(0 if falhas == 0 else 1)
