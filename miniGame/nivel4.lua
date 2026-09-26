-- nivel4.lua
-- Adiciona o "prato" (onda senoidal). Boss com mais pontos para ativar/retirar.
local nivel4 = {}
local game = require("game")

local prato = {img = nil, lista = {}, xbase = 240, ybase = -1000}
for i = 1, 10 do
    table.insert(prato.lista, {x = 0, y = 0, viva = true})
end
local phase = {img = nil, som = nil, x = 300, y = 8000, intervaloMaximo = 15, tempoAposUltimoTiro = 15}

function nivel4.inicia(recursos)
    game.configurar(recursos)
    game.boss = {
        x = -60,
        y = -600,
        danos = 0,
        limitedanos = 100,
        iniciado = false,
        retirado = false,
        ativo = false,
        retirada = false,
        pontosativo = 900,
        pontosretirada = 100
    }
    game.boss.img = recursos.imgs.boss1
    game.boss.hw = game.boss.img:getWidth() / 2
    game.boss.hh = game.boss.img:getWidth() / 2
    game.boss.som = recursos.sons.musica2
    game.boss.som:setVolume(0.3)
    game.boss.som:setLooping(true)
    prato.img = recursos.imgs.prato
    prato.som = recursos.sons.inimigo
    phase.img = recursos.imgs.phase
    phase.som = recursos.sons.phase
    tocarMusica(game.musica.som)
end

function nivel4.fim()
    game.reinicializa1(game.balas, game.inimigo, game.boss, game.jogador)
    game.reinicializa2(phase)
    game.reinicializa3(prato)
    -- dificulta o boss na re-inicializacao
    game.boss.pontosativo = game.boss.pontosativo + 1000
end

function nivel4.atualiza(dt)
    local deltaTmp1 = 5 * dt
    local deltaTmp2 = 15 * dt
    local deltaTmp3 = 250 * dt
    local deltaTmp4 = 1 * dt
    local deltaTmp5 = 350 * dt
    local deltaTmp6 = 200 * dt
    local deltaTmp7 = 30 * dt

    game.movejogador(dt, game.jogador)
    game.dispara(dt, game.jogador, game.balas, deltaTmp3, deltaTmp4)
    game.atualizaexplosoes(dt, game.explosao, deltaTmp1, deltaTmp2)
    -- move nuvens e solo
    game.movenuvenssolo(dt, game.nuvem, game.solo, deltaTmp3, deltaTmp7)
    -- atualiza posicao inimigo
    game.atualizainimigos1(dt, game.pontos, game.inimigo, deltaTmp6, deltaTmp4)
    game.atualizainimigos2(dt, phase, deltaTmp4, deltaTmp5)
    game.atualizainimigos4(dt, game.angular, game.pontos, prato, deltaTmp6)
    game.atualizaboss1(dt, game.pontos, game.boss, 20, deltaTmp6)

    -- se o jogador morreu, nao atualiza o resto
    if not game.jogador.vivo then
        return game.pontos, false
    end

    game.angular = game.angular + dt
    if game.angular > 3.14 then
        game.angular = -3.14
    end

    -- atualiza dificuldade
    game.atualizaDificuldade(game.pontos, phase)

    -- testa colisoes
    game.pontos = game.pontos + game.colisaobalainimigojogador(dt, game.balas, game.inimigo, game.jogador, game.explosao, game.pontos)

    game.colisaoinimigo2jogador(dt, phase, game.jogador, game.explosao)

    game.pontos = game.pontos + game.colisaobalainimigo4jogador(dt, game.balas, prato, game.jogador, game.explosao)

    return game.pontos, game.jogador.vivo, not game.boss.retirado
end

function nivel4.desenha()
    game.desenharCenario(700, 600)

    -- phase, inimigos e prato (desenhados sob a iluminacao do shader)
    love.graphics.draw(phase.img, phase.x, phase.y)
    for i, iniTmp in pairs(game.inimigo.lista) do
        love.graphics.draw(
            game.inimigo.img,
            iniTmp.x + game.inimigo.hw,
            iniTmp.y + game.inimigo.hh,
            iniTmp.s * game.angular,
            1,
            1,
            game.inimigo.hw,
            game.inimigo.hh
        )
    end
    for i, cblTmp in pairs(prato.lista) do
        if cblTmp.viva then
            love.graphics.draw(prato.img, prato.xbase + cblTmp.x, prato.ybase + cblTmp.y)
        end
    end

    game.desenharParticulas()
end

return nivel4
