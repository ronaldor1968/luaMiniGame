-- nivel3.lua
-- Adiciona a "cobra" (onda senoidal). Adicionalmente ao phase.
local nivel3 = {}
local game = require("game")

local phase = {img = nil, som = nil, x = 300, y = 8000, intervaloMaximo = 15, tempoAposUltimoTiro = 15}
local cobra = {img = nil, lista = {}, xbase = 240, ybase = -1000}
for i = 1, 10 do
    table.insert(cobra.lista, {x = 0, y = 0, viva = true})
end
local pontos = 0

function nivel3.inicia(recursos)
    pontos = 0
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
        pontosativo = 450,
        pontosretirada = 40
    }
    game.boss.img = recursos.imgs.boss1
    game.boss.hw = game.boss.img:getWidth() / 2
    game.boss.hh = game.boss.img:getWidth() / 2
    game.boss.som = recursos.sons.musica2
    game.boss.som:setVolume(0.3)
    game.boss.som:setLooping(true)
    phase.img = recursos.imgs.phase
    phase.som = recursos.sons.phase
    cobra.img = recursos.imgs.cobra
    cobra.som = recursos.sons.inimigo
    game.musica.som:play()
end

function nivel3.fim()
    game.reinicializa1(game.balas, game.inimigo, game.boss, game.jogador)
    game.reinicializa2(phase)
    game.reinicializa3(cobra)
end

function nivel3.atualiza(dt)
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
    game.atualizainimigos1(dt, pontos, game.inimigo, deltaTmp6, deltaTmp4)
    game.atualizainimigos2(dt, phase, deltaTmp4, deltaTmp5)
    game.atualizainimigos3(dt, game.angular, pontos, cobra, deltaTmp6)
    game.atualizaboss1(dt, pontos, game.boss, 20, deltaTmp6)

    -- se o jogador morreu, nao atualiza o resto
    if not game.jogador.vivo then
        return pontos, false
    end

    game.angular = game.angular + dt
    if game.angular > 3.14 then
        game.angular = -3.14
    end

    -- atualiza dificuldade
    game.atualizaDificuldade(pontos, phase)

    -- testa colisoes
    pontos = pontos + game.colisaobalainimigojogador(dt, game.balas, game.inimigo, game.jogador, game.explosao, pontos)

    game.colisaoinimigo2jogador(dt, phase, game.jogador, game.explosao)

    pontos = pontos + game.colisaobalainimigo3jogador(dt, game.balas, cobra, game.jogador, game.explosao)

    return pontos, game.jogador.vivo, not game.boss.retirado
end

function nivel3.desenha()
    game.desenharCenario(700, 600)

    -- phase, inimigos e cobra (desenhados sob a iluminacao do shader)
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
    for i, cblTmp in pairs(cobra.lista) do
        if cblTmp.viva then
            love.graphics.draw(cobra.img, cobra.xbase + cblTmp.x, cobra.ybase + cblTmp.y)
        end
    end

    game.desenharParticulas()
end

return nivel3
