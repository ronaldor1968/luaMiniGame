-- game.lua
-- Funcoes e entidades compartilhadas entre os niveis.
-- Cada nivel e responsavel apenas por:
--   * suas entidades de inimigos especificas (boss/phase/cobra/prato/inimigo)
--   * sua funcao inicia/fim/atualiza/desenha
-- O restante (movimento, tiro, explosoes, nuvens, colisoes, shader, render de
-- foreground) esta centralizado aqui para nao duplicar entre os niveis.
require "utils"

local game = {}

-- pontos partilhados entre os niveis (acumulam; sao zerados apenas ao
-- iniciar um novo jogo, em nivel1.inicia)
game.pontos = 0

-- ============================================================
-- Entidades compartilhadas
-- ============================================================

function game.criarEntidades()
    game.jogador = {x = 200, y = 710, speed = 150, vivo = true, img = nil}
    game.balas = {
        img = nil,
        som = nil,
        tempoRecarga = 0.2,
        tempoAposUltimoTiro = 0.2,
        recarregado = true,
        lista = {}
    }
    game.explosao = {imgs = {}, lista = {}, tempoExplosao = 0.5}
    game.nuvem = {img = nil, y1 = -3200, y2 = -6400}
    game.solo = {img = nil, y1 = -3200, y2 = -6400}
    game.inimigo = {img = nil, som = nil, maximo = 2, tempoAposCriarUltimoInimigo = 1, tempoCriacao = 1, lista = {}}
    game.boss = {
        x = -60,
        y = -600,
        danos = 0,
        limitedanos = 100,
        iniciado = false,
        retirado = false,
        ativo = false,
        retirada = false,
        pontosativo = 100,
        pontosretirada = 40
    }
    game.angular = 0
    game.iluminacao = 0
    game.myshader = nil
    game.shaderNeon = nil
    game.musica = {som = nil}
end

function game.configurar(recursos)
    -- cria (ou recria) as entidades compartilhadas
    game.criarEntidades()

    -- atribui imagens e sons das entidades compartilhadas
    game.inimigo.img = recursos.imgs.inimigo
    game.inimigo.som = recursos.sons.inimigo
    game.inimigo.hw = game.inimigo.img:getWidth() / 2
    game.inimigo.hh = game.inimigo.img:getWidth() / 2
    game.inimigo.som:setVolume(0.5)
    game.jogador.img = recursos.imgs.jogador
    game.jogador.som = recursos.sons.jogador
    game.jogador.som:setVolume(0.9)
    game.balas.img = recursos.imgs.balas
    game.balas.som = recursos.sons.balas
    game.balas.som:setVolume(0.3)
    game.nuvem.img = recursos.imgs.nuvem
    game.solo.img = recursos.imgs.solo
    for i = 1, 8 do
        game.explosao.imgs[i] = recursos.imgs.explosao[i]
    end
    game.musica.som = recursos.sons.musica1
    game.musica.som:setVolume(0.1)
    game.musica.som:setLooping(true)
    game.angular = 0
    game.iluminacao = 0
    game.myshader = nil
    game.shaderNeon = nil
    game.configurarShader()
    game.jogador.vivo = true
end

function game.configurarShader(base)
    local pixelcode = [[

extern int base;
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screenCoords){
  float r = screenCoords.y / base;
  vec4 nColor = vec4(r);
  return Texel(texture, texture_coords) * nColor * color;
}
    ]]

    game.myshader = love.graphics.newShader(pixelcode)

    -- shader de efeito neon (glow + sombra) para os textos do menu/configuracoes
    -- NAO usar uniforms vec2/vec3: nesta versao do LÖVE o send com tabela
    -- nao chega ao shader; todos os uniforms sao escalares (mesmo padrão do
    -- shader de iluminacao acima, cujo send escalar funciona).
    local neoncode = [[
extern vec2 texturepx;
extern float time;

uniform float u_glowR;
uniform float u_glowG;
uniform float u_glowB;
uniform float u_glowIntensity;
uniform float u_glowRadius;
uniform float u_shadowX;
uniform float u_shadowY;
uniform float u_shadowStrength;
uniform float u_speed;
uniform float u_flicker;

vec4 effect(vec4 color, Image texture, vec2 uv, vec2 screenCoords) {
  vec4 base = Texel(texture, uv);
  vec3 neon = vec3(u_glowR, u_glowG, u_glowB);

  // --- animacao: pulsacao lenta + tremulacao de letreiro (neon a falhar) ---
  float pulso = 0.85 + 0.15 * sin(time * u_speed);
  float ruid = step(0.94, fract(sin(floor(time * 18.0) * 91.17) * 43758.5453));
  float anim = mix(pulso, 0.3, ruid * u_flicker);

  // glow: 20 amostras em tres aneis (pseudo-desfoque), somadas
  vec2 r1 = texturepx * u_glowRadius;
  vec2 r2 = r1 * 1.7;
  vec2 r3 = r1 * 2.6;
  vec4 g = vec4(0.0);
  g  = Texel(texture, uv + vec2( r1.x,  0.0));
  g += Texel(texture, uv + vec2(-r1.x,  0.0));
  g += Texel(texture, uv + vec2( 0.0,  r1.y));
  g += Texel(texture, uv + vec2( 0.0, -r1.y));
  g += Texel(texture, uv + vec2( r1.x,  r1.y)) * 0.7;
  g += Texel(texture, uv + vec2(-r1.x,  r1.y)) * 0.7;
  g += Texel(texture, uv + vec2( r1.x, -r1.y)) * 0.7;
  g += Texel(texture, uv + vec2(-r1.x, -r1.y)) * 0.7;
  g += Texel(texture, uv + vec2( r2.x,  0.0)) * 0.55;
  g += Texel(texture, uv + vec2(-r2.x,  0.0)) * 0.55;
  g += Texel(texture, uv + vec2( 0.0,  r2.y)) * 0.55;
  g += Texel(texture, uv + vec2( 0.0, -r2.y)) * 0.55;
  g += Texel(texture, uv + vec2( r2.x,  r2.y)) * 0.38;
  g += Texel(texture, uv + vec2(-r2.x,  r2.y)) * 0.38;
  g += Texel(texture, uv + vec2( r2.x, -r2.y)) * 0.38;
  g += Texel(texture, uv + vec2(-r2.x, -r2.y)) * 0.38;
  g += Texel(texture, uv + vec2( r3.x,  0.0)) * 0.3;
  g += Texel(texture, uv + vec2(-r3.x,  0.0)) * 0.3;
  g += Texel(texture, uv + vec2( 0.0,  r3.y)) * 0.3;
  g += Texel(texture, uv + vec2( 0.0, -r3.y)) * 0.3;
  float glowA = g.r * u_glowIntensity * anim;

  // sombra: forma do texto deslocada, escurece a area atras
  vec4 sh = Texel(texture, uv + vec2(u_shadowX, u_shadowY) * texturepx);
  float shA = sh.r * u_shadowStrength;

  // tubo aceso: branco tingido de neon, pulsa, com brilho a correr ao longo
  float shimmer = 0.10 * sin(uv.x * 30.0 - time * 2.5);
  vec3 tubo = mix(vec3(1.0), neon, 0.35) * (0.8 + 0.4 * anim) + vec3(shimmer);

  // cor final: glow aditivo, sombra, tubo por cima
  vec3 col = max(neon * glowA - vec3(shA * 0.9), vec3(0.0));
  col = mix(col, tubo, base.r);
  col = col * (1.0 - shA * (1.0 - base.r) * 0.35);

  float a = min(max(base.r, max(glowA, shA)), 1.0);
  return vec4(col * color.rgb, a * color.a);
}
    ]]

    game.shaderNeon = love.graphics.newShader(neoncode)
end

-- ============================================================
-- Movimento, tiro, explosões, ambiente
-- ============================================================

function game.atualizaDificuldade(...)
    local pontos, phase = ...
    if pontos > 10 then
        game.inimigo.tempoCriacao = 1
        phase.intervaloMaximo = 13
        if pontos < 200 then
            game.inimigo.tempoCriacao = 0.9
            phase.intervaloMaximo = 12
            game.balas.tempoRecarga = 0.15
        elseif pontos < 500 then
            game.inimigo.tempoCriacao = 0.7
            phase.intervaloMaximo = 10
            game.balas.tempoRecarga = 0.1
        elseif pontos < 1000 then
            game.inimigo.tempoCriacao = 0.5
            phase.intervaloMaximo = 7
        elseif pontos < 3000 then
            game.inimigo.tempoCriacao = 0.3
            phase.intervaloMaximo = 5
        elseif pontos < 5000 then
            game.inimigo.tempoCriacao = 0.2
            phase.intervaloMaximo = 4
        else
            game.inimigo.tempoCriacao = 0.1
            phase.intervaloMaximo = 2
        end
    end
end

function game.movejogador(...)
    local dt, jogador = ...
    if love.keyboard.isDown("left", "a") then
        if jogador.x > 0 then -- binds us to the map
            jogador.x = jogador.x - (jogador.speed * dt)
        end
    end
    if love.keyboard.isDown("right", "d") then
        if jogador.x < (love.graphics.getWidth() - jogador.img:getWidth()) then
            jogador.x = jogador.x + (jogador.speed * dt)
        end
    end
    if love.keyboard.isDown("up", "w") then
        if jogador.y > 0 then
            jogador.y = jogador.y - (jogador.speed * dt)
        end
    end
    if love.keyboard.isDown("down", "s") then
        if jogador.y < 710 then
            jogador.y = jogador.y + (jogador.speed * dt)
        end
    end
end

function game.dispara(...)
    local dt, jogador, balas, deltaSpeed, deltaRecarga = ...
    if love.keyboard.isDown("space", "rctrl", "lctrl") then
        if jogador.vivo and balas.recarregado then
            -- cria balas
            local newBullet = {x = jogador.x + (jogador.img:getWidth() - balas.img:getWidth()) / 2, y = jogador.y}
            table.insert(balas.lista, newBullet)
            balas.recarregado = false
            balas.tempoAposUltimoTiro = balas.tempoRecarga
            tocarEfeito(balas.som)
        end
    else
        balas.tempoAposUltimoTiro = balas.tempoAposUltimoTiro - deltaRecarga
        if (balas.tempoAposUltimoTiro < 0) then
            balas.recarregado = true
        end
    end

    -- atualiza posicao das balas
    for i, blTmp in pairs(balas.lista) do
        blTmp.y = blTmp.y - deltaSpeed

        if blTmp.y < 0 then -- remove balas when they pass off the screen
            table.remove(balas.lista, i)
        end
    end
end

function game.atualizaexplosoes(...)
    local dt, explosao, deltaTempo, deltaSpeed = ...
    local remover = {}
    for i, expTmp in pairs(explosao.lista) do
        expTmp.tempo = expTmp.tempo - deltaTempo
        expTmp.y = expTmp.y + deltaSpeed
        if (expTmp.tempo < 0) then
            expTmp.tempo = explosao.tempoExplosao
            if expTmp.indice < 8 then
                expTmp.indice = expTmp.indice + 1
            else
                table.insert(remover, i)
            end
        end
    end
    local n = #remover
    for k = n, 1, -1 do
        table.remove(explosao.lista, remover[k])
    end
end

function game.movenuvenssolo(...)
    local dt, nuvem, solo, deltaNuvem, deltaSolo = ...
    nuvem.y1 = nuvem.y1 + deltaNuvem
    nuvem.y2 = nuvem.y2 + deltaNuvem
    if (nuvem.y1 > 0) then
        nuvem.y1 = -6400
    end
    if (nuvem.y2 > 0) then
        nuvem.y2 = -6400
    end

    solo.y1 = solo.y1 + deltaSolo
    solo.y2 = solo.y2 + deltaSolo
    if (solo.y1 > 0) then
        solo.y1 = -6400
    end
    if (solo.y2 > 0) then
        solo.y2 = -6400
    end
end

function game.atualizainimigos1(...)
    local dt, pontos, inimigo, deltaSpeed, deltaTempo = ...
    local remover = {}
    -- atualiza posicao inimigo
    for i, iniTmp in pairs(inimigo.lista) do
        iniTmp.y = iniTmp.y + deltaSpeed
        if iniTmp.x > 400 or iniTmp.x < 0 then
            iniTmp.delta_x = -iniTmp.delta_x
        end
        iniTmp.x = iniTmp.x + iniTmp.delta_x

        if iniTmp.y > 850 then -- remove inimigos quando sai da tela
            table.insert(remover, i)
        end
    end
    local n = #remover
    for k = n, 1, -1 do
        table.remove(inimigo.lista, remover[k])
    end

    inimigo.tempoAposCriarUltimoInimigo = inimigo.tempoAposCriarUltimoInimigo - deltaTempo
    if inimigo.tempoAposCriarUltimoInimigo < 0 then
        inimigo.tempoAposCriarUltimoInimigo = inimigo.tempoCriacao
        if (#inimigo.lista < inimigo.maximo) then
            -- cria novo inimigo
            local dx = math.random(-1, 1) * pontos
            if (dx > 100) then
                dx = 100
            elseif dx < -100 then
                dx = -100
            end
            table.insert(
                inimigo.lista,
                {x = math.random(10, love.graphics.getWidth() - 80), y = -30, delta_x = dx * dt, s = math.random(-2, 2)}
            )
        end
    end
end

function game.atualizainimigos2(...)
    local dt, phase, deltaTempo, deltaSpeed = ...
    phase.tempoAposUltimoTiro = phase.tempoAposUltimoTiro - deltaTempo
    if phase.y > 800 and phase.tempoAposUltimoTiro < 0 then
        -- novo tipo de phase
        phase.y = -800
        phase.x = math.random(10, 510)
        phase.tempoAposUltimoTiro = phase.intervaloMaximo
        tocarEfeito(phase.som)
    else
        phase.y = phase.y + deltaSpeed
    end
end

function game.atualizainimigos3(...)
    local dt, angular, pontos, cobra, deltaSpeed = ...
    cobra.ybase = cobra.ybase + deltaSpeed
    if cobra.ybase > 1400 then
        cobra.ybase = -3000
        for i, cblTmp in pairs(cobra.lista) do
            cblTmp.viva = true
        end
    end
    for i, cblTmp in pairs(cobra.lista) do
        local a = angular + i * 0.628
        cblTmp.x = math.sin(a) * 100
        cblTmp.y = -40 * i
    end
end

function game.atualizainimigos4(...)
    local dt, angular, pontos, prato, deltaSpeed = ...
    prato.ybase = prato.ybase + deltaSpeed
    if prato.ybase > 1400 then
        prato.ybase = -2000
        for i, cblTmp in pairs(prato.lista) do
            cblTmp.viva = true
        end
    end
    for i, cblTmp in pairs(prato.lista) do
        local a = angular + i * 0.628 * 4
        cblTmp.x = math.sin(a) * 100
        cblTmp.y = -40 * i
    end
end

function game.atualizaboss1(...)
    local dt, pontos, boss, pontosboss, speed = ...

    if boss.ativo then
        if not boss.iniciado then
            if boss.y < -200 then
                boss.y = boss.y + speed
            else
                boss.iniciado = true
                boss.pontosretirada = pontos + pontosboss
            end
        else
            if not boss.retirada then
                boss.retirada = (pontos > boss.pontosretirada)
            else
                if boss.y > -700 then
                    boss.y = boss.y - speed
                else
                    boss.retirado = true
                    boss.som:stop()
                end
            end
        end
    else
        boss.ativo = (pontos > boss.pontosativo)
        if (boss.ativo) then
            tocarMusica(boss.som)
        end
    end
end

-- ============================================================
-- Colisoes (corrigido: nao remover durante iteracao com pairs)
-- ============================================================

function game.colisaobalainimigojogador(...)
    local dt, balas, inimigo, jogador, explosao, pontos = ...
    local deltapontos = 0
    local tolerancia = 1
    local w1 = inimigo.img:getWidth()
    local h1 = inimigo.img:getHeight()
    local w2 = balas.img:getWidth()
    local h2 = balas.img:getHeight()
    local w3 = jogador.img:getWidth() * tolerancia
    local h3 = jogador.img:getHeight() * tolerancia

    local removerBala, removerInimigo = {}, {}
    for i, iniTmp in pairs(inimigo.lista) do
        for j, blTmp in pairs(balas.lista) do
            if testesSimplesDeColisao(iniTmp.x, iniTmp.y, w1, h1, blTmp.x, blTmp.y, w2, h2) then
                inimigo.maximo = 2 + pontos / 10
                tocarEfeito(inimigo.som)
                deltapontos = deltapontos + 1
                table.insert(explosao.lista, {x = iniTmp.x - 80, y = iniTmp.y - 80, tempo = explosao.tempoExplosao, indice = 1})
                table.insert(removerBala, j)
                table.insert(removerInimigo, i)
                break
            end
        end

        if testesSimplesDeColisao(iniTmp.x, iniTmp.y, w1, h1, jogador.x, jogador.y, w3, h3) then
            tocarEfeito(jogador.som)
            tocarEfeito(inimigo.som)
            table.insert(removerInimigo, i)
            table.insert(explosao.lista, {x = iniTmp.x - 80, y = iniTmp.y - 80, tempo = explosao.tempoExplosao, indice = 1})
            table.insert(explosao.lista, {x = jogador.x - 80, y = jogador.y - 80, tempo = explosao.tempoExplosao, indice = 1})
            jogador.vivo = false
        end
    end

    local n = #removerInimigo
    for k = n, 1, -1 do
        table.remove(inimigo.lista, removerInimigo[k])
    end
    local m = #removerBala
    for l = m, 1, -1 do
        table.remove(balas.lista, removerBala[l])
    end

    return deltapontos
end

function game.colisaoinimigo2jogador(...)
    local dt, phase, jogador, explosao = ...
    if testaColisao(phase, jogador) then
        tocarEfeito(jogador.som)
        table.insert(explosao.lista, {x = jogador.x - 80, y = jogador.y - 80, tempo = explosao.tempoExplosao, indice = 1})
        jogador.vivo = false
    end
end

function game.colisaobalainimigo3jogador(...)
    local dt, balas, cobra, jogador, explosao = ...
    local deltapontos = 0
    local tolerancia = 1
    local w1 = cobra.img:getWidth()
    local h1 = cobra.img:getHeight()
    local w2 = balas.img:getWidth()
    local h2 = balas.img:getHeight()
    local w3 = jogador.img:getWidth() * tolerancia
    local h3 = jogador.img:getHeight() * tolerancia

    local removerBala, removerCobra = {}, {}
    for i, clbBase in pairs(cobra.lista) do
        if clbBase.viva then
            for j, blTmp in pairs(balas.lista) do
                if testesSimplesDeColisao(cobra.xbase + clbBase.x, cobra.ybase + clbBase.y, w1, h1, blTmp.x, blTmp.y, w2, h2) then
                    tocarEfeito(cobra.som)
                    deltapontos = deltapontos + 1
                    table.insert(
                        explosao.lista,
                        {x = cobra.xbase + clbBase.x - 80, y = cobra.ybase + clbBase.y - 80, tempo = explosao.tempoExplosao, indice = 1}
                    )
                    table.insert(removerBala, j)
                    clbBase.viva = false
                    break
                end
            end

            if testesSimplesDeColisao(cobra.xbase + clbBase.x, cobra.ybase + clbBase.y, w1, h1, jogador.x, jogador.y, w3, h3) then
                tocarEfeito(jogador.som)
                tocarEfeito(cobra.som)
                table.insert(removerCobra, i)
                table.insert(
                    explosao.lista,
                    {x = cobra.xbase + clbBase.x - 80, y = cobra.ybase + clbBase.y - 80, tempo = explosao.tempoExplosao, indice = 1}
                )
                table.insert(explosao.lista, {x = jogador.x - 80, y = jogador.y - 80, tempo = explosao.tempoExplosao, indice = 1})
                jogador.vivo = false
            end
        end
    end

    local n = #removerCobra
    for k = n, 1, -1 do
        table.remove(cobra.lista, removerCobra[k])
    end
    local m = #removerBala
    for l = m, 1, -1 do
        table.remove(balas.lista, removerBala[l])
    end

    return deltapontos
end

function game.colisaobalainimigo4jogador(...)
    local dt, balas, prato, jogador, explosao = ...
    local deltapontos = 0
    local tolerancia = 1
    local w1 = prato.img:getWidth()
    local h1 = prato.img:getHeight()
    local w2 = balas.img:getWidth()
    local h2 = balas.img:getHeight()
    local w3 = jogador.img:getWidth() * tolerancia
    local h3 = jogador.img:getHeight() * tolerancia

    local removerBala, removerPrato = {}, {}
    for i, clbBase in pairs(prato.lista) do
        if clbBase.viva then
            for j, blTmp in pairs(balas.lista) do
                if testesSimplesDeColisao(prato.xbase + clbBase.x, prato.ybase + clbBase.y, w1, h1, blTmp.x, blTmp.y, w2, h2) then
                    tocarEfeito(prato.som)
                    deltapontos = deltapontos + 1
                    table.insert(
                        explosao.lista,
                        {x = prato.xbase + clbBase.x - 80, y = prato.ybase + clbBase.y - 80, tempo = explosao.tempoExplosao, indice = 1}
                    )
                    table.insert(removerBala, j)
                    clbBase.viva = false
                    break
                end
            end

            if testesSimplesDeColisao(prato.xbase + clbBase.x, prato.ybase + clbBase.y, w1, h1, jogador.x, jogador.y, w3, h3) then
                tocarEfeito(jogador.som)
                tocarEfeito(prato.som)
                table.insert(removerPrato, i)
                table.insert(
                    explosao.lista,
                    {x = prato.xbase + clbBase.x - 80, y = prato.ybase + clbBase.y - 80, tempo = explosao.tempoExplosao, indice = 1}
                )
                table.insert(explosao.lista, {x = jogador.x - 80, y = jogador.y - 80, tempo = explosao.tempoExplosao, indice = 1})
                jogador.vivo = false
            end
        end
    end

    local n = #removerPrato
    for k = n, 1, -1 do
        table.remove(prato.lista, removerPrato[k])
    end
    local m = #removerBala
    for l = m, 1, -1 do
        table.remove(balas.lista, removerBala[l])
    end

    return deltapontos
end

-- ============================================================
-- Reinicializacao de entidades entre fases
-- ============================================================

function game.reinicializa1(...)
    local balas, inimigo, boss, jogador = ...
    balas.lista = {}
    balas.tempoRecarga = 0.2
    balas.tempoAposUltimoTiro = balas.tempoRecarga
    inimigo.lista = {}
    inimigo.tempoCriacao = 1
    inimigo.tempoAposCriarUltimoInimigo = inimigo.tempoCriacao
    boss.y = -700
    boss.iniciado = false
    boss.retirado = false
    boss.ativo = false
    boss.retirada = false
    jogador.vivo = false
end

function game.reinicializa2(...)
    local phase = ...
    phase.intervaloMaximo = 15
    phase.tempoAposUltimoTiro = phase.intervaloMaximo
    phase.y = 1000
end

function game.reinicializa3(...)
    local poc = ...
    poc.ybase = -1000
end

-- ============================================================
-- Render compartilhado (cenario + foreground)
-- ============================================================

function game.desenharCenario(...)
    local base, limite = ...
    love.graphics.setBackgroundColor(0, 0.1, 0.3, 0.1)

    game.shaderOn(base, limite)

    love.graphics.draw(game.solo.img, 0, game.solo.y1)
    love.graphics.draw(game.solo.img, 0, game.solo.y2)

    love.graphics.draw(game.nuvem.img, 0, game.nuvem.y1)
    love.graphics.draw(game.nuvem.img, 0, game.nuvem.y2)
    love.graphics.draw(game.nuvem.img, 0, game.nuvem.y1 + 300)
    love.graphics.draw(game.nuvem.img, 0, game.nuvem.y2 + 300)
end

function game.desenharParticulas()
    love.graphics.setColor(1, 1, 1, 1)
    game.iluminacao = 0
    for i, expTmp in pairs(game.explosao.lista) do
        love.graphics.draw(game.explosao.imgs[expTmp.indice], expTmp.x, expTmp.y)
        game.iluminacao = game.iluminacao + 100
    end

    game.shadeOff()

    for i, blTmp in pairs(game.balas.lista) do
        love.graphics.draw(game.balas.img, blTmp.x, blTmp.y)
    end

    if game.jogador.vivo then
        love.graphics.draw(game.jogador.img, game.jogador.x, game.jogador.y)
    end

    if game.boss.ativo then
        love.graphics.draw(game.boss.img, game.boss.x + game.boss.hw, game.boss.y + game.boss.hh, game.angular, 1, 1, game.boss.hw, game.boss.hh)
    end
end

function game.shaderOn(...)
    local base, limite = ...
    game.myshader:send("base", base)
    love.graphics.setShader(game.myshader)
    if game.iluminacao > limite then
        game.iluminacao = limite
    end
end

function game.shadeOff()
    love.graphics.setShader()
end

return game
