require "utils"
require "rotinas"

-- estados
local pontos  = 0
local record = 0
local continua = true
local numeroNivel = 1
local tempoMostraImagem = 2
local imagem = nil
local posimagem = {x = 20, y = 100}

local nivel = require ("nivel" .. numeroNivel)

local recursos = {
	imgs = {
		nivel1 = love.graphics.newImage("assets/nivel1.png"),
		nivel2 = love.graphics.newImage("assets/nivel2.png"),
		nivel3 = love.graphics.newImage("assets/nivel3.png"),
		fimjogo = love.graphics.newImage("assets/gameover.png"),
		inimigo = love.graphics.newImage("assets/inimigo.png"),
		jogador = love.graphics.newImage("assets/aviao.png"),
		balas = love.graphics.newImage("assets/bala.png"),
		phase = love.graphics.newImage("assets/phaser.png"),
		nuvem = love.graphics.newImage("assets/nuvem.png"),
		solo = love.graphics.newImage("assets/solo.png"),
		cobra = love.graphics.newImage("assets/sphera.png"),
		explosao = {nil,nil,nil,nil,nil,nil,nil,nil}
	},

	sons = {
		inimigo = love.audio.newSource("assets/explosao1.ogg", "static"),
		jogador = love.audio.newSource("assets/explosao2.ogg", "static"),
		balas = love.audio.newSource("assets/tiro.ogg", "static"),
		phase = love.audio.newSource("assets/phase.ogg", "static"),
		musica1 = love.audio.newSource("assets/musica1.ogg", "static")
	}
}

for i = 1, 8 do
	recursos.imgs.explosao[i] = love.graphics.newImage("assets/exp"..i..".png")
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

	nivel.inicia(recursos)
	imagem = recursos.imgs.nivel1

end


-- calcula
function love.update(dt)
	if love.keyboard.isDown('escape') then
		love.event.quit(0)
	end

	if imagem ~= nil then
		tempoMostraImagem = tempoMostraImagem - dt;
		if tempoMostraImagem < 0 then
			imagem = nil
		end
	end

	if not continua and love.keyboard.isDown('r') then
		-- remove balas e inimigos fora da area de jogo
		nivel.fim()
		numeroNivel = 1
		nivel = require ("nivel" .. numeroNivel)
		nivel.inicia(recursos)
		tempoMostraImagem = 2
		imagem = recursos.imgs.nivel1
		continua = true

	end

	pontos, continua = nivel.atualiza(dt)
	if not continua then
		endGame()
	else
		if pontos > nivel.limite then
			local antigoNivel = numeroNivel
			numeroNivel = math.min(numeroNivel + 1, 3)
			if numeroNivel ~= antigoNivel then
				nivel.fim()
				nivel = require ("nivel" .. numeroNivel)
				nivel.inicia(recursos)
				tempoMostraImagem = 2
				if numeroNivel == 2 then
					imagem = recursos.imgs.nivel2
				end
				if numeroNivel == 3 then

					imagem = recursos.imgs.nivel3
				end
			end
			continua = true
		end
	end
	posimagem.x = 20 + 20 * math.cos(tempoMostraImagem)
	posimagem.y = 100 + 50 * math.sin(tempoMostraImagem)
end



function endGame()

	if record < pontos then
		record = pontos
	end

	-- grava o record
	file = io.open("data", "w")
	file:write(record)
	file:close()
	imagem = recursos.imgs.fimjogo
end

-- desenha
function love.draw()

	nivel.desenha()

	love.graphics.setColor(255, 255, 255)
	if record > 0 then
		love.graphics.print("record: " .. tostring(record), 0, 10)
	end
	love.graphics.print("pontos: " .. tostring(pontos), 400, 10)

	if not continua then
		love.graphics.print("Pressione 'R' para reiniciarm Esc para sair", love.graphics:getWidth()/2-140, love.graphics:getHeight()/2-10)
	end


	if imagem ~= nil then
		love.graphics.draw(imagem, posimagem.x, posimagem.y)
	end

	--love.graphics.print("FPS:"..love.timer.getFPS(), 9, 780)

	--love.graphics.print("ANG:"..angular, 9, 780)

end
