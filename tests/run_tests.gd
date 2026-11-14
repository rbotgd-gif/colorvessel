extends SceneTree
# Runner unificado: roda todo test_*.gd de core/tests/ e visual/tests/.
# Cada teste é um SceneTree que chama quit(), então roda em processo Godot próprio.
# Uso: godot --headless --path . -s res://tests/run_tests.gd
# Sai com 0 só se TODOS passarem.

const PASTAS := ["res://core/tests", "res://visual/tests"]

func descobrir_testes() -> Array[String]:
	var testes: Array[String] = []
	for pasta in PASTAS:
		var arquivos := DirAccess.get_files_at(pasta)
		for nome in arquivos:
			if nome.begins_with("test_") and nome.ends_with(".gd"):
				testes.append(pasta + "/" + nome)
	return testes

func _initialize() -> void:
	var godot := OS.get_executable_path()
	var projeto := ProjectSettings.globalize_path("res://")
	var testes := descobrir_testes()
	var falhos: Array[String] = []

	print("=== Runner de testes: %d arquivo(s) ===" % testes.size())
	if testes.is_empty():
		push_error("Nenhum teste encontrado em %s" % [PASTAS])
		quit(1)
		return

	for teste in testes:
		print("\n>>> ", teste)
		var saida: Array = []
		var codigo := OS.execute(godot, ["--headless", "--path", projeto, "-s", teste], saida, true)
		for linha in saida:
			print(linha.strip_edges(false, true))
		if codigo != 0:
			falhos.append("%s (código %d)" % [teste, codigo])

	print("\n=== Resumo: %d/%d arquivo(s) passaram ===" % [testes.size() - falhos.size(), testes.size()])
	for f in falhos:
		print("FALHOU: ", f)
	quit(0 if falhos.is_empty() else 1)
