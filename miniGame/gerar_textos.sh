#!/bin/bash
# Gera os textos do menu/estilo do jogo como PNGs de alta qualidade
# (fundo transparente, contorno escuro) usando ImageMagick + DejaVu Sans Bold
set -e
cd "$(dirname "$0")/assets"

F=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf

# renderiza etiqueta: $1 texto, $2 pointsize, $3 cor -> $4 ficheiro
render() {
  convert -background none -fill "$3" -font "$F" -pointsize "$2" \
    label:"$1" -trim +repage "$4"
}

# largura do texto renderizado a pointsize 100
largura() {
  convert -background none -fill white -font "$F" -pointsize 100 \
    label:"$1" -trim +repage -format "%w" info:
}

# ponto de partida: escala 100 -> largura alvo
tamanho_ajustado() { # $1 texto, $2 largura max
  local w=$(largura "$1")
  echo $(( 100 * $2 / $w ))
}

# imagem final: $1 texto $2 pointsize $3 fill $4 contorno $5 W $6 H $7 raio contorno $8 destino
gerar() {
  local tmp=/tmp/txtgen_$$
  mkdir -p "$tmp"
  # mascara branca para o contorno
  render "$1" "$2" white "$tmp/mascara.png"
  convert "$tmp/mascara.png" -morphology Dilate "Disk:$7" \
    -fill "$4" -opaque white "$tmp/contorno.png"
  # texto colorido
  render "$1" "$2" "$3" "$tmp/cores.png"
  # compor: contorno atrás, texto à frente, centrado no canvas
  convert "$tmp/contorno.png" "$tmp/cores.png" -gravity center -composite \
    -background none -gravity center -extent "${5}x${6}" "$8"
  rm -rf "$tmp"
}

# ---------------------------------------------------------------------------
# 1) Linhas do menu (mesmo tamanho de letra nas 4 linhas)
#    canvas 500x108 igual aos existentes
MAXW=460
T1="Pressione I para Iniciar"
T2="Pressione R para Reiniciar"
T3="Pressione Esc para Sair"
T4="Pressiona C para Configurações"
PS=999
for t in "$T1" "$T2" "$T3" "$T4"; do
  s=$(tamanho_ajustado "$t" $MAXW)
  [ "$s" -lt "$PS" ] && PS=$s
done
echo "menu pointsize: $PS"
gerar "$T1" $PS "#E8264F" "#400813" 500 108 2 texto1.png
gerar "$T2" $PS "#E8264F" "#400813" 500 108 2 texto2.png
gerar "$T3" $PS "#E8264F" "#400813" 500 108 2 texto3.png
gerar "$T4" $PS "#E8264F" "#400813" 500 108 2 texto4.png

# ---------------------------------------------------------------------------
# 2) Título do ecrã de configurações (verde como o titulo do jogo)
T5="CONFIGURAÇÕES"
s=$(tamanho_ajustado "$T5" 440)
[ "$s" -gt 54 ] && s=54
echo "titulo config pointsize: $s"
gerar "$T5" $s "#3FFC00" "#0B4A00" 480 120 3 texto5.png

# ---------------------------------------------------------------------------
# 3) Linhas do ecrã de configurações
T6="Som: ATIVADO (tecla S)"
T7="Som: DESATIVADO (tecla S)"
T8="Música: ATIVADO (tecla M)"
T9="Música: DESATIVADO (tecla M)"
T10="V - Voltar ao menu anterior"
T11="ESC - Sair"
PS=999
for t in "$T6" "$T7" "$T8" "$T9" "$T10" "$T11"; do
  s=$(tamanho_ajustado "$t" 450)
  [ "$s" -lt "$PS" ] && PS=$s
done
echo "linhas config pointsize: $PS"
gerar "$T6"  $PS "#F2E9DC" "#4A443C" 480 64 2 texto6.png
gerar "$T7"  $PS "#F2E9DC" "#4A443C" 480 64 2 texto7.png
gerar "$T8"  $PS "#F2E9DC" "#4A443C" 480 64 2 texto8.png
gerar "$T9"  $PS "#F2E9DC" "#4A443C" 480 64 2 texto9.png
gerar "$T10" $PS "#F2E9DC" "#4A443C" 480 64 2 texto10.png
gerar "$T11" $PS "#F2E9DC" "#4A443C" 480 64 2 texto11.png

echo "OK"
