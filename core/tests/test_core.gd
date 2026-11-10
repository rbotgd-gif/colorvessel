extends SceneTree

var falhas := 0

func ok(cond: bool, nome: String) -> void:
    if not cond:
        falhas += 1
        push_error("FALHOU: " + nome)

func _init() -> void:
    ok(true, "sanity check")
    if falhas == 0:
        print("OK: todos os testes passaram")
    else:
        print("FALHOU: ", falhas, " teste(s)")
    quit(0 if falhas == 0 else 1)
