require "utils"

-- estados
pontos  = 0
record = 0
continua = true

nivel = require "nivel1"

-- Loading
function love.load(arg)
	local file = io.open("data", "r")
	if file == nil then
		record = 0
	else
		record = tonumber(file:read())
		file:close()
	end

	nivel.inicia(arg)


end


-- calcula
function love.update(dt)

	if love.keyboard.isDown('escape') then
		love.event.quit(0)
	end

	if not continua and love.keyboard.isDown('r') then
		-- remove balas e inimigos fora da area de jogo

		nivel.fim()
		nivel = require ("nivel1")
		nivel.inicia()
		continua = true

	end

	pontos, continua = nivel.atualiza(dt)
	if not continua then
		endGame()
	else
		if pontos > nivel.limite then
			nivel.fim()
			nivel = require "nivel2"
			nivel.inicia()
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
