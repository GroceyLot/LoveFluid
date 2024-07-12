return function(args)
    local shader = love.graphics.newShader("shader.glsl")

    return function(dots)
        local radius, numParticles, smooth = args()
        shader:send("radius", radius)
        shader:send("dotCount", numParticles)
        shader:send("smoothFactor", smooth)
        shader:send("viewDir", {0, 0, 1})
        shader:send("dots", unpack(dots))
        love.graphics.setShader(shader)
        love.graphics.rectangle("fill", 0, 0, 1000, 1000)
        love.graphics.setShader()
    end
end
