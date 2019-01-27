debug_rect = {}
debug_text = {}


function testaColisao(a, b)
	local erro = a.img:getWidth() / 4
	return testesSimplesDeColisao(a.x + erro, a.y + erro, a.img:getWidth() - 2 * erro, a.img:getHeight() - 2 * erro, b.x, b.y, b.img:getWidth(), b.img:getHeight())
end

function testesSimplesDeColisao(x1,y1,w1,h1, x2,y2,w2,h2)
	local intersecta = x1 < (x2 + w2) and
				 	(x1 + w1) > x2 and
					y1 < (y2 + h2) and
					(y1 + h1) > y2

	--debugrect(x1,y1,w1,h1, x2,y2,w2,h2)

  return intersecta
end

function debugrect(px1, py1, pw1, ph1, px2, py2, pw2, ph2)
	table.insert(debug_rect, {x = px1, y = py1, w = pw1, h = ph1})
	table.insert(debug_rect, {x = px2, y = py2, w = pw2, h = ph2})
end

function debugtext(text)
	table.insert(debug_text, text)
end
