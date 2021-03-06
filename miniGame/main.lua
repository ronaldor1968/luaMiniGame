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
local primeiravez = true
local finalizado = false

local nivel = require ("nivel" .. numeroNivel)


local recursos = {
	imgs = {
		titulo = love.graphics.newImage("assets/titulo.png"),
		texto1 = love.graphics.newImage("assets/texto1.png"),
		texto2 = love.graphics.newImage("assets/texto2.png"),
		texto3 = love.graphics.newImage("assets/texto3.png"),
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
		explosao = {nil,nil,nil,nil,nil,nil,nil,nil}
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
	recursos.sons.abertura:setVolume(0.5)
  recursos.sons.abertura:setLooping(true)
	recursos.sons.abertura:play()
	--nivel.inicia(recursos)
end


-- calcula
function love.update(dt)
	if love.keyboard.isDown('escape') then
		love.event.quit(0)
	end

	if not continua and love.keyboard.isDown('r') then
		-- remove balas e inimigos fora da area de jogo
		nivel.fim()
		paratodosossons()
		numeroNivel = 1
		nivel = require ("nivel" .. numeroNivel)
		nivel.inicia(recursos)
		tempoMostraImagem = 2
		imagem = recursos.imgs.nivel1
		continua = true
		finalizado = false
	end

	if primeiravez then
		if love.keyboard.isDown('i') then
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
		tempoMostraImagem = tempoMostraImagem - dt;
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
				nivel = require ("nivel" .. numeroNivel)
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

function endGame()
	if record < pontos then
		record = pontos
	end
	paratodosossons()
	recursos.sons.abertura:play()

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

	if not primeiravez then
		nivel.desenha()
	end

	if record > 0 then
		love.graphics.print("record: " .. tostring(record), 0, 10)
	end
	love.graphics.print("pontos: " .. tostring(pontos), 400, 10)

	if primeiravez then
		love.graphics.setBackgroundColor(0.1, 0.1,  0.1, 1)
		love.graphics.draw(recursos.imgs.titulo, 30, 250)
		love.graphics.draw(recursos.imgs.texto1, -10, 650)
		love.graphics.draw(recursos.imgs.texto3, -10, 700)
		return
	end

	if not continua then
		love.graphics.draw(recursos.imgs.titulo, 30, 350)
		love.graphics.draw(recursos.imgs.texto2, -10, 650)
		love.graphics.draw(recursos.imgs.texto3, -10, 700)
	end


	if imagem ~= nil then
		love.graphics.draw(imagem, posimagem.x, posimagem.y)
	end

	for i, j in pairs(debug_rect) do
		love.graphics.rectangle("line", j.x, j.y, j.w, j.h)
		table.remove(debug_rect, i)
	end

	love.graphics.setColor(1,0,0,1)
	for i, j in pairs(debug_text) do
		love.graphics.print(j, 10, 600 + i * 10)
		table.remove(debug_text, i)
	end
	love.graphics.setColor(1,1,1,1)

	--love.graphics.print("FPS:"..love.timer.getFPS(), 9, 780)

	--love.graphics.print("ANG:"..angular, 9, 780)

end
