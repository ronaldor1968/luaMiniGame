-- nivel1.lua
-- Nível mais simples: inimigos clássicos + boss.
-- Todo o resto (movimento, tiro, explosões, nuvens, colisões, render) está em game.lua.
local nivel1 = {}
local game = require("game")

function nivel1.inicia(recursos)
    game.configurar(recursos)
    -- novo jogo: zeros pontos (os demais niveis apenas acumulam)
    game.pontos = 0
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
    game.boss.img = recursos.imgs.boss1
    game.boss.hw = game.boss.img:getWidth() / 2
    game.boss.hh = game.boss.img:getWidth() / 2
    game.boss.som = recursos.sons.musica2
    game.boss.som:setVolume(0.3)
    game.boss.som:setLooping(true)
    tocarMusica(game.musica.som)
end

function nivel1.fim()
    game.reinicializa1(game.balas, game.inimigo, game.boss, game.jogador)
end

function nivel1.atualiza(dt)
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
    if game.pontos > 10 then
        game.inimigo.tempoCriacao = 1
        if game.pontos < 50 then
            game.inimigo.tempoCriacao = 0.9
            game.balas.tempoRecarga = 0.15
        else
            game.inimigo.tempoCriacao = 0.7
            game.balas.tempoRecarga = 0.1
        end
    end

    -- testa colisoes
    game.pontos = game.pontos + game.colisaobalainimigojogador(dt, game.balas, game.inimigo, game.jogador, game.explosao, game.pontos)

    return game.pontos, game.jogador.vivo, not game.boss.retirado
end

function nivel1.desenha()
    game.desenharCenario(400, 400)

    -- desenha os inimigos (diferenca especifica do nivel)
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

    game.desenharParticulas()
end

return nivel1
