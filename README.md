# luaMiniGame
Mini game developed in one day in love2d (lua) 

Somente uma brincadeira de fim de semana, demonstra a potencialidadade e facilidade
de fazer jogos simples em love2d com lua.

![Screenshot 1](Screenshot%20from%202019-01-27%2017-41-10.png?raw=true "Screen Shot 1")
![Screenshot 2](Screenshot%20from%202019-01-20%2012-25-45.png?raw=true "Screen Shot 2")

Foi implementado somente com objetivo didático para sair da rotina de trabalhos mais sérios.

Todas as imágens e sons foram implemeentados por mim e pelo meu filho Pedro, de 9 anos. O avião, disco voador foram primeiramente desenhados em openscad, depois renderizados em blender. As explosões foram criadas com base em gravação de voz no microfone, com efeitos e modificações efetuadas em audacity. As outras imagens foram criadas utilizando o gimp. A música de abertura e do boss foram feitas por mim, a música do jogo foi feita pelo Pedro. Para as músicas foi utilizado um piano digital conectado ao sintetizador yoshimi, gravado diretamente no audacity.


---

## Changelog

### Refatoração de código compartilhado (prioridade Alta)
- **Novo módulo `game.lua`**: centraliza todo o código idêntico entre os 4 níveis
  (movimento, tiro, explosões, nuvens/solo, colisões, reinicialização de entidades,
  shader de iluminação e render de foreground). Antes cada nível replicava ~1200 linhas;
  agora os níveis ficam enxutos e só definem suas entidades específicas
  (boss/phase/cobra/prato) e a orquestração de `inicia/fim/atualiza/desenha`.
- **`rotinas.lua` removido** (suas funções foram migradas para `game.lua`).
- **`main.lua`**: removeu `require "rotinas"`; o debug (record/pontos) segue intacto.
- **`boss` tornou-se entidade compartilhada** (`game.boss`) — antes era local de cada
  nível e causava referências globais inválidas no render.
- **Correções de bugs** (iteração + `table.remove`):
  - `atualizainimigos1`, `atualizaexplosoes` e as 4 funções de colisão agora coletam os
    índices a remover antes de `table.remove`, evitando pular entradas.
  - **Nível 4**: `atualiza` devolvia `false` fixo no 3º valor; agora retorna
    `not boss.retirado`, alinhado aos demais níveis.
- **Limpeza**: removido `balasboss` (nunca usado) e `finalizarDesenho` (duplicada em `main.lua`).

Como não há interpretador Lua instalado neste ambiente, a validação foi feita por
análise estática (balanceamento de chaves/strings e conferência de parâmetros). Recomenda-se
rodar `love2d miniGame` para confirmar o comportamento em runtime.
