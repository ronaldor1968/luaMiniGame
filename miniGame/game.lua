-- game.lua
-- Funcoes e entidades compartilhadas entre os niveis.
-- Cada nivel e responsavel apenas por:
--   * suas entidades de inimigos especificas (boss/phase/cobra/prato/inimigo)
--   * sua funcao inicia/fim/atualiza/desenha
-- O restante (movimento, tiro, explosoes, nuvens, colisoes, shader, render de
-- foreground) esta centralizado aqui para nao duplicar entre os niveis.
require "utils"

local game = {}

-- pontos partilhados entre os niveis (acumulam; sao zerados apenas ao
-- iniciar um novo jogo, em nivel1.inicia)
game.pontos = 0

-- ============================================================
-- Entidades compartilhadas
-- ============================================================

function game.criarEntidades()
    game.jogador = {x = 200, y = 710, speed = 150, vivo = true, img = nil}
    game.balas = {
        img = nil,
        som = nil,
        tempoRecarga = 0.2,
        tempoAposUltimoTiro = 0.2,
        recarregado = true,
        lista = {}
    }
    game.explosao = {imgs = {}, lista = {}, tempoExplosao = 0.5}
    game.nuvem = {img = nil, y1 = -3200, y2 = -6400}
    game.solo = {img = nil, y1 = -3200, y2 = -6400}
    game.inimigo = {img = nil, som = nil, maximo = 2, tempoAposCriarUltimoInimigo = 1, tempoCriacao = 1, lista = {}}
    game.boss = {
        x = -60,
        y = -600,
        danos = 0,
        limitedanos = 100,
        iniciado = false,
        retirado = false,
        ativo = false,
        retirada = false,
        pontosativo = 100,
        pontosretirada = 40
    }
    game.angular = 0
    game.iluminacao = 0
    game.myshader = nil
    game.shaderNeon = nil
    game.musica = {som = nil}
end

function game.configurar(recursos)
    -- cria (ou recria) as entidades compartilhadas
    game.criarEntidades()

    -- atribui imagens e sons das entidades compartilhadas
    game.inimigo.img = recursos.imgs.inimigo
    game.inimigo.som = recursos.sons.inimigo
    game.inimigo.hw = game.inimigo.img:getWidth() / 2
    game.inimigo.hh = game.inimigo.img:getWidth() / 2
    game.inimigo.som:setVolume(0.5)
    game.jogador.img = recursos.imgs.jogador
    game.jogador.som = recursos.sons.jogador
    game.jogador.som:setVolume(0.9)
    game.balas.img = recursos.imgs.balas
    game.balas.som = recursos.sons.balas
    game.balas.som:setVolume(0.3)
    game.nuvem.img = recursos.imgs.nuvem
    game.solo.img = recursos.imgs.solo
    for i = 1, 8 do
        game.explosao.imgs[i] = recursos.imgs.explosao[i]
    end
    game.musica.som = recursos.sons.musica1
    game.musica.som:setVolume(0.1)
    game.musica.som:setLooping(true)
    game.angular = 0
    game.iluminacao = 0
    game.myshader = nil
    game.shaderNeon = nil
    game.configurarShader()
    game.jogador.vivo = true
end

function game.configurarShader(base)
    local pixelcode = [[

extern int base;
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screenCoords){
  float r = screenCoords.y / base;
  vec4 nColor = vec4(r);
  return Texel(texture, texture_coords) * nColor * color;
}
    ]]

    game.myshader = love.graphics.newShader(pixelcode)

    -- shader de efeito neon (glow + sombra) para os textos do menu/configuracoes
    -- NAO usar uniforms vec2/vec3: nesta versao do LÖVE o send com tabela
    -- nao chega ao shader; todos os uniforms sao escalares (mesmo padrão do
    -- shader de iluminacao acima, cujo send escalar funciona).
    local neoncode = [[
extern vec2 texturepx; // ou os teus uniform float u_texelW, u_texelH
extern float time;

uniform float u_glowR;
uniform float u_glowG;
uniform float u_glowB;
uniform float u_glowIntensity; // sugestao: 1.5 a 3.0
uniform float u_glowRadius;    // sugestao: 2.0 a 5.0
uniform float u_speed;
uniform float u_flicker;

vec4 effect(vec4 color, Image texture, vec2 uv, vec2 screenCoords) {
  
  // 1
  vec4 base = Texel(texture, uv);
  
  float pulso = 0.85 + 0.45 * sin(time * u_speed);
  
  float ruid = step(0.94, fract(sin(floor(time * 18.0) * 91.17) * 43758.5453));
  
  // Se 'ruid' for 1 (falha ativa) E 'u_flicker' for > 0,
  // a intensidade cai drasticamente para 0.3 (escuro) instantaneamente.
  float anim = mix(pulso, 0.3, ruid * u_flicker);

  // 3. Amostragem em anéis com pesos normalizados (Gaussiana aproximada)
  vec2 r1 = texturepx * u_glowRadius;
  vec2 r2 = r1 * 2.0;
  vec2 r3 = r1 * 3.5;

  float glowSamples = 0.0;
  // Anel interior
  glowSamples += Texel(texture, uv + vec2( r1.x,  0.0)).a;
  glowSamples += Texel(texture, uv + vec2(-r1.x,  0.0)).a;
  glowSamples += Texel(texture, uv + vec2( 0.0,  r1.y)).a;
  glowSamples += Texel(texture, uv + vec2( 0.0, -r1.y)).a;
  // Diagonais anel interior
  glowSamples += Texel(texture, uv + vec2( r1.x,  r1.y)).a * 0.707;
  glowSamples += Texel(texture, uv + vec2(-r1.x,  r1.y)).a * 0.707;
  glowSamples += Texel(texture, uv + vec2( r1.x, -r1.y)).a * 0.707;
  glowSamples += Texel(texture, uv + vec2(-r1.x, -r1.y)).a * 0.707;
  // Anel medio
  glowSamples += Texel(texture, uv + vec2( r2.x,  0.0)).a * 0.5;
  glowSamples += Texel(texture, uv + vec2(-r2.x,  0.0)).a * 0.5;
  glowSamples += Texel(texture, uv + vec2( 0.0,  r2.y)).a * 0.5;
  glowSamples += Texel(texture, uv + vec2( 0.0, -r2.y)).a * 0.5;
  // Anel exterior
  glowSamples += Texel(texture, uv + vec2( r3.x,  0.0)).a * 0.25;
  glowSamples += Texel(texture, uv + vec2(-r3.x,  0.0)).a * 0.25;
  glowSamples += Texel(texture, uv + vec2( 0.0,  r3.y)).a * 0.25;
  glowSamples += Texel(texture, uv + vec2( 0.0, -r3.y)).a * 0.25;

  // Normaliza a densidade da luz acumulada
  float glowDensity = (glowSamples / 9.0) * u_glowIntensity * anim;

  // Cores do Neon
  vec3 neonColor = vec3(u_glowR, u_glowG, u_glowB);

  // O "Tubo": o centro da letra deve ser quase branco (luz concentrada)
  // ligeiramente colorido nas bordas
  vec3 coreColor = mix(neonColor, vec3(1.0, 1.0, 1.0), 0.85);

  // Composicao da Luz
  // - Onde ha texto (base.a): mistura do brilho colorido com o centro incandescente
  // - Fora do texto: apenas a radiacao colorida (glow)
  vec3 finalRgb = (neonColor * glowDensity) + (coreColor * base.a * anim);

  // Alpha aditivo suave
  float finalAlpha = clamp(base.a + glowDensity * 0.8, 0.0, 1.0);

  return vec4(finalRgb * color.rgb, finalAlpha * color.a);
}
    ]]

    game.shaderNeon = love.graphics.newShader(neoncode)

    local firecode = [[
extern float time;

// Tamanho inverso da textura (1.0 / largura, 1.0 / altura)
uniform float u_texelW;
uniform float u_texelH;

// Controlos escalares
uniform float u_flameHeight;  // Altura da coluna em pixels (ex: 25.0 a 45.0)
uniform float u_flameWidth;   // Dispersão horizontal (ex: 2.0 a 4.0 para manter focado)
uniform float u_speed;        // Velocidade da ascensão (ex: 4.0 a 6.0)
uniform float u_preserveBody; // 1.0 = mantém sprite visível; 0.0 = queima total

// Gerador de ruído 2D rápido
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
        u.y
    );
}

vec4 effect(vec4 color, Image texture, vec2 uv, vec2 screenCoords) {
    vec2 texPx = vec2(u_texelW, u_texelH);
    vec4 base = Texel(texture, uv);

    // 1. Ruído esticado no eixo vertical (frequência Y menor = línguas de fogo longas)
    vec2 fireCoord = vec2(uv.x * 20.0, uv.y * 6.0) - vec2(0.0, time * u_speed);
    float n = noise(fireCoord) * 0.7 + noise(fireCoord * 2.0) * 0.3;

    // Deslocamento lateral moderado para manter o rastro vertical
    float xOffset = (n - 0.5) * (u_flameWidth * 0.6) * texPx.x;

    // 2. Rastreio vertical profundo (12 passos em direção a baixo)
    float fireDensity = 0.0;
    const int PASSOS = 12;
    for (int i = 1; i <= PASSOS; i++) {
        float progresso = float(i) / float(PASSOS); // 0.0 (base) a 1.0 (topo)

        // Amostra a textura mais abaixo (+Y)
        vec2 sampleUV = uv + vec2(xOffset * progresso, progresso * u_flameHeight * texPx.y);
        float a = Texel(texture, sampleUV).a;

        // Sustentação de energia: potência 0.7 mantém o fogo brilhante por mais tempo
        float sustentacao = pow(1.0 - progresso, 0.7);
        fireDensity += a * sustentacao;
    }

    // Dilatação lateral subtil para preencher os lados do sprite
    float latEsq = Texel(texture, uv + vec2(-u_flameWidth * 0.4 * texPx.x, 0.0)).a;
    float latDir = Texel(texture, uv + vec2( u_flameWidth * 0.4 * texPx.x, 0.0)).a;
    fireDensity += (latEsq + latDir) * 0.3;

    // Normalização com ganho e modulação pelo ruído
    fireDensity = (fireDensity / float(PASSOS)) * 1.6;
    fireDensity *= (n * 1.1 + 0.45);
    fireDensity = clamp(fireDensity, 0.0, 1.0);

    // 3. Gradiente térmico (Preto -> Vermelho -> Laranja -> Amarelo -> Branco)
    vec3 cVermelho = vec3(0.95, 0.15, 0.0);
    vec3 cLaranja  = vec3(1.0, 0.55, 0.05);
    vec3 cAmarelo  = vec3(1.0, 0.95, 0.3);
    vec3 cBranco   = vec3(1.0, 1.0, 1.0);

    vec3 fogoCol = vec3(0.0);
    if (fireDensity < 0.30) {
        fogoCol = mix(vec3(0.0), cVermelho, fireDensity / 0.30);
    } else if (fireDensity < 0.65) {
        fogoCol = mix(cVermelho, cLaranja, (fireDensity - 0.30) / 0.35);
    } else if (fireDensity < 0.88) {
        fogoCol = mix(cLaranja, cAmarelo, (fireDensity - 0.65) / 0.23);
    } else {
        fogoCol = mix(cAmarelo, cBranco, (fireDensity - 0.88) / 0.12);
    }

    float fogoAlpha = smoothstep(0.06, 0.30, fireDensity);

    // 4. Composição final
    vec3 corFinal;
    float alphaFinal;

    if (u_preserveBody > 0.5) {
        // Mantém o sprite visível, aquecendo-o ligeiramente com a luz do fogo
        corFinal = mix(fogoCol, base.rgb + fogoCol * 0.35, base.a);
        alphaFinal = max(base.a, fogoAlpha);
    } else {
        // Modo tocha: consome todo o sprite em chamas
        corFinal = fogoCol;
        alphaFinal = fogoAlpha;
    }

    return vec4(corFinal * color.rgb, alphaFinal * color.a);
}
]]
    game.shaderFire = love.graphics.newShader(firecode)

    local electricCode = [[
extern float time;

// Escalares de dimensão de texel
uniform float u_texelW;
uniform float u_texelH;

// Controlos
uniform float u_radius;       // Alcance dos raios (pixels)
uniform float u_speed;        // Velocidade dos arcos elétricos
uniform float u_intensity;    // Brilho do plasma
uniform float u_psycho;       // Ciclo de cores
uniform float u_threshold;    // Limiar mínimo RGB (ex: 100/255 = 0.392)

// NOVO: Máscara radial a partir do centro
uniform float u_centerRadius; // Raio máximo a partir do centro (0.0 a 0.5)
uniform float u_centerFade;   // Margem de desvanecimento na borda (ex: 0.05 a 0.15)

// Ruído 2D rápido
float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
        u.y
    );
}

// Ruído fractal (FBM)
float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    mat2 rot = mat2(0.8, -0.6, 0.6, 0.8);
    for (int i = 0; i < 4; i++) {
        v += a * noise(p);
        p = rot * p * 2.1;
        a *= 0.48;
    }
    return v;
}

// Paleta Psicodélica
vec3 rainbowPalette(float t) {
    vec3 a = vec3(0.1, 0.5, 0.3);
    vec3 b = vec3(0.7, 0.2, 0.3);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.00, 0.33, 0.67);
    return a + b * cos(6.28 * (c * t + d));
}

// Validação dupla: canais >= threshold E dentro do raio central
float sampleEligible(Image tex, vec2 coords, float thresh, float maxR, float fade) {
    vec4 c = Texel(tex, coords);
    if (c.a < 0.05) return 0.0;

    // Regra dos canais RGB >= x
    float menorRGB = min(min(c.r, c.g), c.b);
    float okRGB = step(thresh, menorRGB);

    // Regra do raio central em relação a (0.5, 0.5)
    float dist = length(coords - vec2(0.5, 0.5));
    float distMask = 1.0 - smoothstep(maxR - fade, maxR, dist);

    return okRGB * distMask * c.a;
}

vec4 effect(vec4 color, Image texture, vec2 uv, vec2 screenCoords) {
    vec2 texPx = vec2(u_texelW, u_texelH);
    vec4 base = Texel(texture, uv);

    // 1. Procura radial de pontos elegíveis (RGB alto + dentro do raio central)
    float maskPerto = 0.0;
    float maskLonge = 0.0;
    float rDistPerto = u_radius * 0.4;
    float rDistLonge = u_radius;

    vec2 off1 = vec2(rDistPerto, 0.0) * texPx;
    vec2 off2 = vec2(0.0, rDistPerto) * texPx;
    vec2 offD = vec2(rDistPerto * 0.707) * texPx;

    maskPerto += sampleEligible(texture, uv + off1, u_threshold, u_centerRadius, u_centerFade);
    maskPerto += sampleEligible(texture, uv - off1, u_threshold, u_centerRadius, u_centerFade);
    maskPerto += sampleEligible(texture, uv + off2, u_threshold, u_centerRadius, u_centerFade);
    maskPerto += sampleEligible(texture, uv - off2, u_threshold, u_centerRadius, u_centerFade);
    maskPerto += sampleEligible(texture, uv + offD, u_threshold, u_centerRadius, u_centerFade);
    maskPerto += sampleEligible(texture, uv - offD, u_threshold, u_centerRadius, u_centerFade);
    maskPerto += sampleEligible(texture, uv + vec2(offD.x, -offD.y), u_threshold, u_centerRadius, u_centerFade);
    maskPerto += sampleEligible(texture, uv + vec2(-offD.x, offD.y), u_threshold, u_centerRadius, u_centerFade);
    maskPerto /= 8.0;

    vec2 offL1 = vec2(rDistLonge, 0.0) * texPx;
    vec2 offL2 = vec2(0.0, rDistLonge) * texPx;
    vec2 offLD = vec2(rDistLonge * 0.707) * texPx;

    maskLonge += sampleEligible(texture, uv + offL1, u_threshold, u_centerRadius, u_centerFade);
    maskLonge += sampleEligible(texture, uv - offL1, u_threshold, u_centerRadius, u_centerFade);
    maskLonge += sampleEligible(texture, uv + offL2, u_threshold, u_centerRadius, u_centerFade);
    maskLonge += sampleEligible(texture, uv - offL2, u_threshold, u_centerRadius, u_centerFade);
    maskLonge += sampleEligible(texture, uv + offLD, u_threshold, u_centerRadius, u_centerFade);
    maskLonge += sampleEligible(texture, uv - offLD, u_threshold, u_centerRadius, u_centerFade);
    maskLonge += sampleEligible(texture, uv + vec2(offLD.x, -offLD.y), u_threshold, u_centerRadius, u_centerFade);
    maskLonge += sampleEligible(texture, uv + vec2(-offLD.x, offLD.y), u_threshold, u_centerRadius, u_centerFade);
    maskLonge /= 8.0;

    float campoForca = max(maskPerto * 1.3, maskLonge * 0.8);

    // 2. Descargas elétricas distorcidas (Domain Warping)
    vec2 electricUV = uv * 35.0;
    float warp = fbm(electricUV + vec2(time * u_speed * 0.5, -time * u_speed));
    vec2 warpedUV = electricUV + vec2(warp * 4.0, warp * 4.0) + vec2(time * u_speed * 1.2);
    
    float descarga = fbm(warpedUV);
    float raios = pow(abs(sin(descarga * 6.28318)), 12.0);

    // 3. Força e Cor
    float energiaTotal = (campoForca * 1.5 + raios * campoForca * 4.0) * u_intensity;

    float cicloCor = (uv.x + uv.y) * 0.8 + time * u_psycho + warp * 0.5;
    vec3 corPsicodelica = rainbowPalette(cicloCor);
    vec3 raioFinal = mix(corPsicodelica * energiaTotal, vec3(1.0), raios * 0.75 * campoForca);

    // 4. Verificação no pixel base do próprio sprite
    float selfEligible = 0.0;
    if (base.a > 0.05) {
        float distCentro = length(uv - vec2(0.5, 0.5));
        float maskCentro = 1.0 - smoothstep(u_centerRadius - u_centerFade, u_centerRadius, distCentro);
        float menorRGB = min(min(base.r, base.g), base.b);
        selfEligible = step(u_threshold, menorRGB) * maskCentro;
    }

    vec3 spriteRGB = base.rgb + (raioFinal * 0.5 * selfEligible);
    vec3 rgbFinal = mix(raioFinal, spriteRGB, base.a);
    float alphaFinal = clamp(base.a + energiaTotal * 0.85, 0.0, 1.0);

    return vec4(rgbFinal * color.rgb, alphaFinal * color.a);
}
]]
    game.shaderEletric = love.graphics.newShader(electricCode)

end

-- ============================================================
-- Movimento, tiro, explosões, ambiente
-- ============================================================

function game.atualizaDificuldade(...)
    local pontos, phase = ...
    if pontos > 10 then
        game.inimigo.tempoCriacao = 1
        phase.intervaloMaximo = 13
        if pontos < 200 then
            game.inimigo.tempoCriacao = 0.9
            phase.intervaloMaximo = 12
            game.balas.tempoRecarga = 0.15
        elseif pontos < 500 then
            game.inimigo.tempoCriacao = 0.7
            phase.intervaloMaximo = 10
            game.balas.tempoRecarga = 0.1
        elseif pontos < 1000 then
            game.inimigo.tempoCriacao = 0.5
            phase.intervaloMaximo = 7
        elseif pontos < 3000 then
            game.inimigo.tempoCriacao = 0.3
            phase.intervaloMaximo = 5
        elseif pontos < 5000 then
            game.inimigo.tempoCriacao = 0.2
            phase.intervaloMaximo = 4
        else
            game.inimigo.tempoCriacao = 0.1
            phase.intervaloMaximo = 2
        end
    end
end

function game.movejogador(...)
    local dt, jogador = ...
    if love.keyboard.isDown("left", "a") then
        if jogador.x > 0 then -- binds us to the map
            jogador.x = jogador.x - (jogador.speed * dt)
        end
    end
    if love.keyboard.isDown("right", "d") then
        if jogador.x < (love.graphics.getWidth() - jogador.img:getWidth()) then
            jogador.x = jogador.x + (jogador.speed * dt)
        end
    end
    if love.keyboard.isDown("up", "w") then
        if jogador.y > 0 then
            jogador.y = jogador.y - (jogador.speed * dt)
        end
    end
    if love.keyboard.isDown("down", "s") then
        if jogador.y < 710 then
            jogador.y = jogador.y + (jogador.speed * dt)
        end
    end
end

function game.dispara(...)
    local dt, jogador, balas, deltaSpeed, deltaRecarga = ...
    if love.keyboard.isDown("space", "rctrl", "lctrl") then
        if jogador.vivo and balas.recarregado then
            -- cria balas
            local newBullet = {x = jogador.x + (jogador.img:getWidth() - balas.img:getWidth()) / 2, y = jogador.y}
            table.insert(balas.lista, newBullet)
            balas.recarregado = false
            balas.tempoAposUltimoTiro = balas.tempoRecarga
            tocarEfeito(balas.som)
        end
    else
        balas.tempoAposUltimoTiro = balas.tempoAposUltimoTiro - deltaRecarga
        if (balas.tempoAposUltimoTiro < 0) then
            balas.recarregado = true
        end
    end

    -- atualiza posicao das balas
    for i, blTmp in pairs(balas.lista) do
        blTmp.y = blTmp.y - deltaSpeed

        if blTmp.y < 0 then -- remove balas when they pass off the screen
            table.remove(balas.lista, i)
        end
    end
end

function game.atualizaexplosoes(...)
    local dt, explosao, deltaTempo, deltaSpeed = ...
    local remover = {}
    for i, expTmp in pairs(explosao.lista) do
        expTmp.tempo = expTmp.tempo - deltaTempo
        expTmp.y = expTmp.y + deltaSpeed
        if (expTmp.tempo < 0) then
            expTmp.tempo = explosao.tempoExplosao
            if expTmp.indice < 8 then
                expTmp.indice = expTmp.indice + 1
            else
                table.insert(remover, i)
            end
        end
    end
    local n = #remover
    for k = n, 1, -1 do
        table.remove(explosao.lista, remover[k])
    end
end

function game.movenuvenssolo(...)
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

function game.atualizainimigos1(...)
    local dt, pontos, inimigo, deltaSpeed, deltaTempo = ...
    local remover = {}
    -- atualiza posicao inimigo
    for i, iniTmp in pairs(inimigo.lista) do
        iniTmp.y = iniTmp.y + deltaSpeed
        if iniTmp.x > 400 or iniTmp.x < 0 then
            iniTmp.delta_x = -iniTmp.delta_x
        end
        iniTmp.x = iniTmp.x + iniTmp.delta_x

        if iniTmp.y > 850 then -- remove inimigos quando sai da tela
            table.insert(remover, i)
        end
    end
    local n = #remover
    for k = n, 1, -1 do
        table.remove(inimigo.lista, remover[k])
    end

    inimigo.tempoAposCriarUltimoInimigo = inimigo.tempoAposCriarUltimoInimigo - deltaTempo
    if inimigo.tempoAposCriarUltimoInimigo < 0 then
        inimigo.tempoAposCriarUltimoInimigo = inimigo.tempoCriacao
        if (#inimigo.lista < inimigo.maximo) then
            -- cria novo inimigo
            local dx = math.random(-1, 1) * pontos
            if (dx > 100) then
                dx = 100
            elseif dx < -100 then
                dx = -100
            end
            table.insert(
                inimigo.lista,
                {x = math.random(10, love.graphics.getWidth() - 80), y = -30, delta_x = dx * dt, s = math.random(-2, 2)}
            )
        end
    end
end

function game.atualizainimigos2(...)
    local dt, phase, deltaTempo, deltaSpeed = ...
    phase.tempoAposUltimoTiro = phase.tempoAposUltimoTiro - deltaTempo
    if phase.y > 800 and phase.tempoAposUltimoTiro < 0 then
        -- novo tipo de phase
        phase.y = -800
        phase.x = math.random(10, 510)
        phase.tempoAposUltimoTiro = phase.intervaloMaximo
        tocarEfeito(phase.som)
    else
        phase.y = phase.y + deltaSpeed
    end
end

function game.atualizainimigos3(...)
    local dt, angular, pontos, cobra, deltaSpeed = ...
    cobra.ybase = cobra.ybase + deltaSpeed
    if cobra.ybase > 1400 then
        cobra.ybase = -3000
        for i, cblTmp in pairs(cobra.lista) do
            cblTmp.viva = true
        end
    end
    for i, cblTmp in pairs(cobra.lista) do
        local a = angular + i * 0.628
        cblTmp.x = math.sin(a) * 100
        cblTmp.y = -40 * i
    end
end

function game.atualizainimigos4(...)
    local dt, angular, pontos, prato, deltaSpeed = ...
    prato.ybase = prato.ybase + deltaSpeed
    if prato.ybase > 1400 then
        prato.ybase = -2000
        for i, cblTmp in pairs(prato.lista) do
            cblTmp.viva = true
        end
    end
    for i, cblTmp in pairs(prato.lista) do
        local a = angular + i * 0.628 * 4
        cblTmp.x = math.sin(a) * 100
        cblTmp.y = -40 * i
    end
end

function game.atualizaboss1(...)
    local dt, pontos, boss, pontosboss, speed = ...

    if boss.ativo then
        if not boss.iniciado then
            if boss.y < -200 then
                boss.y = boss.y + speed
            else
                boss.iniciado = true
                boss.pontosretirada = pontos + pontosboss
            end
        else
            if not boss.retirada then
                boss.retirada = (pontos > boss.pontosretirada)
            else
                if boss.y > -700 then
                    boss.y = boss.y - speed
                else
                    boss.retirado = true
                    boss.som:stop()
                end
            end
        end
    else
        boss.ativo = (pontos > boss.pontosativo)
        if (boss.ativo) then
            tocarMusica(boss.som)
        end
    end
end

-- ============================================================
-- Colisoes (corrigido: nao remover durante iteracao com pairs)
-- ============================================================

function game.colisaobalainimigojogador(...)
    local dt, balas, inimigo, jogador, explosao, pontos = ...
    local deltapontos = 0
    local tolerancia = 1
    local w1 = inimigo.img:getWidth()
    local h1 = inimigo.img:getHeight()
    local w2 = balas.img:getWidth()
    local h2 = balas.img:getHeight()
    local w3 = jogador.img:getWidth() * tolerancia
    local h3 = jogador.img:getHeight() * tolerancia

    local removerBala, removerInimigo = {}, {}
    for i, iniTmp in pairs(inimigo.lista) do
        for j, blTmp in pairs(balas.lista) do
            if testesSimplesDeColisao(iniTmp.x, iniTmp.y, w1, h1, blTmp.x, blTmp.y, w2, h2) then
                inimigo.maximo = 2 + pontos / 10
                tocarEfeito(inimigo.som)
                deltapontos = deltapontos + 1
                table.insert(explosao.lista, {x = iniTmp.x - 80, y = iniTmp.y - 80, tempo = explosao.tempoExplosao, indice = 1})
                table.insert(removerBala, j)
                table.insert(removerInimigo, i)
                break
            end
        end

        if testesSimplesDeColisao(iniTmp.x, iniTmp.y, w1, h1, jogador.x, jogador.y, w3, h3) then
            tocarEfeito(jogador.som)
            tocarEfeito(inimigo.som)
            table.insert(removerInimigo, i)
            table.insert(explosao.lista, {x = iniTmp.x - 80, y = iniTmp.y - 80, tempo = explosao.tempoExplosao, indice = 1})
            table.insert(explosao.lista, {x = jogador.x - 80, y = jogador.y - 80, tempo = explosao.tempoExplosao, indice = 1})
            jogador.vivo = false
        end
    end

    local n = #removerInimigo
    for k = n, 1, -1 do
        table.remove(inimigo.lista, removerInimigo[k])
    end
    local m = #removerBala
    for l = m, 1, -1 do
        table.remove(balas.lista, removerBala[l])
    end

    return deltapontos
end

function game.colisaoinimigo2jogador(...)
    local dt, phase, jogador, explosao = ...
    if testaColisao(phase, jogador) then
        tocarEfeito(jogador.som)
        table.insert(explosao.lista, {x = jogador.x - 80, y = jogador.y - 80, tempo = explosao.tempoExplosao, indice = 1})
        jogador.vivo = false
    end
end

function game.colisaobalainimigo3jogador(...)
    local dt, balas, cobra, jogador, explosao = ...
    local deltapontos = 0
    local tolerancia = 1
    local w1 = cobra.img:getWidth()
    local h1 = cobra.img:getHeight()
    local w2 = balas.img:getWidth()
    local h2 = balas.img:getHeight()
    local w3 = jogador.img:getWidth() * tolerancia
    local h3 = jogador.img:getHeight() * tolerancia

    local removerBala, removerCobra = {}, {}
    for i, clbBase in pairs(cobra.lista) do
        if clbBase.viva then
            for j, blTmp in pairs(balas.lista) do
                if testesSimplesDeColisao(cobra.xbase + clbBase.x, cobra.ybase + clbBase.y, w1, h1, blTmp.x, blTmp.y, w2, h2) then
                    tocarEfeito(cobra.som)
                    deltapontos = deltapontos + 1
                    table.insert(
                        explosao.lista,
                        {x = cobra.xbase + clbBase.x - 80, y = cobra.ybase + clbBase.y - 80, tempo = explosao.tempoExplosao, indice = 1}
                    )
                    table.insert(removerBala, j)
                    clbBase.viva = false
                    break
                end
            end

            if testesSimplesDeColisao(cobra.xbase + clbBase.x, cobra.ybase + clbBase.y, w1, h1, jogador.x, jogador.y, w3, h3) then
                tocarEfeito(jogador.som)
                tocarEfeito(cobra.som)
                table.insert(removerCobra, i)
                table.insert(
                    explosao.lista,
                    {x = cobra.xbase + clbBase.x - 80, y = cobra.ybase + clbBase.y - 80, tempo = explosao.tempoExplosao, indice = 1}
                )
                table.insert(explosao.lista, {x = jogador.x - 80, y = jogador.y - 80, tempo = explosao.tempoExplosao, indice = 1})
                jogador.vivo = false
            end
        end
    end

    local n = #removerCobra
    for k = n, 1, -1 do
        table.remove(cobra.lista, removerCobra[k])
    end
    local m = #removerBala
    for l = m, 1, -1 do
        table.remove(balas.lista, removerBala[l])
    end

    return deltapontos
end

function game.colisaobalainimigo4jogador(...)
    local dt, balas, prato, jogador, explosao = ...
    local deltapontos = 0
    local tolerancia = 1
    local w1 = prato.img:getWidth()
    local h1 = prato.img:getHeight()
    local w2 = balas.img:getWidth()
    local h2 = balas.img:getHeight()
    local w3 = jogador.img:getWidth() * tolerancia
    local h3 = jogador.img:getHeight() * tolerancia

    local removerBala, removerPrato = {}, {}
    for i, clbBase in pairs(prato.lista) do
        if clbBase.viva then
            for j, blTmp in pairs(balas.lista) do
                if testesSimplesDeColisao(prato.xbase + clbBase.x, prato.ybase + clbBase.y, w1, h1, blTmp.x, blTmp.y, w2, h2) then
                    tocarEfeito(prato.som)
                    deltapontos = deltapontos + 1
                    table.insert(
                        explosao.lista,
                        {x = prato.xbase + clbBase.x - 80, y = prato.ybase + clbBase.y - 80, tempo = explosao.tempoExplosao, indice = 1}
                    )
                    table.insert(removerBala, j)
                    clbBase.viva = false
                    break
                end
            end

            if testesSimplesDeColisao(prato.xbase + clbBase.x, prato.ybase + clbBase.y, w1, h1, jogador.x, jogador.y, w3, h3) then
                tocarEfeito(jogador.som)
                tocarEfeito(prato.som)
                table.insert(removerPrato, i)
                table.insert(
                    explosao.lista,
                    {x = prato.xbase + clbBase.x - 80, y = prato.ybase + clbBase.y - 80, tempo = explosao.tempoExplosao, indice = 1}
                )
                table.insert(explosao.lista, {x = jogador.x - 80, y = jogador.y - 80, tempo = explosao.tempoExplosao, indice = 1})
                jogador.vivo = false
            end
        end
    end

    local n = #removerPrato
    for k = n, 1, -1 do
        table.remove(prato.lista, removerPrato[k])
    end
    local m = #removerBala
    for l = m, 1, -1 do
        table.remove(balas.lista, removerBala[l])
    end

    return deltapontos
end

-- ============================================================
-- Reinicializacao de entidades entre fases
-- ============================================================

function game.reinicializa1(...)
    local balas, inimigo, boss, jogador = ...
    balas.lista = {}
    balas.tempoRecarga = 0.2
    balas.tempoAposUltimoTiro = balas.tempoRecarga
    inimigo.lista = {}
    inimigo.tempoCriacao = 1
    inimigo.tempoAposCriarUltimoInimigo = inimigo.tempoCriacao
    boss.y = -700
    boss.iniciado = false
    boss.retirado = false
    boss.ativo = false
    boss.retirada = false
    jogador.vivo = false
end

function game.reinicializa2(...)
    local phase = ...
    phase.intervaloMaximo = 15
    phase.tempoAposUltimoTiro = phase.intervaloMaximo
    phase.y = 1000
end

function game.reinicializa3(...)
    local poc = ...
    poc.ybase = -1000
end

-- ============================================================
-- Render compartilhado (cenario + foreground)
-- ============================================================

function game.desenharCenario(...)
    local base, limite = ...
    love.graphics.setBackgroundColor(0, 0.1, 0.3, 0.1)

    game.shaderOn(base, limite)

    love.graphics.draw(game.solo.img, 0, game.solo.y1)
    love.graphics.draw(game.solo.img, 0, game.solo.y2)

    love.graphics.draw(game.nuvem.img, 0, game.nuvem.y1)
    love.graphics.draw(game.nuvem.img, 0, game.nuvem.y2)
    love.graphics.draw(game.nuvem.img, 0, game.nuvem.y1 + 300)
    love.graphics.draw(game.nuvem.img, 0, game.nuvem.y2 + 300)
end

function game.desenharParticulas()
    love.graphics.setColor(1, 1, 1, 1)
    game.iluminacao = 0
    for i, expTmp in pairs(game.explosao.lista) do
        love.graphics.draw(game.explosao.imgs[expTmp.indice], expTmp.x, expTmp.y)
        game.iluminacao = game.iluminacao + 100
    end

    game.shadeOff()

    for i, blTmp in pairs(game.balas.lista) do
        love.graphics.draw(game.balas.img, blTmp.x, blTmp.y)
    end

    if game.jogador.vivo then
        love.graphics.draw(game.jogador.img, game.jogador.x, game.jogador.y)
    end

    if game.boss.ativo then
        game.shaderFireOn(game.boss.img)
        love.graphics.draw(game.boss.img, game.boss.x + game.boss.hw, game.boss.y + game.boss.hh, game.angular, 1, 1, game.boss.hw, game.boss.hh)
        game.shadeOff()
    end
end

function game.shaderOn(...)
    local base, limite = ...
    game.myshader:send("base", base)
    love.graphics.setShader(game.myshader)
    if game.iluminacao > limite then
        game.iluminacao = limite
    end
end

function game.shaderNeonOn(...)
    if not game.shaderNeon then
		game.configurarShader()
	end
	local s = game.shaderNeon

	s:send("u_glowR", 0.0)  
    s:send("u_glowG", 0.85)
    s:send("u_glowB", 1.0)
    s:send("u_glowIntensity", 2.2)
    s:send("u_glowRadius", 3.0)

	s:send("time", love.timer.getTime()) -- OBRIGATÓRIO para animação

    -- 1. VELOCIDADE DA PULSAÇÃO (u_speed)
    -- Controla o "respirar" lento do neon.
    -- Baixo (ex: 1.0 a 3.0) = Respiração calma.
    -- Alto (ex: 10.0+) = Batimento cardíaco rápido.
    s:send("u_speed", 2.5) 

	-- 2. INTENSIDADE DA FALHA/PISCADE_LA (u_flicker)
	-- Controla o quanto a luz "cai" quando falha.
	-- 0.0 = Desativado (apenas pulsação lenta).
	-- 0.5 = Pisca suavemente.
	-- 1.0 = Falha agressiva e realista (quase apaga).
	s:send("u_flicker", 0.99) -- Tenta 0.8 para um efeito visível

	love.graphics.setShader(s)
end

function game.shaderFireOn(...)    
    if not game.shaderNeon then
		game.configurarShader()
	end
    local s = game.shaderFire
    meuSprite = ...
	    
    -- Envio de uniforms escalares
    s:send("time", love.timer.getTime())
    s:send("u_texelW", 1.0 / meuSprite:getWidth())
    s:send("u_texelH", 1.0 / meuSprite:getHeight())

    -- Altura e largura das chamas (em pixels)
    s:send("u_flameHeight", 16.0)   -- Quão alto o fogo sobe acima do sprite
    s:send("u_flameWidth", 6.0)     -- Quão largo o fogo ondula
    s:send("u_speed", 3.5)          -- Velocidade da animação
    s:send("u_preserveBody", 1.0)   -- 1.0 = sprite intacto com fogo ao redor; 0.0 = vira uma tocha

    -- Subir o alcance vertical (ex: de 16 para 30 ou 45 pixels acima)
    s:send("u_flameHeight", 35.0)

    -- Reduzir a dispersão lateral para focar o rastro numa coluna vertical
    s:send("u_flameWidth", 3.0)

    -- Uma velocidade mais alta dá a sensação de sucção/chama a disparar para cima
    s:send("u_speed", 5.0)

    love.graphics.setShader(s)
end

function game.shaderEletricOn(...)
    local cx = love.graphics.getWidth() / 2
    local cy = love.graphics.getHeight() / 2
    local mx, my = love.mouse.getPosition()
    local s = game.shaderEletric
    meuSprite = ...


    love.graphics.setShader(s)

    -- Envio dos uniforms escalares
    s:send("time", love.timer.getTime())
    s:send("u_texelW", 1.0 / meuSprite:getWidth())
    s:send("u_texelH", 1.0 / meuSprite:getHeight())
    
    -- Ajustes do efeito:
    s:send("u_radius", 20.0)    -- Alcance dos raios (pixels)
    s:send("u_speed", 15.5)      -- Tremulação e velocidade dos arcos
    s:send("u_intensity", 1.2)  -- Densidade da aura
    s:send("u_psycho", 4.0)     -- Velocidade do ciclo arco-íris
    
    s:send("u_threshold", 10.0 / 255.0) -- Filtro RGB >= 100

    -- RAIO A PARTIR DO CENTRO:
    -- 0.20 = Apenas um núcleo pequeno no centro (ex: um cristal no peito do inimigo)
    -- 0.35 = Metade do sprite a partir do centro
    -- 0.50 = Cobre o sprite quase todo a partir do meio
    s:send("u_centerRadius", 0.40)

    -- SUAVIZAÇÃO DA BORDA DO RAIO:
    -- Controla a transição suave para as labaredas não cortarem a seco
    s:send("u_centerFade", 0.08)
end    

function game.shadeOff()
    love.graphics.setShader()
end

return game
