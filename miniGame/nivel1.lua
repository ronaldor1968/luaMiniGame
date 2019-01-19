local nivel1 = {limite = 100}

angular = 0
iluminacao = 0

-- objetos de imagens
jogador = {x = 200, y = 710, speed = 150, vivo = true, img = nil }
balas = {img =nil, som = nil, tempoRecarga = 0.5, tempoAposUltimoTiro = 0.5, recarregado = true, lista = {}}
inimigo = {img =nil, som = nil, maximo = 2, tempoAposCriarUltimoInimigo = 1, tempoCriacao = 1, lista = {}}
nuvem = {img = nil, y1 = -3200, y2 = -6400}
solo = {img = nil, y1 = -3200, y2 = -6400}
explosao = {imgs={}, lista = {}, tempoExplosao = 0.5}
myshader = nil
musica = {som = nil}

function nivel1.inicia(recursos)
  inimigo.img = recursos.imgs.inimigo
	inimigo.som = recursos.sons.inimigo
	inimigo.som:setVolume(0.5)
	jogador.img = recursos.imgs.jogador
	jogador.som = recursos.sons.jogador
	jogador.som:setVolume(0.8)
	balas.img = recursos.imgs.balas
	balas.som = recursos.sons.balas
	balas.som:setVolume(0.3)
	jogador.som:setVolume(0.9)
	nuvem.img = recursos.imgs.nuvem
	solo.img = recursos.imgs.solo
	for i = 1, 8 do
		explosao.imgs[i] = recursos.imgs.explosao[i]
	end
	musica.som = recursos.sons.musica1
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
  jogador.vivo = true
  pontos = 0
end

function nivel1.fim()
  -- reinicia os valores
  balas.lista = {}
  balas.tempoRecarga = 0.5
  balas.tempoAposUltimoTiro = balas.tempoRecarga
  inimigo.lista = {}
  inimigo.tempoCriacao = 1
  inimigo.tempoAposCriarUltimoInimigo = inimigo.tempoCriacao
  jogador.vivo = false
  musica.som:stop()
end

function nivel1.atualiza(dt)


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

	-- se estiver mosto, não atualiza o resto
	if not jogador.vivo then
		return pontos, false
	end

	angular = angular + dt
	if angular >  3.14 then
		angular = -3.14
	end


	-- atualiza dificuldade


	if pontos > 10 then
		inimigo.tempoCriacao = 1
		if pontos < 50 then
			inimigo.tempoCriacao = 0.9
			balas.tempoRecarga = 0.45
		else
			inimigo.tempoCriacao = 0.7
			balas.tempoRecarga = 0.40
    end
	end

	-- conta o tempo para as balas e os inimigos
	balas.tempoAposUltimoTiro = balas.tempoAposUltimoTiro - deltaTmp4
	if (balas.tempoAposUltimoTiro < 0) then
		balas.recarregado = true
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


		if testesSimplesDeColisao(iniTmp.x, iniTmp.y, inimigo.img:getWidth(), inimigo.img:getHeight(), jogador.x, jogador.y, jogador.img:getWidth(), jogador.img:getHeight())
		then
			jogador.som:play()
			inimigo.som:stop()
			inimigo.som:play()
			table.remove(inimigo.lista, i)
			table.insert(explosao.lista, { x = iniTmp.x - 80, y = iniTmp.y - 80, tempo = explosao.tempoExplosao, indice = 1})
			table.insert(explosao.lista, { x = jogador.x - 80, y = jogador.y - 80, tempo = explosao.tempoExplosao, indice = 1})
      jogador.vivo = false
		end

	end

  return pontos, jogador.vivo
end

function shaderOn()
	myshader:send("base", 400)
	love.graphics.setShader(myshader)
	if iluminacao > 400 then
		iluminacao = 400
	end
end

function shadeOff()
	love.graphics.setShader()
end

function nivel1.desenha(dt)
  love.graphics.setBackgroundColor( 0, 0.1, 0.3, 0.1 )

  shaderOn()

	love.graphics.draw(solo.img, 0, solo.y1)
	love.graphics.draw(solo.img, 0, solo.y2)

	love.graphics.draw(nuvem.img, 0, nuvem.y1)
	love.graphics.draw(nuvem.img, 0, nuvem.y2)
	love.graphics.draw(nuvem.img, 0, nuvem.y1 + 300)
	love.graphics.draw(nuvem.img, 0, nuvem.y2 + 300)


	love.graphics.setColor(1 - math.cos(angular)/2, 1 - math.sin(angular)/2, angular, 1)

	for i, iniTmp in ipairs(inimigo.lista) do
		love.graphics.draw(inimigo.img, iniTmp.x, iniTmp.y)
	end

	love.graphics.setColor(1, 1, 1, 1)
	iluminacao = 0
	for i, expTmp in ipairs(explosao.lista) do
		love.graphics.draw(explosao.imgs[expTmp.indice], expTmp.x, expTmp.y);
		iluminacao = iluminacao + 100
	end

  shadeOff()

	for i, blTmp in ipairs(balas.lista) do
		love.graphics.draw(balas.img, blTmp.x, blTmp.y)
	end

  if jogador.vivo then
		love.graphics.draw(jogador.img, jogador.x, jogador.y)
	end

end

return nivel1
