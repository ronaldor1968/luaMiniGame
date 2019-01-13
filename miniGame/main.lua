
-- estados
pontos  = 0 
record = 0
angular = 0
delta_angular = 1
iluminacao = 0

-- objetos de imagens
jogador = {x = 200, y = 710, speed = 150, vivo = true, img = nil }
balas = {img =nil, som = nil, tempoRecarga = 0.5, tempoAposUltimoTiro = 0.5, recarregado = true, lista = {}}
inimigo = {img =nil, som = nil, maximo = 2, tempoAposCriarUltimoInimigo = 1, tempoCriacao = 1, lista = {}}
phase = {img = nil, som = nil, x = 300, y = 8000, intervaloMaximo = 15, tempoAposUltimoTiro = 15}
nuvem = {img = nil, y1 = -3200, y2 = -6400}
solo = {img = nil, y1 = -3200, y2 = -6400}
explosao = {imgs={}, lista = {}, tempoExplosao = 0.5}
myshader = nil
musica = {som = nil}


function testaColisao(a, b)
	local erro = a.img:getWidth() / 4
	return testesSimplesDeColisao(a.x + erro, a.y + erro, a.img:getWidth() - 2 * erro, a.img:getHeight() - 2 * erro, b.x, b.y, b.img:getWidth(), b.img:getHeight())
end

function testesSimplesDeColisao(x1,y1,w1,h1, x2,y2,w2,h2)
  local intersecta = x1 < x2+w2 and
         x2 < x1+w1 and
         y1 < y2+h2 and
         y2 < y1+h1
  --if (intersecta) then
  --	  print(x1, y1, x1+w1, y1+h1, x2, y2, x2+w2, y2+h2)
  --end
  return intersecta
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
	inimigo.img = love.graphics.newImage("assets/inimigo.png")
	inimigo.som = love.audio.newSource("assets/explosao1.ogg", "static")
	inimigo.som:setVolume(0.5)
	jogador.img = love.graphics.newImage("assets/aviao.png")
	jogador.som = love.audio.newSource("assets/explosao2.ogg", "static")
	jogador.som:setVolume(0.8)
	balas.img = love.graphics.newImage("assets/bala.png")
	balas.som = love.audio.newSource("assets/tiro.ogg", "static")
	balas.som:setVolume(0.3)
	phase.img = love.graphics.newImage("assets/phaser.png")
	phase.som = love.audio.newSource("assets/phase.ogg", "static")
	jogador.som:setVolume(0.9)
	nuvem.img = love.graphics.newImage("assets/nuvem.png")
	solo.img = love.graphics.newImage("assets/solo.png")
	for i = 1, 8 do
		explosao.imgs[i] = love.graphics.newImage("assets/exp"..i..".png")
	end
	musica.som = love.audio.newSource("assets/musica1.ogg", "static")
	musica.som:setVolume(0.1)
	musica.som:setLooping(true)


	local pixelcode = [[

	extern int base;
	vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screenCoords){
	  float r = screenCoords.y / base;
	  vec4 nColor = vec4(r);
	  return Texel(texture, texture_coords) * nColor * color;
	}
	]]

	myshader = love.graphics.newShader(pixelcode)
	print(myshader:getWarnings())
	musica.som:play()

end


-- calcula
function love.update(dt)

	if not jogador.vivo and love.keyboard.isDown('r') then
		-- remove balas e inimigos fora da area de jogo

		jogador.x = math.random(80, love.graphics.getWidth()  - 180)
		jogador.y = 710
		jogador.vivo = true

	end

	if love.keyboard.isDown('left','a') then
		if jogador.x > 0 then -- binds us to the map
			jogador.x = jogador.x - (jogador.speed*dt)
		end
	elseif love.keyboard.isDown('right','d') then
		if jogador.x < (love.graphics.getWidth() - jogador.img:getWidth()) then
			jogador.x = jogador.x + (jogador.speed*dt)
		end
	elseif love.keyboard.isDown('up','w') then
		if jogador.y > 0 then
			jogador.y = jogador.y - (jogador.speed*dt)
		end
	elseif love.keyboard.isDown('down','s') then
		if jogador.y < 710  then
			jogador.y = jogador.y + (jogador.speed*dt)
		end
	end

	if jogador.vivo and love.keyboard.isDown('space', 'rctrl', 'lctrl') and balas.recarregado then
		-- cria balas
		newBullet = { x = jogador.x + (jogador.img:getWidth() - balas.img:getWidth())/2, y = jogador.y }
		table.insert(balas.lista, newBullet)
		balas.recarregado = false
		balas.tempoAposUltimoTiro = balas.tempoRecarga
		balas.som:stop()
		balas.som:play()
	end	

	local deltaTmp1 = 5 * dt
	local deltaTmp2 = 15 * dt
	local deltaTmp3 = 250 * dt;
	local deltaTmp4 = 1 * dt
	local deltaTmp5 = 350 * dt
	local deltaTmp6 = 200 * dt
	local deltaTmp7 = 30 * dt;

	for i, expTmp in ipairs(explosao.lista) do
		expTmp.tempo = expTmp.tempo  -  deltaTmp1
		expTmp.y = expTmp.y + deltaTmp2
		if (expTmp.tempo < 0) then
			expTmp.tempo = explosao.tempoExplosao
			if expTmp.indice < 8 then
				expTmp.indice = expTmp.indice + 1
			else
				table.remove(explosao.lista, i)
			end
		end
	end


	-- move nuvens e solo

	nuvem.y1 = nuvem.y1 + deltaTmp3
	nuvem.y2 = nuvem.y2 + deltaTmp3
	if (nuvem.y1 > 0) then
		nuvem.y1 = -6400
	end
	if (nuvem.y2 > 0) then
		nuvem.y2 = -6400
	end

	solo.y1 = solo.y1 + deltaTmp7
	solo.y2 = solo.y2 + deltaTmp7
	if (solo.y1 > 0) then
		solo.y1 = -6400
	end
	if (solo.y2 > 0) then
		solo.y2 = -6400
	end

	-- se estiver mosto, não atualiza o resto
	if not jogador.vivo then 
		return
	end
	
	angular = angular + delta_angular * dt
	if angular >  1 then
		delta_angular = -1
	elseif angular < 0.5 then
		delta_angular = 1	
	end	


	-- atualiza dificuldade


	if pontos > 10 then
		inimigo.tempoCriacao = 1
		phase.intervaloMaximo = 13
		if pontos < 200 then
			inimigo.tempoCriacao = 0.9
			phase.intervaloMaximo = 12
			balas.tempoRecarga = 0.45
		elseif pontos < 500 then
			inimigo.tempoCriacao = 0.7
			phase.intervaloMaximo = 10
			balas.tempoRecarga = 0.40
		elseif pontos < 1000 then
			inimigo.tempoCriacao = 0.5
			phase.intervaloMaximo = 7
			balas.tempoRecarga = 0.35
		elseif pontos < 3000 then
			inimigo.tempoCriacao = 0.3
			phase.intervaloMaximo = 5
			balas.tempoRecarga = 0.30
		elseif pontos < 5000 then
			inimigo.tempoCriacao = 0.2
			phase.intervaloMaximo = 4
			balas.tempoRecarga = 0.25
		else
			inimigo.tempoCriacao = 0.1
			phase.intervaloMaximo = 2
			balas.tempoRecarga = 0.2
		end
	end


	-- conta o tempo para as balas e os inimigos
	balas.tempoAposUltimoTiro = balas.tempoAposUltimoTiro - deltaTmp4
	if (balas.tempoAposUltimoTiro < 0) then
		balas.recarregado = true
	end

	phase.tempoAposUltimoTiro = phase.tempoAposUltimoTiro - deltaTmp4
	if phase.y > 800 and phase.tempoAposUltimoTiro < 0 then
		-- novo tipo de phase
		phase.y = -800
		phase.x = math.random(10, 510)
		phase.tempoAposUltimoTiro = phase.intervaloMaximo
		phase.som:stop()
		phase.som:play()
	else
		phase.y = phase.y + deltaTmp5
	end


	inimigo.tempoAposCriarUltimoInimigo = inimigo.tempoAposCriarUltimoInimigo - deltaTmp4
	if inimigo.tempoAposCriarUltimoInimigo < 0 then
		inimigo.tempoAposCriarUltimoInimigo = inimigo.tempoCriacao
		if (table.getn(inimigo.lista) < inimigo.maximo) then
			-- cria novo inimigo
			local dx = math.random(-1,1) * pontos
			if (dx > 100) then
				dx = 100
			elseif dx < -100 then
				dx = -100
			end
			table.insert(inimigo.lista, { x = math.random(10, love.graphics.getWidth()  - 80), y = -30, delta_x = dx * dt})
		end
	end


	-- atualiza posicao das balas
	for i, blTmp in ipairs(balas.lista) do
		blTmp.y = blTmp.y - deltaTmp3

		if blTmp.y < 0 then -- remove balas when they pass off the screen
			table.remove(balas.lista, i)
		end
	end

	

	-- atualiza posicao inimigo
	for i, iniTmp in ipairs(inimigo.lista) do
		iniTmp.y = iniTmp.y + deltaTmp6
		if iniTmp.x > 400 or iniTmp.x < 0 then
			iniTmp.delta_x = -iniTmp.delta_x
		end
		iniTmp.x = iniTmp.x + iniTmp.delta_x

		if iniTmp.y > 850 then -- remove inimigos quando sai da tela
			table.remove(inimigo.lista, i)
		end
	end

	-- testa cosiloes
	for i, iniTmp in ipairs(inimigo.lista) do
		for j, blTmp in ipairs(balas.lista) do
			if testesSimplesDeColisao(iniTmp.x, iniTmp.y, inimigo.img:getWidth(), inimigo.img:getHeight(), blTmp.x, blTmp.y, balas.img:getWidth(), balas.img:getHeight()) then
				inimigo.maximo = 2 + pontos / 10
				inimigo.som:stop()
				inimigo.som:play()
				pontos = pontos + 1
				table.insert(explosao.lista, { x = iniTmp.x - 80, y = iniTmp.y - 80, tempo = explosao.tempoExplosao, indice = 1})
				table.remove(balas.lista, j)
				table.remove(inimigo.lista, i)
			end
		end

		if jogador.vivo and
		testesSimplesDeColisao(iniTmp.x, iniTmp.y, inimigo.img:getWidth(), inimigo.img:getHeight(), jogador.x, jogador.y, jogador.img:getWidth(), jogador.img:getHeight())
		then
			jogador.som:play()
			inimigo.som:stop()
			inimigo.som:play()
			table.remove(inimigo.lista, i)
			table.insert(explosao.lista, { x = iniTmp.x - 80, y = iniTmp.y - 80, tempo = explosao.tempoExplosao, indice = 1})
			table.insert(explosao.lista, { x = jogador.x - 80, y = jogador.y - 80, tempo = explosao.tempoExplosao, indice = 1})
			endGame()
		end
	end

	if testaColisao(phase, jogador)
	then
		jogador.som:play()
		table.insert(explosao.lista, { x = jogador.x - 80 , y = jogador.y - 80, tempo = explosao.tempoExplosao, indice = 1})
		endGame()
	end

end

function endGame()
	jogador.vivo = false	
	if record < pontos then
		record = pontos
	end

	file = io.open("data", "w")
	file:write(record)
	file:close()

	balas.lista = {}
	balas.tempoRecarga = 0.5
	balas.tempoAposUltimoTiro = balas.tempoRecarga
	inimigo.lista = {}
	inimigo.tempoCriacao = 1
	inimigo.tempoAposCriarUltimoInimigo = inimigo.tempoCriacao
	phase.intervaloMaximo = 15
	phase.tempoAposUltimoTiro = phase.intervaloMaximo
	phase.y = 1000
	pontos = 0
end

function shaderOn()
	love.graphics.setShader(myshader)
	if iluminacao > 600 then
		iluminacao = 600
	end	
	myshader:send("base", 800 - iluminacao)
end

function shadeOff()
	love.graphics.setShader()
end

-- desenha
function love.draw(dt)

	
	shaderOn()
	
	love.graphics.setBackgroundColor( 0, 0.1, 0.3, 0.1 )
	love.graphics.draw(solo.img, 0, solo.y1)
	love.graphics.draw(solo.img, 0, solo.y2)

	--love.graphics.draw(phase.img, phase.x, phase.y, math.rad(phase.angulo), 1, 1, 100, 100)



	love.graphics.draw(phase.img, phase.x, phase.y)

	love.graphics.draw(nuvem.img, 0, nuvem.y1)
	love.graphics.draw(nuvem.img, 0, nuvem.y2)
	love.graphics.draw(nuvem.img, 0, nuvem.y1 + 300)
	love.graphics.draw(nuvem.img, 0, nuvem.y2 + 300)

	

	love.graphics.setColor(angular, angular, angular, 1)
	
	for i, iniTmp in ipairs(inimigo.lista) do
		love.graphics.draw(inimigo.img, iniTmp.x, iniTmp.y)
	end

	iluminacao = 0
	for i, expTmp in ipairs(explosao.lista) do
		love.graphics.draw(explosao.imgs[expTmp.indice], expTmp.x, expTmp.y);
		iluminacao = iluminacao + 200
	end

	shadeOff()
	
	love.graphics.setColor(1, 1, 1, 1)

	for i, blTmp in ipairs(balas.lista) do
		love.graphics.draw(balas.img, blTmp.x, blTmp.y)
	end

	love.graphics.setColor(255, 255, 255)
	if record > 0 then
		love.graphics.print("record: " .. tostring(record), 0, 10)
	end
	love.graphics.print("pontos: " .. tostring(pontos), 400, 10)

	if jogador.vivo then
		love.graphics.draw(jogador.img, jogador.x, jogador.y)
	else
		love.graphics.print("Pressione 'R' para reiniciarm Esc para sair", love.graphics:getWidth()/2-140, love.graphics:getHeight()/2-10)
		
	end

	--love.graphics.print("FPS:"..love.timer.getFPS(), 9, 780)
	

	--love.graphics.print("ANG:"..angular, 9, 780)

	
	

end
