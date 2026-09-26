#!/bin/bash
# Gera os textos do menu como PNGs: TEXTO BRANCO limpo, fundo transparente.
# O efeito neon (glow + sombra) e aplicado em tempo real pelo shader
# efeito_neon.fsh em main.lua - as imagens precisam ser brancas para o
# shader poder tintar o brilho.
#
# NOTA: esta build do ImageMagick tem compositing de camadas semi-transparentes
# quebrado (camadas com alpha sao ignoradas no -composite), por isso o texto e
# desenhado num unico canvas com o primitivo -draw, que funciona de forma
# fiavel. O -draw nesta build escala o texto a ~39/72 do pointsize indicado,
# por isso o fator DPS_FATOR abaixo.
set -e
cd "$(dirname "$0")/assets"

F=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf
DPS_FATOR=1846   # o -draw desenha a ~39/72 do pointsize; 72/39*1000=1846

# mede o texto: devolve "largura altura ascent xoff" desenhado a dps
medir() { # $1 texto $2 dps
  local tmp=/tmp/txtmed_$$
  mkdir -p "$tmp"
  convert -size 800x400 xc:none -font "$F" -pointsize "$2" -fill white \
    -draw "text 0,250 '$1'" "$tmp/t.png"
  local b w h x y
  b=$(convert "$tmp/t.png" -format "%@" info:)
  w=${b%%x*}; b=${b#*x}; h=${b%%+*}; b=${b#*+}
  x=${b%%+*}; y=${b#*+}
  rm -rf "$tmp"
  echo "$w $h $(( 250 - y )) $x"
}

# gera imagem final: texto branco centrado num unico canvas:
#  $1 texto $2 dps $3 canvasW $4 canvasH $5 destino
gerar() {
  local texto="$1" dps="$2" CW="$3" CH="$4" dest="$5"
  local m bw bh asc xoff
  m=$(medir "$texto" "$dps"); bw=${m%% *}; rest=${m#* }; bh=${rest%% *}; rest=${rest#* }
  asc=${rest%% *}; xoff=${rest#* }
  local x0=$(( (CW - bw) / 2 - xoff ))
  local y0=$(( (CH - bh) / 2 + asc ))

  convert -background none -size "${CW}x${CH}" xc:none -font "$F" \
    -pointsize "$dps" -fill white -draw "text $x0,$y0 '$texto'" "$dest"
}

# ajusta o dps para o texto caber na largura maxima:
#  $1 texto $2 largura max -> dps final (usar dps inicial 46)
ajustar() {
  local texto="$1" maxw="$2" dps=46 m w
  m=$(medir "$texto" "$dps"); w=${m%% *}
  if [ "$w" -gt "$maxw" ]; then
    dps=$(( dps * maxw / w ))
  fi
  echo "$dps"
}

# ---------------------------------------------------------------------------
# 1) Linhas do menu (mesmo tamanho nas 4 linhas)
T1="Pressione I para Iniciar"
T2="Pressione R para Reiniciar"
T3="Pressione Esc para Sair"
T4="Pressiona C para Configurações"
PS=999
for t in "$T1" "$T2" "$T3" "$T4"; do
  s=$(ajustar "$t" 460)
  [ "$s" -lt "$PS" ] && PS=$s
done
echo "menu pointsize(dps): $PS"
gerar "$T1" $PS 500 108 texto1.png
gerar "$T2" $PS 500 108 texto2.png
gerar "$T3" $PS 500 108 texto3.png
gerar "$T4" $PS 500 108 texto4.png

# ---------------------------------------------------------------------------
# 2) Titulo do ecran de configuracoes
T5="CONFIGURAÇÕES"
s=$(ajustar "$T5" 440)
[ "$s" -gt 85 ] && s=85
echo "titulo config pointsize(dps): $s"
gerar "$T5" $s 480 120 texto5.png

# ---------------------------------------------------------------------------
# 3) Linhas do ecran de configuracoes
T6="Som: ATIVADO (tecla S)"
T7="Som: DESATIVADO (tecla S)"
T8="Música: ATIVADO (tecla M)"
T9="Música: DESATIVADO (tecla M)"
T10="V - Voltar ao menu anterior"
T11="ESC - Sair"
PS=999
for t in "$T6" "$T7" "$T8" "$T9" "$T10" "$T11"; do
  s=$(ajustar "$t" 450)
  [ "$s" -lt "$PS" ] && PS=$s
done
echo "linhas config pointsize(dps): $PS"
gerar "$T6"  $PS 480 64 texto6.png
gerar "$T7"  $PS 480 64 texto7.png
gerar "$T8"  $PS 480 64 texto8.png
gerar "$T9"  $PS 480 64 texto9.png
gerar "$T10" $PS 480 64 texto10.png
gerar "$T11" $PS 480 64 texto11.png

echo "OK"
