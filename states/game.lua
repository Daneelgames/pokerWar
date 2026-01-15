local game = {}

-- Загрузка игровых систем
local Deck = require 'states.gameSystems.deck'
local Player = require 'states.gameSystems.player'
local Table = require 'states.gameSystems.gameTable'
local AIPlayer = require 'states.gameSystems.aiPlayer'

-- Загрузка спрайтов мастей для перетаскивания карт
local suitSprites = {
    hearts = love.graphics.newImage("assets/images/hearts.png"),
    diamonds = love.graphics.newImage("assets/images/diamonds.png"),
    clubs = love.graphics.newImage("assets/images/clubs.png"),
    spades = love.graphics.newImage("assets/images/spades.png")
}

--[[LOVE LOAD]]
function game:init()
    -- Game initialization
    print("Game init")

    -- Настройки скейлинга
    self.canvasWidth = 800
    self.canvasHeight = 600
    self.canvas = love.graphics.newCanvas(self.canvasWidth, self.canvasHeight)
    self:updateScaling()

    -- Состояние перетаскивания карт
    self.draggedCard = nil
    self.draggedCardIndex = nil
    self.dragOffsetX = 0
    self.dragOffsetY = 0
    
    -- Управление ходами
    self.currentTurn = "player"  -- "player" или "enemy"

    -- Поле боя - сетка 5x5 для размещения карт
    self.battlefield = {}
    for row = 1, 5 do
        self.battlefield[row] = {}
        for col = 1, 5 do
            self.battlefield[row][col] = nil  -- nil означает пустой слот
        end
    end

    -- Создание колоды и тасование
    self.deck = Deck.new()
    self.deck:shuffle()

    -- Создание игроков
    self.player = Player.new("Игрок", true)
    self.enemy = Player.new("Компьютер", false)

    -- Раздача 5 карт каждому игроку в качестве подкреплений
    for i = 1, 5 do
        local playerCard = self.deck:draw()
        if playerCard then
            self.player:addReinforcement(playerCard)
        end

        local enemyCard = self.deck:draw()
        if enemyCard then
            self.enemy:addReinforcement(enemyCard)
        end
    end

    -- Создание стола и установка игроков
    self.table = Table.new(self.canvasWidth, self.canvasHeight)
    self.table:setPlayers(self.player, self.enemy)

    print("Game initialized!")
    print("Player received " .. self.player:getReinforcementsCount() .. " reinforcements")
    print("Enemy received " .. self.enemy:getReinforcementsCount() .. " reinforcements")
end

--[[LOVE UPDATE]]
function game:update(dt)
    -- Обновление состояния игроков (анимации)
    if self.player then self.player:update(dt) end
    if self.enemy then self.enemy:update(dt) end
end

-- Обновление скейлинга при изменении размера окна
function game:updateScaling()
    local windowWidth, windowHeight = love.graphics.getDimensions()
    self.scaleX = windowWidth / self.canvasWidth
    self.scaleY = windowHeight / self.canvasHeight
    -- Используем минимальный масштаб для сохранения пропорций
    self.scale = math.min(self.scaleX, self.scaleY)
    -- Центрирование canvas на экране
    self.offsetX = (windowWidth - self.canvasWidth * self.scale) / 2
    self.offsetY = (windowHeight - self.canvasHeight * self.scale) / 2
end

-- Обновление скейлинга при изменении размера окна
function game:resize(w, h)
    self:updateScaling()
end

-- Получение позиции мыши относительно canvas
function game:getMouseCanvasPosition()
    local mouseX, mouseY = love.mouse.getPosition()
    -- Преобразуем экранные координаты в координаты canvas
    local canvasMouseX = (mouseX - self.offsetX) / self.scale
    local canvasMouseY = (mouseY - self.offsetY) / self.scale
    return canvasMouseX, canvasMouseY
end

-- Проверка попадания точки в прямоугольник
function game:pointInRect(x, y, rectX, rectY, rectWidth, rectHeight)
    return x >= rectX and x <= rectX + rectWidth and y >= rectY and y <= rectY + rectHeight
end

-- Получение ближайшего ряда слотов к игроку (нижний ряд сетки)
function game:getPlayerFrontRowSlots()
    -- Используем те же значения, что и в gameTable.lua
    local gridRows = self.table.tableConfig.gridRows
    local gridCols = self.table.tableConfig.gridCols
    local gridSlotSize = self.table.tableConfig.gridSlotSize
    local gridSpacing = self.table.tableConfig.gridSpacing
    local gridStartY = self.table.tableConfig.gridStartY

    local gridTotalWidth = gridCols * gridSlotSize + (gridCols - 1) * gridSpacing
    local gridStartX = (self.canvasWidth - gridTotalWidth) / 2

    local slots = {}
    for col = 1, gridCols do
        local x = gridStartX + (col - 1) * (gridSlotSize + gridSpacing)
        local y = gridStartY + (gridRows - 1) * (gridSlotSize + gridSpacing)  -- Нижний ряд (ближайший к игроку)
        table.insert(slots, {x = x, y = y, width = gridSlotSize, height = gridSlotSize, col = col})
    end


    return slots
end

-- Размещение карты на поле боя
-- Размещение карты на поле боя
function game:addCardToBattlefield(row, col, card)
    if not self.battlefield[row] then return end

    if self.battlefield[row][col] == nil then
        self.battlefield[row][col] = {card}
        print("New squad created at " .. row .. ", " .. col)
    else
        -- Если там уже лежит карта (в старом формате) или массив карт
        local slotContent = self.battlefield[row][col]
        
        -- Safe check if it's a single card (legacy or fallback)
        if slotContent.suit then
             self.battlefield[row][col] = {slotContent, card}
        else
             -- It is already a list
             table.insert(self.battlefield[row][col], card)
        end
        print("Card added to squad at " .. row .. ", " .. col)
    end
end

--[[LOVE KEYPRESS DETECTION]]
function game:keypressed(keypressed)
    -- Quit the game if you press escape
    if keypressed == "escape" then love.event.quit() end
    -- Toggle fullscreen if you press F11
    if keypressed == "f11" then
        love.window.setFullscreen(not love.window.getFullscreen())
        -- Обновляем скейлинг после изменения режима окна
        self:updateScaling()
    end

    -- Дополнительные клавиши для тестирования
    if keypressed == "r" then
        -- Перезапуск игры
        self:init()
    end
end

-- Обработка нажатия мыши
function game:mousepressed(x, y, button)
    if button == 1 and not self.draggedCard then  -- Левая кнопка мыши
        local canvasX, canvasY = self:getMouseCanvasPosition()

        -- Проверяем карты игрока
        if self.player and self.player.reinforcements then
            -- Используем те же значения, что и в gameTable.lua
            local cardWidth = self.table.tableConfig.cardWidth
            local cardHeight = self.table.tableConfig.cardHeight
            local cardSpacing = self.table.tableConfig.cardSpacing
            local playerY = self.table.tableConfig.playerY

            local playerCards = self.player:getReinforcementsCount()
            local totalWidth = playerCards * cardWidth + (playerCards - 1) * cardSpacing
            local startX = (self.canvasWidth - totalWidth) / 2

            for i = 1, playerCards do
                local cardX = startX + (i - 1) * (cardWidth + cardSpacing)
                local cardY = playerY

                if self:pointInRect(canvasX, canvasY, cardX, cardY, cardWidth, cardHeight) then
                    -- Захватываем карту
                    self.draggedCard = self.player.reinforcements[i]
                    self.draggedCardIndex = i
                    self.dragOffsetX = canvasX - cardX
                    self.dragOffsetY = canvasY - cardY
                    break
                end
            end
        end
    end
end

-- Обработка отпускания мыши
function game:mousereleased(x, y, button)
    if button == 1 and self.draggedCard and self.currentTurn == "player" then  -- Левая кнопка мыши и ход игрока
        local canvasX, canvasY = self:getMouseCanvasPosition()

        -- Проверяем, находится ли курсор над слотами нижнего ряда
        local frontRowSlots = self:getPlayerFrontRowSlots()
        local droppedInSlot = false

        for _, slot in ipairs(frontRowSlots) do
            if self:pointInRect(canvasX, canvasY, slot.x, slot.y, slot.width, slot.height) then
                -- Проверяем, не переполнен ли слот (макс. 5 карт)
                local playerRow = self.table.tableConfig.gridRows
                local currentStack = self.battlefield[playerRow][slot.col]
                if currentStack and #currentStack >= 5 then
                    print("Slot column " .. slot.col .. " is full (5 cards max)")
                    break -- Выходим из цикла, droppedInSlot останется false, карта вернется в руку
                end

                -- Card successfully dropped in slot
                print("Card dropped in slot column " .. slot.col)

                -- Add card to battlefield
                self:addCardToBattlefield(playerRow, slot.col, self.draggedCard)

                -- Remove card from player's hand
                table.remove(self.player.reinforcements, self.draggedCardIndex)

                droppedInSlot = true

                -- pass turn to opponent in func playerEndsTurn
                self:playerEndsTurn()
                break
            end
        end

        if not droppedInSlot then
            print("Card returned to hand")
        end

        -- Always reset dragged card state after mouse release
        self.draggedCard = nil
        self.draggedCardIndex = nil
        self.dragOffsetX = 0
        self.dragOffsetY = 0
    end
end

function game:playerEndsTurn()
    -- Передаем ход противнику
    self.currentTurn = "enemy"
    print("\n=== AI Turn ===")
    
    local playerCard = self.deck:draw()
    if playerCard then
        self.player:addReinforcement(playerCard)
        -- shake player cards in hand
        self.player:shakeCards()
    end
    -- AI делает ход
    local cardIndex, col = AIPlayer.makeMove(self.battlefield, self.enemy.reinforcements)
    
    if cardIndex and col then
        local card = self.enemy.reinforcements[cardIndex]
        
        -- Добавляем карту на поле боя в верхний ряд (row 1)
        self:addCardToBattlefield(1, col, card)
        
        -- Удаляем карту из руки AI
        table.remove(self.enemy.reinforcements, cardIndex)
        
        print("AI placed card in row 1, column " .. col)
        local enemyCard = self.deck:draw()
        if enemyCard then
            self.enemy:addReinforcement(enemyCard)
            -- shake enemy cars in hand
            self.enemy:shakeCards()
        end
    else
        print("AI can't make a move")
    end
    -- Возвращаем ход игроку
    self.currentTurn = "player"
    print("=== Player's Turn ===")
end

-- Обработка движения мыши
function game:mousemoved(x, y, dx, dy)
    -- Ничего не делаем, перетаскивание обрабатывается в draw()
end

--[[LOVE DRAW]]
function game:draw()
    -- Рисуем в canvas с фиксированным разрешением
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(0, 0, 0, 0) -- Прозрачный фон canvas

    -- Отрисовка стола с картами (передаем информацию о перетаскиваемой карте и поле боя)
    if self.table then
        self.table:draw(self.draggedCard, self.draggedCardIndex, self.draggedCard ~= nil, self.battlefield)
    end

    -- Отрисовка перетаскиваемой карты
    if self.draggedCard then
        local mouseX, mouseY = self:getMouseCanvasPosition()
        local cardX = mouseX - self.dragOffsetX
        local cardY = mouseY - self.dragOffsetY

        -- Используем размеры из TABLE_CONFIG
        local cardWidth = 60  -- TABLE_CONFIG.cardWidth
        local cardHeight = 60 -- TABLE_CONFIG.cardHeight (обновлено)

        -- Рисуем карту в позиции курсора
        self.draggedCard:draw(cardX, cardY, self.table.tableConfig, self.table.suitSprites)
    end

    -- Отрисовка инструкций
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(Fonts.regular[12])
    love.graphics.print("R - Перезапуск игры", 10, self.canvasHeight - 140)
    love.graphics.print("ESC - Выход", 10, self.canvasHeight - 120)

    -- Возвращаемся к основному canvas
    love.graphics.setCanvas()

    -- Выводим canvas с масштабированием
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.canvas, self.offsetX, self.offsetY, 0, self.scale, self.scale)
end

return game
