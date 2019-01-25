function movejogador(...)
  local dt, jogador = ...
  if love.keyboard.isDown('left','a') then
		if jogador.x > 0 then -- binds us to the map
			jogador.x = jogador.x - (jogador.speed*dt)
		end
	end
  if love.keyboard.isDown('right','d') then
		if jogador.x < (love.graphics.getWidth() - jogador.img:getWidth()) then
			jogador.x = jogador.x + (jogador.speed*dt)
		end
	end
  if love.keyboard.isDown('up','w') then
		if jogador.y > 0 then
			jogador.y = jogador.y - (jogador.speed*dt)
		end
  end
	if love.keyboard.isDown('down','s') then
		if jogador.y < 710  then
			jogador.y = jogador.y + (jogador.speed*dt)
		end
	end
end


function dispara(...)
  local dt, jogador, balas, deltaSpeed, deltaRecarga = ...
  if jogador.vivo and love.keyboard.isDown('space', 'rctrl', 'lctrl') and balas.recarregado then
		-- cria balas
		newBullet = { x = jogador.x + (jogador.img:getWidth() - balas.img:getWidth())/2, y = jogador.y }
		table.insert(balas.lista, newBullet)
		balas.recarregado = false
		balas.tempoAposUltimoTiro = balas.tempoRecarga
		balas.som:stop()
		balas.som:play()
	end

  -- atualiza posicao das balas
	for i, blTmp in pairs(balas.lista) do
		blTmp.y = blTmp.y - deltaSpeed

		if blTmp.y < 0 then -- remove balas when they pass off the screen
			table.remove(balas.lista, i)
		end
	end

  -- conta o tempo para as balas e os inimigos
	balas.tempoAposUltimoTiro = balas.tempoAposUltimoTiro - deltaRecarga
	if (balas.tempoAposUltimoTiro < 0) then
		balas.recarregado = true
	end
end

function atualizaexplosoes(...)
  local dt, explosao, deltaTempo, deltaSpeed = ...
  for i, expTmp in pairs(explosao.lista) do
		expTmp.tempo = expTmp.tempo  -  deltaTempo
		expTmp.y = expTmp.y + deltaSpeed
		if (expTmp.tempo < 0) then
			expTmp.tempo = explosao.tempoExplosao
			if expTmp.indice < 8 then
				expTmp.indice = expTmp.indice + 1
			else
				table.remove(explosao.lista, i)
			end
		end
	end
end

function movenuvenssolo(...)
  local dt, nuvem, solo, deltaNuvem, deltaSolo = ...
  nuvem.y1 = nuvem.y1 + deltaNuvem
  nuvem.y2 = nuvem.y2 + deltaNuvem
  if (nuvem.y1 > 0) then
    nuvem.y1 = -6400
  end
  if (nuvem.y2 > 0) then
    nuvem.y2 = -6400
  end

  solo.y1 = solo.y1 + deltaSolo
  solo.y2 = solo.y2 + deltaSolo
  if (solo.y1 > 0) then
    solo.y1 = -6400
  end
  if (solo.y2 > 0) then
    solo.y2 = -6400
  end
end


function atualizainimigos1(...)
  local dt, pontos, inimigo, deltaSpeed, deltaTempo = ...
  -- atualiza posicao inimigo
  for i, iniTmp in pairs(inimigo.lista) do
    iniTmp.y = iniTmp.y + deltaSpeed
    if iniTmp.x > 400 or iniTmp.x < 0 then
      iniTmp.delta_x = -iniTmp.delta_x
    end
    iniTmp.x = iniTmp.x + iniTmp.delta_x

    if iniTmp.y > 850 then -- remove inimigos quando sai da tela
      table.remove(inimigo.lista, i)
    end
  end

  inimigo.tempoAposCriarUltimoInimigo = inimigo.tempoAposCriarUltimoInimigo - deltaTempo
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
			table.insert(inimigo.lista, { x = math.random(10, love.graphics.getWidth()  - 80), y = -30, delta_x = dx * dt, s = math.random(-2, 2)})
		end
	end
end

function atualizainimigos2(...)
  local dt, phase, deltaTempo, deltaSpeed = ...
  phase.tempoAposUltimoTiro = phase.tempoAposUltimoTiro - deltaTempo
	if phase.y > 800 and phase.tempoAposUltimoTiro < 0 then
		-- novo tipo de phase
		phase.y = -800
		phase.x = math.random(10, 510)
		phase.tempoAposUltimoTiro = phase.intervaloMaximo
		phase.som:stop()
		phase.som:play()
	else
		phase.y = phase.y + deltaSpeed
	end
end

function atualizainimigos3(...)
  local dt, angular, pontos, cobra, deltaSpeed = ...
  cobra.ybase = cobra.ybase + deltaSpeed
	if cobra.ybase > 1400 then
		cobra.ybase = -3000
		for i, cblTmp in pairs(cobra.lista) do
				cblTmp.viva = true
		end
	end
	for i, cblTmp in pairs(cobra.lista) do
		local a = angular + i * 0.628 * math.max(pontos,100) / 100
			cblTmp.x = math.sin(a) * 100
			cblTmp.y = -40 * i
	end
end

function colisaobalainimigojogador(...)
  local dt, balas, inimigo, jogador, explosao = ...
  local deltapontos = 0
  for i, iniTmp in pairs(inimigo.lista) do
		for j, blTmp in pairs(balas.lista) do
			if testesSimplesDeColisao(iniTmp.x, iniTmp.y, inimigo.img:getWidth(), inimigo.img:getHeight(), blTmp.x, blTmp.y, balas.img:getWidth(), balas.img:getHeight()) then
				inimigo.maximo = 2 + pontos / 10
				inimigo.som:stop()
				inimigo.som:play()
				deltapontos = deltapontos + 1
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
  return deltapontos
end

function colisaoinimigo2jogador(...)
  local dt, phase, jogador, explosao = ...
  if testaColisao(phase, jogador)
	then
		jogador.som:play()
		table.insert(explosao.lista, { x = jogador.x - 80 , y = jogador.y - 80, tempo = explosao.tempoExplosao, indice = 1})
		jogador.vivo = false
	end
end

function colisaobalainimigo3jogador(...)
  local dt, balas, cobra, jogador, explosao = ...
  local deltapontos = 0
  for i, clbBase in pairs(cobra.lista) do
		for j, blTmp in pairs(balas.lista) do
			if testesSimplesDeColisao(cobra.xbase + clbBase.x, cobra.ybase + clbBase.y, cobra.img:getWidth(), cobra.img:getHeight(), blTmp.x, blTmp.y, balas.img:getWidth(), balas.img:getHeight()) then
				cobra.som:stop()
				cobra.som:play()
				deltapontos = deltapontos + 1
				table.insert(explosao.lista, { x = cobra.xbase + clbBase.x - 80, y = cobra.ybase + clbBase.y - 80, tempo = explosao.tempoExplosao, indice = 1})
				table.remove(balas.lista, j)
				clbBase.viva = false
			end
		end

		if testesSimplesDeColisao(cobra.xbase + clbBase.x, cobra.ybase + clbBase.y, cobra.img:getWidth(), cobra.img:getHeight(), jogador.x, jogador.y, jogador.img:getWidth(), jogador.img:getHeight())
		then
			jogador.som:play()
			cobra.som:stop()
			cobra.som:play()
			table.remove(cobra.lista, i)
			table.insert(explosao.lista, { x = cobra.xbase + clbBase.x - 80, y = cobra.ybase + clbBase.y - 80, tempo = explosao.tempoExplosao, indice = 1})
			table.insert(explosao.lista, { x = jogador.x - 80, y = jogador.y - 80, tempo = explosao.tempoExplosao, indice = 1})
			jogador.vivo = false
		end

	end
  return deltapontos
end
