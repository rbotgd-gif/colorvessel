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
	
	# Instancia a classe Tube que criamos
	var tubo = Tube.new()
	
	ok(tubo.is_vazio() == true, "Tubo deve começar vazio")
	ok(tubo.is_completo() == false, "Tubo não deve começar cheio")
	
	var aceitou = tubo.adicionar_cor(1) # 1 = Vermelho
	ok(aceitou == true, "Tubo deve aceitar a primeira cor")
	ok(tubo.get_cor_topo() == 1, "O topo deve ser a cor 1")
	
	tubo.adicionar_cor(2) # 2 = Azul
	ok(tubo.get_cor_topo() == 2, "O topo agora deve ser a cor 2")
	
	# Enche o tubo
	tubo.adicionar_cor(2)
	tubo.adicionar_cor(2)
	ok(tubo.is_completo() == true, "Tubo deve estar cheio após 4 blocos")
	
	var recusou = tubo.adicionar_cor(3)
	ok(recusou == false, "Tubo cheio deve recusar nova cor")
	
	if falhas == 0:
		print("OK: Todos os testes passaram!")
	else:
		print("FALHOU: ", falhas, " teste(s)")
		
	quit(0 if falhas == 0 else 1)
