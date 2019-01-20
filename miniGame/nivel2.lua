local nivel2 = {limite = 200}

local angular = 0
local iluminacao = 0

-- objetos de imagens
local jogador = {x = 200, y = 710, speed = 150, vivo = true, img = nil }
local balas = {img =nil, som = nil, tempoRecarga = 0.5, tempoAposUltimoTiro = 0.5, recarregado = true, lista = {}}
local inimigo = {img =nil, som = nil, maximo = 2, tempoAposCriarUltimoInimigo = 1, tempoCriacao = 1, lista = {}}
local phase = {img = nil, som = nil, x = 300, y = 8000, intervaloMaximo = 15, tempoAposUltimoTiro = 15}
local nuvem = {img = nil, y1 = -3200, y2 = -6400}
local solo = {img = nil, y1 = -3200, y2 = -6400}
local explosao = {imgs={}, lista = {}, tempoExplosao = 0.5}
local myshader = nil
local musica = {som = nil}

function nivel2.inicia(recursos)
  inimigo.img = recursos.imgs.inimigo
	inimigo.som = recursos.sons.inimigo
	inimigo.som:setVolume(0.5)
	jogador.img = recursos.imgs.jogador
	jogador.som = recursos.sons.jogador
	jogador.som:setVolume(0.8)
	balas.img = recursos.imgs.balas
	balas.som = recursos.sons.balas
	balas.som:setVolume(0.3)
	phase.img = recursos.imgs.phase
	phase.som = recursos.sons.phase
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
end

function nivel2.fim()
  -- reinicia os valores
  balas.lista = {}
  balas.tempoRecarga = 0.5
  balas.tempoAposUltimoTiro = balas.tempoRecarga
  inimigo.lista = {}
  inimigo.tempoCriacao = 1
  inimigo.tempoAposCriarUltimoInimigo = inimigo.tempoCriacao
  phase.intervaloMaximo = 15
  phase.tempoAposUltimoTiro = phase.intervaloMaximo
  phase.y = 1000
  jogador.vivo = false
  musica.som:stop()
end

function nivel2.atualiza(dt)

  local deltaTmp1 = 5 * dt
	local deltaTmp2 = 15 * dt
	local deltaTmp3 = 250 * dt;
	local deltaTmp4 = 1 * dt
	local deltaTmp5 = 350 * dt
	local deltaTmp6 = 200 * dt
	local deltaTmp7 = 30 * dt;

	movejogador(dt, jogador)
	dispara(dt, jogador, balas, deltaTmp3, deltaTmp4)
  atualizaexplosoes(dt, explosao, deltaTmp1, deltaTmp2)
  -- move nuvens e solo
  movenuvenssolo(dt, nuvem, solo, deltaTmp3, deltaTmp7)
  -- atualiza posicao inimigo
  atualizainimigos1(dt, pontos, inimigo, deltaTmp6, deltaTmp4)
  atualizainimigos2(dt, phase, deltaTmp4, deltaTmp5)

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

  -- testa cosiloes
  pontos = pontos + colisaobalainimigojogador(dt, balas, inimigo, jogador, explosao)

  colisaoinimigo2jogador(dt, phase, jogador, explosao)

  return pontos, jogador.vivo
end

function shaderOn()
	myshader:send("base", 600 - iluminacao)
	love.graphics.setShader(myshader)
	if iluminacao > 600 then
		iluminacao = 600
	end
end

function shadeOff()
	love.graphics.setShader()
end

function nivel2.desenha()
  love.graphics.setBackgroundColor( 0, 0.1, 0.3, 0.1 )

	shaderOn()


	love.graphics.draw(solo.img, 0, solo.y1)
	love.graphics.draw(solo.img, 0, solo.y2)

	--love.graphics.draw(phase.img, phase.x, phase.y, math.rad(phase.angulo), 1, 1, 100, 100)



	love.graphics.draw(phase.img, phase.x, phase.y)

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

return nivel2
