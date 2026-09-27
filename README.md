# luaMiniGame
Mini game developed in one day in love2d (lua) 

[Download executável para windows](https://github.com/ronaldor1968/luaMiniGame/releases/download/0.0.3/distwin.zip).

[Ultima Release](https://github.com/ronaldor1968/luaMiniGame/releases/tag/0.0.3).

Somente uma brincadeira de fim de semana, demonstra a potencialidade e facilidade
de fazer jogos simples em love2d com lua.


![Screenshot 1](Screenshot%20from%202026-09-27%2012-29-35.png?raw=true "Screen Shot 1")
![Screenshot 2](Screenshot%20from%202026-09-27%2012-29-59.png?raw=true "Screen Shot 2")
![Screenshot 3](Screenshot%20from%202026-09-27%2012-25-45.png?raw=true "Screen Shot 3")
![Screenshot 4](Screenshot%20from%202026-09-27%2012-27-55.png?raw=true "Screen Shot 4")


Foi implementado somente com objetivo didático para sair da rotina de trabalhos mais sérios.

Todas as imágens e sons foram implemeentados por mim e pelo meu filho Pedro, de 9 anos. O avião, disco voador foram primeiramente desenhados em openscad, depois renderizados em blender. As explosões foram criadas com base em gravação de voz no microfone, com efeitos e modificações efetuadas em audacity. As outras imagens foram criadas utilizando o gimp. A música de abertura e do boss foram feitas por mim, a música do jogo foi feita pelo Pedro. Para as músicas foi utilizado um piano digital conectado ao sintetizador yoshimi, gravado diretamente no audacity.


---

## Changelog

### Todos os textos do menu/configuração em imagens PNG com efeito neon (shader)
- **`texto1..3.png` regenerados** (DejaVu Sans Bold, texto branco, fundo transparente):
  "Pressione I para Iniciar", "Pressione R para Reiniciar", "Pressione Esc para Sair".
- **Novas imagens** para os textos que usavam a fonte simples do love2d:
  - `texto4.png` — "Pressiona C para Configurações" (antes apenas "C - Opcoes" em 12px,
    quase invisível no menu e no game over)
  - `texto5.png` — "CONFIGURAÇÕES" (título do ecrã de configurações)
  - `texto6/7.png` — "Som: ATIVADO/DESATIVADO (tecla S)"
  - `texto8/9.png` — "Música: ATIVADO/DESATIVADO (tecla M)"
  - `texto10.png` — "V - Voltar ao menu anterior"
  - `texto11.png` — "ESC - Sair"
- **Efeito neon em tempo real**: as imagens são texto branco e um shader
  (`game.shaderNeon`, criado em `game.configurarShader()` como o shader de
  iluminação) aplica **brilho** (16 amostras ponderadas da forma do texto, somadas
  aditivamente, cor configurável) e **sombra** deslocada, via `desenhaNeon` no
  `main.lua`. Três perfis: `NEON.menu` (vermelho), `NEON.titulo` (verde) e
  `NEON.linha` (branco quente) — cores, intensidade e raio ajustáveis no `main.lua`.
  Nota: `send` de vec2/vec3 usa tabelas (`{r, g, b}`) por compatibilidade com a
  API do LÖVE em uso.
- **`desenhaConfig`** desenha apenas imagens neon (o estado ATIVADO/DESATIVADO escolhe
  entre as duas variantes de cada linha).
- **HUD dinâmico** ("pontos:"/"record:"): como os valores mudam em tempo real não podem
  ser imagens; passa a usar `assets/fonte.ttf` (DejaVu Sans Bold, 26px) em vez da fonte
  predefinida de 12px.
- **`gerar_textos.sh`**: script (ImageMagick) usado para gerar todas as imagens de texto
  brancas; permite regenerá-las mudando textos ou tamanhos.
- **Debounce de teclas swap** (`s`/`m` nas configurações e `c` no menu): só reagem na
  transição solta→premida, com cooldown de 0,4 s após cada troca de estado.
- Posições do menu ajustadas (y=586/654/722) para as imagens de 108px não ficarem
  cortadas na margem inferior da janela (480x800).

### Refatoração de código compartilhado (prioridade Alta)
- **Novo módulo `game.lua`**: centraliza todo o código idêntico entre os 4 níveis
  (movimento, tiro, explosões, nuvens/solo, colisões, reinicialização de entidades,
  shader de iluminação e render de foreground). Antes cada nível replicava ~1200 linhas;
  agora os níveis ficam enxutos e só definem suas entidades específicas
  (boss/phase/cobra/prato) e a orquestração de `inicia/fim/atualiza/desenha`.

