anim8 = require 'lib/anim8'
camera = require 'lib/camera'
suit = require 'lib/suit'

function love.load()
    colorBlack	=	{normal = {bg = {71,134,206}, fg = {0,0,0}}}
    colorRed	=	{normal = {bg = {71,134,206}, fg = {255,0,0}}}

    love.graphics.setDefaultFilter("nearest", "nearest")
    math.randomseed(os.time())

    --font sizes
    sm = love.graphics.newFont(12)
    md = love.graphics.newFont(18)
    lg = love.graphics.newFont(36)

    beavers = {}
    winner = nil
    beaverInit = false

    numBeavers = 0
    minBeavers = 1
    maxBeavers = 100

    raceLength = 0
    minTime = 1
    maxTime = 300

    beaverSpacing = 0
    raceStart = false

    cam = camera()

    -- audio
    sounds = {}
    sounds.river = love.audio.newSource("audio/stream1.ogg", "static")
    sounds.river:setLooping(true)
    sounds.river:play()

    inputBeavers = {}
    inputBeavers.text = ""
    inputBeavers.visible = true
    inputBeavers.error = ""
    inputBeavers.set = false

    inputTime = {}
    inputTime.text = ""
    inputTime.visible = true
    inputTime.error = ""
    inputTime.set = false

    screenHeight = love.graphics.getHeight()
    screenWidth = love.graphics.getWidth()

    -- UI stuff
    showUI = true
    showStartMenu = true
    start = false
    startError = ""
    uiWidth = 200
    uiX = screenWidth/2 - uiWidth/2
    uiY = 100

    background = {}
    background.spriteSheet = love.graphics.newImage('sprites/Ocean_SpriteSheet.png')
    background.grid = anim8.newGrid(32,32, background.spriteSheet:getWidth(), background.spriteSheet:getHeight())
    background.animations = {}
    background.animations.anim = anim8.newAnimation(background.grid('1-8',2),0.2)

    time = {}
    time.start = 0
    time.stop = 0

    -- suit.theme.color.normal = {bg = {255, 255, 255}, fg = {255, 255, 255}}
    -- suit.theme.color.hovered = {bg = {0, 0, 0}, fg = {255, 255, 255}}
    -- suit.theme.color.active = {bg = {0, 0, 0}, fg = {255, 255, 255}} 
end

function love.update(dt)

    if showStartMenu then
        startMenu()
    end
    if showResetButton then
        resetButton()
    end
    -- TODO:: add a quit game button

    if raceStart and love.timer.getTime() < time.stop then
        max = -1
        for i,beaver in ipairs(beavers) do
            beaver.x = beaver.x + love.math.random(.01, .09)*5
            if beaver.x > max then
                winner = beaver
                max = beaver.x
                cam:lookAt(beaver.x -200, screenHeight/2)
            end
            beaver.animations.right:update(dt)
        end
    elseif raceStart and love.timer.getTime() >= time.stop then
        cam:lookAt(winner.x -200, screenHeight/2)
        winner.animations.right:update(dt)
        winner.x = winner.x + 0.5
    end
    background.animations.anim:update(dt)
end

function love.draw()
    love.graphics.setFont(md)

    --drawing background
    for i = 0, screenWidth/64 do
        for j = 0, screenHeight/64 do
            background.animations.anim:draw(background.spriteSheet,i*64,j*64, nil, 2)
        end
    end

    cam:attach()
    for i=1,#beavers do
        local beaver = beavers[i]
        beaver.animations.right:draw(beaver.spriteSheet, beaver.x, beaver.y, nil, beaver.scale, nil, 200, 32)
        love.graphics.print(beaver.name, beaver.x-325, beaver.y+20)
    end
    cam:detach()

    -- Draw start menu on black background
    if showStartMenu then
        love.graphics.setColor(0,0,0,50)
        love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight);
        love.graphics.setColor(255,255,255,255)
        suit.draw()
    end
    if showResetButton then
        suit.draw()
    end

    -- When race is over
    if raceStart and love.timer.getTime() >= time.stop then
        love.graphics.setColor(255,255,0,255)
        love.graphics.setFont(lg)
        love.graphics.print("Number " .. winner.name .. " is the winner!", screenWidth/2, 10)


        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.setFont(md)
        showResetButton = true
    end

    --TODO: draw timer on screen, (current time - start time)
        -- love.graphics.print(tostring(love.timer.getTime() - time.start), screenWidth/2, 10)
end

function love.keypressed(key)
    suit.keypressed(key)
end

function love.textinput(t)
    suit.textinput(t)
end

function newBeaver(y, name)
    local beaver = {}
    beaver.y = y
    beaver.x = 500
    beaver.scale = 2
    beaver.scale = 2
    beaver.speed = 1
    beaver.name = name
    beaver.spriteSheet = love.graphics.newImage('sprites/beaver-NESW-rgb.png')
    beaver.grid = anim8.newGrid(64, 64, beaver.spriteSheet:getWidth(), beaver.spriteSheet:getHeight())
    beaver.animations = {}
    beaver.animations.right = anim8.newAnimation(beaver.grid('1-3', 2), 0.2)
    beaver.animations.right:gotoFrame(love.math.random(1,3))
    table.insert(beavers,beaver)
end

function initBeavers(numBeavers)
    newBeaver(50, 1)
    winner = beavers[1]
    for i=1,numBeavers-1 do
        newBeaver(beavers[#beavers].y + beaverSpacing, tostring(i+1))
    end
    beaverInit = true
end

--TODO: need some kind of beaver destructor that clears the beaver list thing table whatever
function clearBeavers()
    for i in pairs(beavers) do
        beavers[i] = nil
    end
end

function startMenu()
    -- Input Boxes
    suit.Label("Number of Beavers:", {align="center"}, uiX, uiY, uiWidth,30) 
    suit.Input(inputBeavers, uiX,uiY +25,uiWidth,30)
    suit.Label(inputBeavers.error, {align="center", color = colorRed}, uiX, uiY+50,uiWidth,30) 

    suit.Label("Race Length:", {align="center"}, uiX, uiY+125, uiWidth, 30)
    suit.Input(inputTime, uiX, uiY+150, uiWidth, 30)
    suit.Label(inputTime.error, {align="center", color = colorRed}, uiX, uiY+175,uiWidth,30) 

    -- Start Button
    if suit.Button("Start", uiX, uiY+275, uiWidth, 30).hit then
        numBeavers = tonumber(inputBeavers.text)
        if numBeavers == nil or numBeavers > maxBeavers or numBeavers < minBeavers then
            inputBeavers.error = "number of beavers must be beween " .. minBeavers .. " and " .. maxBeavers
            inputBeavers.set = false
        else
            inputBeavers.set = true
            inputBeavers.error = ""
        end

        raceLength = tonumber(inputTime.text)
        if raceLength == nil or raceLength > maxTime or raceLength < minTime then
            inputTime.error = "race time must be between " .. minTime .. " and " .. maxTime .. " seconds"
            inputTime.set = false
        else
            inputTime.set = true
            inputTime.error = ""
        end

        if inputTime.set and inputBeavers.set then
            --TODO: add horn sound effect for race start
            showStartMenu = false
            startError = ""
            time.start = love.timer.getTime()
            time.stop = time.start + raceLength
            raceStart = true

            --TODO: fix beaver spacing
            beaverSpacing = (screenHeight-120) / numBeavers
            initBeavers(numBeavers)
        else
            startError = "enter number of beavers and race time"
        end

    end
    suit.Label(startError, {align = "center", color = colorRed}, uiX, uiY+300, uiWidth, 30)
end

function resetButton()
    if suit.Button("Race Again", uiX, screenHeight/2, uiWidth, 30).hit then
        clearBeavers()
        raceStart = false
        showStartMenu = true
        showResetButton = false
    end
end