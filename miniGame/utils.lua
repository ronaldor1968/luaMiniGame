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
