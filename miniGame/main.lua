require "utils"

-- estados
pontos  = 0
record = 0
continua = true
numeroNivel = 1

nivel = require "nivel1"

local recursos = {
	imgs = {
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


end


-- calcula
function love.update(dt)
	local novoNivel = love.thread.getChannel('nivel'):pop()
	nivel = novoNivel or nivel
	if love.keyboard.isDown('escape') then
		love.event.quit(0)
	end

	if not continua and love.keyboard.isDown('r') then
		-- remove balas e inimigos fora da area de jogo

		nivel.fim()
		nivel = require ("nivel1")
		nivel.inicia(recursos)
		continua = true

	end

	pontos, continua = nivel.atualiza(dt)
	if not continua then
		endGame()
	else
		if pontos > nivel.limite then
			nivel.fim()
			local antigoNivel = numeroNivel
			numeroNivel = math.min(numeroNivel + 1, 3)
			if numeroNivel ~= antigoNivel then
				nivel = require ("nivel" .. numeroNivel)
				nivel.inicia(recursos)
			end
			continua = true
		end
	end
end



function endGame()

	if record < pontos then
		record = pontos
	end

	-- grava o record
	file = io.open("data", "w")
	file:write(record)
	file:close()

end

-- desenha
function love.draw(dt)

	nivel.desenha(dt)

	love.graphics.setColor(255, 255, 255)
	if record > 0 then
		love.graphics.print("record: " .. tostring(record), 0, 10)
	end
	love.graphics.print("pontos: " .. tostring(pontos), 400, 10)

	if not continua then
		love.graphics.print("Pressione 'R' para reiniciarm Esc para sair", love.graphics:getWidth()/2-140, love.graphics:getHeight()/2-10)
	end

	--love.graphics.print("FPS:"..love.timer.getFPS(), 9, 780)

	--love.graphics.print("ANG:"..angular, 9, 780)

end
