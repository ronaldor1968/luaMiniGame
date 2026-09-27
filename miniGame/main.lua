require "utils"
local game = require("game")

-- estados
local pontos = 0
local record = 0
local continua = true
local numeroNivel = 1
local tempoMostraImagem = 2
local imagem = nil
local posimagem = {x = 20, y = 100}
local primeiravez = true
local finalizado = false
local ecra = "menu" -- "menu" | "config"
local cAnterior = false  -- detecao de pressao da tecla c
local sAnterior = false  -- detecao de pressao da tecla s
local mAnterior = false  -- detecao de pressao da tecla m
local configTempo = 0    -- cooldown restante apos um swap (s/m)
local CONFIG_ESPERA = 0.4 -- delay minimo entre swaps no ecran de configuracoes

local nivel = require("nivel" .. numeroNivel)

local recursos = {
	imgs = {
		titulo = love.graphics.newImage("assets/titulo.png"),
		texto1 = love.graphics.newImage("assets/texto1.png"),
		texto2 = love.graphics.newImage("assets/texto2.png"),
		texto3 = love.graphics.newImage("assets/texto3.png"),
		texto4 = love.graphics.newImage("assets/texto4.png"),
		texto5 = love.graphics.newImage("assets/texto5.png"),
		texto6 = love.graphics.newImage("assets/texto6.png"),
		texto7 = love.graphics.newImage("assets/texto7.png"),
		texto8 = love.graphics.newImage("assets/texto8.png"),
		texto9 = love.graphics.newImage("assets/texto9.png"),
		texto10 = love.graphics.newImage("assets/texto10.png"),
		texto11 = love.graphics.newImage("assets/texto11.png"),
		nivel1 = love.graphics.newImage("assets/nivel1.png"),
		nivel2 = love.graphics.newImage("assets/nivel2.png"),
		nivel3 = love.graphics.newImage("assets/nivel3.png"),
		nivel4 = love.graphics.newImage("assets/nivel4.png"),
		fimjogo = love.graphics.newImage("assets/gameover.png"),
		inimigo = love.graphics.newImage("assets/inimigo.png"),
		jogador = love.graphics.newImage("assets/aviao.png"),
		balas = love.graphics.newImage("assets/bala.png"),
		phase = love.graphics.newImage("assets/phaser.png"),
		nuvem = love.graphics.newImage("assets/nuvem.png"),
		solo = love.graphics.newImage("assets/solo.png"),
		boss1 = love.graphics.newImage("assets/boss1.png"),
		cobra = love.graphics.newImage("assets/sphera.png"),
		prato = love.graphics.newImage("assets/prato.png"),
		explosao = {nil, nil, nil, nil, nil, nil, nil, nil}
	},
	sons = {
		inimigo = love.audio.newSource("assets/explosao1.ogg", "static"),
		jogador = love.audio.newSource("assets/explosao2.ogg", "static"),
		balas = love.audio.newSource("assets/tiro.ogg", "static"),
		phase = love.audio.newSource("assets/phase.ogg", "static"),
		abertura = love.audio.newSource("assets/abertura.ogg", "stream"),
		musica1 = love.audio.newSource("assets/musica1.ogg", "stream"),
		musica2 = love.audio.newSource("assets/musica2.ogg", "stream")
	}
}

for i = 1, 8 do
	recursos.imgs.explosao[i] = love.graphics.newImage("assets/exp" .. i .. ".png")
end

-- Loading
function love.load(arg)
	local file = io.open("data", "r")
	if file == nil then
		record = 0
	else
		record = tonumber(file:read())
		file:close()
	end
	recursos.sons.abertura:setVolume(0.5)
	recursos.sons.abertura:setLooping(true)
	tocarMusica(recursos.sons.abertura)
	-- fonte para os valores dinamicos (pontos/record) que nao podem ser imagens
	recursos.fonteHUD = love.graphics.newFont("assets/fonte.ttf", 26)
	--nivel.inicia(recursos)
end

-- calcula
function love.update(dt)
	if love.keyboard.isDown("escape") then
		love.event.quit(0)
	end

	-- pressao da tecla c apenas na transicao solta -> premida
	local cPressionada = love.keyboard.isDown("c") and not cAnterior
	cAnterior = love.keyboard.isDown("c")

	if ecra == "config" then
		atualizaConfig(dt)
		return
	end

	if not continua and love.keyboard.isDown("r") then
		-- remove balas e inimigos fora da area de jogo
		nivel.fim()
		paratodosossons()
		numeroNivel = 1
		nivel = require("nivel" .. numeroNivel)
		nivel.inicia(recursos)
		tempoMostraImagem = 2
		imagem = recursos.imgs.nivel1
		continua = true
		finalizado = false
	end

	-- abre o ecran de configuracoes (no menu ou no game over)
	if (primeiravez or not continua) and cPressionada then
		ecra = "config"
		configTempo = 0
		sAnterior = love.keyboard.isDown("s")
		mAnterior = love.keyboard.isDown("m")
		return
	end

	if primeiravez then
		if love.keyboard.isDown("i") then
			paratodosossons()
			nivel.inicia(recursos)
			imagem = recursos.imgs.nivel1
			tempoMostraImagem = 2
			primeiravez = false
			continua = true
			finalizado = false
		end
		return
	end

	if imagem ~= nil and continua then
		tempoMostraImagem = tempoMostraImagem - dt
		if tempoMostraImagem < 0 then
			imagem = nil
		end
	end

	pontos, continua, fimnivel = nivel.atualiza(dt)
	if not continua then
		if not finalizado then
			endGame()
		end
	else
		if not fimnivel then
			local antigoNivel = numeroNivel
			numeroNivel = math.min(numeroNivel + 1, 4)
			if numeroNivel ~= antigoNivel then
				nivel.fim()
				paratodosossons()
				nivel = require("nivel" .. numeroNivel)
				nivel.inicia(recursos)
				tempoMostraImagem = 2
				if numeroNivel == 2 then
					imagem = recursos.imgs.nivel2
				end
				if numeroNivel == 3 then
					imagem = recursos.imgs.nivel3
				end
				if numeroNivel == 4 then
					imagem = recursos.imgs.nivel4
				end
			end
			continua = true
		end
	end
	posimagem.x = 20 + 20 * math.cos(tempoMostraImagem)
	posimagem.y = 100 + 50 * math.sin(tempoMostraImagem)
end

function paratodosossons()
	for i, som in pairs(recursos.sons) do
		if som ~= recursos.sons.inimigo and som ~= recursos.sons.jogador then
			som:stop()
		end
	end
end

-- ecran de configuracoes
local sonsEfeitos = {recursos.sons.inimigo, recursos.sons.jogador, recursos.sons.balas, recursos.sons.phase}
local sonsMusicas = {recursos.sons.abertura, recursos.sons.musica1, recursos.sons.musica2}

-- s e m sao teclas de swap: so reagem na transicao solta -> premida e com
-- um pequeno delay (cooldown) para o loop nao efetuar multiplas trocas de
-- estado numa fracao de segundos quando a tecla fica pressionada
function atualizaConfig(dt)
	configTempo = configTempo - dt

	local sAgora = love.keyboard.isDown("s")
	local mAgora = love.keyboard.isDown("m")

	if sAgora and not sAnterior and configTempo <= 0 then
		config_jogo.som = not config_jogo.som
		if not config_jogo.som then
			aplicarConfigSom()
		end
		configTempo = CONFIG_ESPERA
	end
	if mAgora and not mAnterior and configTempo <= 0 then
		config_jogo.musica = not config_jogo.musica
		aplicarConfigMusica()
		configTempo = CONFIG_ESPERA
	end

	sAnterior = sAgora
	mAnterior = mAgora

	if love.keyboard.isDown("v") then
		ecra = "menu"
		aplicarConfigMusica()
	end
end

function aplicarConfigSom()
	for _, som in ipairs(sonsEfeitos) do
		som:stop()
	end
end

function aplicarConfigMusica()
	if not config_jogo.musica then
		for _, som in ipairs(sonsMusicas) do
			som:stop()
		end
		return
	end
	-- retoma a musica adequada ao ecran atual
	if primeiravez or not continua then
		recursos.sons.abertura:play()
	elseif game.boss and game.boss.ativo and game.boss.som then
		game.boss.som:play()
	elseif game.musica and game.musica.som then
		game.musica.som:play()
	end
end

-- ---------------------------------------------------------------------------
-- efeito neon para os textos: os PNG sao texto branco e o shader aplica
-- glow grande, sombra, pulsacao, tremulacao de letreiro e brilho a correr.
-- Ajusta tudo aqui:
--   cor        cor do neon (r, g, b) 0..1
--   intensidade forca do halo
--   raio       raio do halo em pixels
--   velocidade velocidade da pulsacao
--   tremulacao 0..1 quanta "falha" de letreiro (corticulos ocasionais)
local NEON = {
	menu   = {cor = {1.00, 0.16, 0.32}, intensidade = 2.2, raio = 6.0, velocidade = 2.0, tremulacao = 0.6}, -- vermelho
	titulo = {cor = {0.30, 1.00, 0.12}, intensidade = 2.4, raio = 7.0, velocidade = 1.6, tremulacao = 0.9}, -- verde
	linha  = {cor = {1.00, 0.93, 0.80}, intensidade = 1.4, raio = 4.5, velocidade = 2.4, tremulacao = 0.3}  -- branco quente
}

function desenhaNeon(img, x, y, perfil)
	-- o menu aparece antes do nivel iniciar; cria o shader por lazy init
	game.shaderNeonOn()
	--game.shaderFireOn(img)
	love.graphics.draw(img, x, y)
	game.shadeOff()
end

-- ecran de configuracoes (todas as imagens em assets/texto5..11.png)
function desenhaConfig()
	love.graphics.setBackgroundColor(0.1, 0.1, 0.1, 1)
	desenhaNeon(recursos.imgs.texto5, 0, 130, NEON.titulo) -- CONFIGURACOES
	desenhaNeon(config_jogo.som and recursos.imgs.texto6 or recursos.imgs.texto7, 0, 320, NEON.linha)
	desenhaNeon(config_jogo.musica and recursos.imgs.texto8 or recursos.imgs.texto9, 0, 400, NEON.linha)
	desenhaNeon(recursos.imgs.texto10, 0, 560, NEON.linha) -- V - Voltar ao menu anterior
	desenhaNeon(recursos.imgs.texto11, 0, 640, NEON.linha) -- ESC - Sair
	
end

function endGame()
	if record < pontos then
		record = pontos
	end
	paratodosossons()
	tocarMusica(recursos.sons.abertura)

	-- grava o record
	file = io.open("data", "w")
	file:write(record)
	file:close()
	tempoMostraImagem = 2
	imagem = recursos.imgs.fimjogo
	finalizado = true
end

-- desenha
function love.draw()
	if ecra == "config" then
		desenhaConfig()
		return
	end

	if not primeiravez then
		nivel.desenha()
	end

	love.graphics.setFont(recursos.fonteHUD)
	if record > 0 then
		love.graphics.print("record: " .. tostring(record), 0, 8)
	end
	-- alinhamento a direita sem printf (incompativel com algumas versoes do love)
	local textoPontos = "pontos: " .. tostring(pontos)
	love.graphics.print(textoPontos, 474 - love.graphics.getFont():getWidth(textoPontos), 8)
	love.graphics.setFont(love.graphics.getFont())

	if primeiravez then
		love.graphics.setBackgroundColor(0.1, 0.1, 0.1, 1)
		love.graphics.draw(recursos.imgs.titulo, 30, 250)
		desenhaNeon(recursos.imgs.texto1, -10, 586, NEON.menu)
		desenhaNeon(recursos.imgs.texto3, -10, 654, NEON.menu)
		desenhaNeon(recursos.imgs.texto4, -10, 722, NEON.menu)
		return
	end

	if not continua then
		love.graphics.draw(recursos.imgs.titulo, 30, 350)
		desenhaNeon(recursos.imgs.texto2, -10, 586, NEON.menu)
		desenhaNeon(recursos.imgs.texto3, -10, 654, NEON.menu)
		desenhaNeon(recursos.imgs.texto4, -10, 722, NEON.menu)
	end

	if imagem ~= nil then
		love.graphics.draw(imagem, posimagem.x, posimagem.y)
	end

	for i, j in pairs(debug_rect) do
		love.graphics.rectangle("line", j.x, j.y, j.w, j.h)
		table.remove(debug_rect, i)
	end

	love.graphics.setColor(1, 0, 0, 1)
	for i, j in pairs(debug_text) do
		love.graphics.print(j, 10, 600 + i * 10)
		table.remove(debug_text, i)
	end
	love.graphics.setColor(1, 1, 1, 1)

	--love.graphics.print("FPS:"..love.timer.getFPS(), 9, 780)

	--love.graphics.print("ANG:"..angular, 9, 780)
end
