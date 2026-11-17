extends RefCounted
# Design tokens do estilo "Juicy Glossy" + Geladeira Térmica (Especificação V1.5).
# Só dados: nenhuma lógica de jogo. Todo valor visual reutilizável mora aqui.

# --- Viewport (retrato) ---
const LARGURA_TELA: int = 720
const ALTURA_TELA: int = 1280

# --- Cores de marca ---
const OURO := Color("#FFC300")
const OURO_ESCURO := Color("#B8860B")
const OURO_CLARO := Color("#FFE27A")
const CIANO_GELO := Color("#38E8FF")
const VERDE_OK := Color("#7CFFB2")
const VERMELHO_ALERTA := Color("#FF5A5F")
const TEXTO := Color("#E6FBFF")
const TEXTO_ESCURO := Color("#0B2530")
const NEUTRO := Color("#8D99AE")
const ROXO := Color("#5A189A")        # HUD/Dock: corpo das pílulas roxas
const ROXO_ESCURO := Color("#3C096C")

# --- Visor térmico (painéis escuros translúcidos) ---
const VISOR_FUNDO := Color(0.03, 0.08, 0.12, 0.72)
const VISOR_BORDA := Color(0.22, 0.91, 1.0, 0.65)
const VISOR_BRILHO := Color(0.22, 0.91, 1.0, 0.22)

# --- Fundo térmico ---
const FUNDO_FRIO := Color.WHITE
const FUNDO_QUENTE := Color("#FFB077")

# --- Variantes de botão: cor base (o resto é derivado em CVTema) ---
const BOTAO_PRIMARIO := Color("#2DC653")   # verde: ação principal
const BOTAO_SECUNDARIO := Color("#0096C7") # ciano: ações neutras
const BOTAO_PERIGO := Color("#E63946")
const BOTAO_OURO := Color("#FFB703")       # compras / destaque

# --- Paleta dos líquidos (chave = cor do Core, a partir de 1) ---
# Ciano e Rosa vêm do Art Bible; as demais são provisórias.
const CORES_LIQUIDO: Dictionary = {
	1: Color("#0096C7"),
	2: Color("#E00088"),
	3: Color("#FFB703"),
	4: Color("#2DC653"),
	5: Color("#7B2CBF"),
	6: Color("#FB6107"),
	7: Color("#D62828"),
	8: Color("#3A0CA3"),
	9: Color("#8AC926"),
}

# --- Geometria ---
const RAIO_PILULA: int = 999   # "meia-lua": o StyleBox limita ao máximo possível
const RAIO_PAINEL: int = 14
const RAIO_BOTAO: int = 18
const BORDA: int = 3
const PROFUNDIDADE_BOTAO: int = 6  # borda inferior grossa = efeito 3D
const MARGEM_H: int = 20
const MARGEM_V: int = 8
const TAM_BOTAO := Vector2(220, 64)

# --- Tipografia ---
const FONTE_CAMINHO := "res://visual/assets/fonts/Fredoka-Bold.ttf"  # opcional (OFL)
const TAM_FONTE_TITULO: int = 32
const TAM_FONTE_CORPO: int = 24
const TAM_FONTE_PEQUENA: int = 18

# --- Animação ---
const DURACAO_TOQUE: float = 0.10
const DURACAO_RETORNO: float = 0.30
const ESCALA_TOQUE: float = 0.92
const ESCALA_HOVER: float = 1.05
