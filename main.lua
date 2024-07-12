local positions = {}
local velocities = {}
local radius = 7
local gridSize = 1000
local numParticles = 1014
local subSteps = 15
local gravity = 200
local eps = 0.5
local responseCoef = 1.0
local bouncingEnabled = true
local dampingEnabled = true
local dampingMult = 0.999
local maxVelocity = 2000
local mouseDist = 100
local mouseForce = 200000
local smooth = 30

local showMenu = false
local settings = {{"Increase Gravity", function()
    gravity = gravity + 50
end}, {"Decrease Gravity", function()
    gravity = gravity - 50
end}, {"Increase Mouse Force", function()
    mouseForce = mouseForce + 50000
end}, {"Decrease Mouse Force", function()
    mouseForce = mouseForce - 50000
end}, {"Increase Smooth", function()
    smooth = smooth + 5
end}, {"Decrease Smooth", function()
    smooth = smooth - 5
end}}

function love.load()
    math.randomseed(os.time())
    for i = 1, numParticles do
        table.insert(positions, {math.random(radius, gridSize - radius), math.random(radius, gridSize - radius)})
        table.insert(velocities, {0, 0})
    end
    render = require("renderParticles")(function ()
        return radius, numParticles, smooth
    end)
end

function updateParticles(dt)
    local mouseX, mouseY = love.mouse.getPosition()
    for i = 1, #positions do
        local pos = positions[i]
        local vel = velocities[i]

        vel[2] = vel[2] + gravity * dt

        -- Mouse interaction
        if love.mouse.isDown(1) then
            -- Left click to attract particles
            local dx = mouseX - pos[1]
            local dy = mouseY - pos[2]
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist > eps and dist < mouseDist then
                local force = mouseForce / dist
                vel[1] = force * dx * dt
                vel[2] = force * dy * dt
            end
        elseif love.mouse.isDown(2) then
            -- Right click to repel particles
            local dx = mouseX - pos[1]
            local dy = mouseY - pos[2]
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist > eps and dist < mouseDist then
                local force = -mouseForce / dist
                vel[1] = force * dx * dt
                vel[2] = force * dy * dt
            end
        end

        -- Cap maximum velocity
        local speed = math.sqrt(vel[1] * vel[1] + vel[2] * vel[2])
        if speed > maxVelocity then
            vel[1] = vel[1] / speed * maxVelocity
            vel[2] = vel[2] / speed * maxVelocity
        end

        pos[1] = pos[1] + vel[1] * dt
        pos[2] = pos[2] + vel[2] * dt

        -- Boundary conditions
        if pos[1] > gridSize - radius then
            pos[1] = gridSize - radius
            if bouncingEnabled then
                vel[1] = -vel[1]
            else
                vel[1] = 0
            end
        elseif pos[1] < radius then
            pos[1] = radius
            if bouncingEnabled then
                vel[1] = -vel[1]
            else
                vel[1] = 0
            end
        end

        if pos[2] > gridSize - radius then
            pos[2] = gridSize - radius
            if bouncingEnabled then
                vel[2] = -vel[2]
            else
                vel[2] = 0
            end
        elseif pos[2] < radius then
            pos[2] = radius
            if bouncingEnabled then
                vel[2] = -vel[2]
            else
                vel[2] = 0
            end
        end

        -- Apply damping
        if dampingEnabled then
            vel[1] = vel[1] * dampingMult
            vel[2] = vel[2] * dampingMult
        end
    end
end

function love.wheelmoved(x, y)
    if y > 0 then
        mouseDist = mouseDist * 1.25
    else
        mouseDist = mouseDist * 0.8
    end
end

function solveContact(i, j)
    local pos1 = positions[i]
    local pos2 = positions[j]
    local dx = pos1[1] - pos2[1]
    local dy = pos1[2] - pos2[2]
    local distSquared = dx * dx + dy * dy
    local combinedRadius = radius * 2

    if distSquared < (combinedRadius * combinedRadius) and distSquared > eps then
        local dist = math.sqrt(distSquared)
        local delta = responseCoef * 0.5 * (combinedRadius - dist)
        local colVec = {dx / dist * delta, dy / dist * delta}
        pos1[1] = pos1[1] + colVec[1]
        pos1[2] = pos1[2] + colVec[2]
        pos2[1] = pos2[1] - colVec[1]
        pos2[2] = pos2[2] - colVec[2]
    end
end

function solveCollisions()
    for i = 1, #positions - 1 do
        for j = i + 1, #positions do
            solveContact(i, j)
        end
    end
end

function love.update(dt)
    local subDt = dt / subSteps
    for step = 1, subSteps do
        updateParticles(subDt)
        solveCollisions()
    end
end

function love.draw()
    render(positions)
    local mouseX, mouseY = love.mouse.getPosition()
    love.graphics.circle("line", mouseX, mouseY, mouseDist)

    if showMenu then
        local startY = 50
        for i, setting in ipairs(settings) do
            love.graphics.print(setting[1], 50, startY + (i - 1) * 20)
        end
    end
end

function love.keypressed(key)
    if key == "m" then
        showMenu = not showMenu
    elseif key == "escape" then
        love.event.quit()
    end
end

function love.textinput(text)
    if showMenu and tonumber(text) then
        local index = tonumber(text)
        if index > 0 and index <= #settings then
            settings[index][2]()
        end
    end
end
