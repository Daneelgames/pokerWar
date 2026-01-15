local gameTable = {}

-- Загрузка спрайтов мастей
local suitSprites = {
    hearts = love.graphics.newImage("assets/images/hearts.png"),
    diamonds = love.graphics.newImage("assets/images/diamonds.png"),
    clubs = love.graphics.newImage("assets/images/clubs.png"),
    spades = love.graphics.newImage("assets/images/spades.png")
}

local Card = require 'states.gameSystems.card'
local combinations = require 'states.gameSystems.combinations'

-- Настройки стола
local TABLE_CONFIG = {
    cardWidth = 60,
    cardHeight = 60,
    cardSpacing = 20,
    tableMargin = 20,
    playerY = 500,  -- Позиция карт игрока (нижняя часть)
    enemyY = 20,    -- Позиция карт противника (верхняя часть)

    -- Настройки сетки поля боя
    gridRows = 5,
    gridCols = 5,
    gridSlotSize = 60,
    gridSpacing = 20,
    gridStartY = 100  -- Начало сетки по Y (между enemyY и playerY)
}

-- Создание нового стола
function gameTable.new(canvasWidth, canvasHeight)
    local self = {
        player = nil,
        enemy = nil,
        canvasWidth = canvasWidth or 800,
        canvasHeight = canvasHeight or 600,
        tableConfig = TABLE_CONFIG,
        suitSprites = suitSprites
    }

    -- Установка игроков
    function self:setPlayers(player, enemy)
        self.player = player
        self.enemy = enemy
    end


    -- Отрисовка скрытой карты (для противника)
    local function drawHiddenCard(x, y)
        love.graphics.setColor(0.3, 0.3, 0.3)  -- Серый фон для скрытых карт
        love.graphics.rectangle("fill", x, y, TABLE_CONFIG.cardWidth, TABLE_CONFIG.cardHeight, 5, 5)

        love.graphics.setColor(0, 0, 0)  -- Черная рамка
        love.graphics.rectangle("line", x, y, TABLE_CONFIG.cardWidth, TABLE_CONFIG.cardHeight, 5, 5)

        -- Символ вопроса для скрытых карт
        love.graphics.setColor(1, 1, 1)
        local font = Fonts.bold[20]
        love.graphics.setFont(font)
        local text = "?"
        local textWidth = font:getWidth(text)
        local textHeight = font:getHeight()
        local textX = x + (TABLE_CONFIG.cardWidth - textWidth) / 2
        local textY = y + (TABLE_CONFIG.cardHeight - textHeight) / 2
        love.graphics.print(text, textX, textY)
    end

    -- Отрисовка сетки поля боя
    local function drawBattleGrid(isDraggingCard)
        -- Рассчитываем общую ширину сетки
        local gridTotalWidth = TABLE_CONFIG.gridCols * TABLE_CONFIG.gridSlotSize +
                              (TABLE_CONFIG.gridCols - 1) * TABLE_CONFIG.gridSpacing
        local gridStartX = (self.canvasWidth - gridTotalWidth) / 2

        for row = 1, TABLE_CONFIG.gridRows do
            for col = 1, TABLE_CONFIG.gridCols do
                local x = gridStartX + (col - 1) * (TABLE_CONFIG.gridSlotSize + TABLE_CONFIG.gridSpacing)
                local y = TABLE_CONFIG.gridStartY + (row - 1) * (TABLE_CONFIG.gridSlotSize + TABLE_CONFIG.gridSpacing)

                -- Определяем цвет слота: подсвечиваем нижний ряд (ближайший к игроку) если карта перетаскивается
                if isDraggingCard and row == TABLE_CONFIG.gridRows then
                    -- Подсветка нижнего ряда (ярко-желтый)
                    love.graphics.setColor(1, 1, 0, 0.6)
                else
                    -- Обычный цвет для остальных слотов
                    love.graphics.setColor(0.8, 0.8, 0.8, 0.3)
                end

                -- Фон слота
                love.graphics.rectangle("fill", x, y, TABLE_CONFIG.gridSlotSize, TABLE_CONFIG.gridSlotSize, 3, 3)

                -- Рамка слота
                if isDraggingCard and row == TABLE_CONFIG.gridRows then
                    love.graphics.setColor(1, 1, 0, 1)  -- Ярко-желтая рамка для нижнего ряда
                else
                    love.graphics.setColor(0.6, 0.6, 0.6, 0.8)  -- Обычная рамка
                end
                love.graphics.rectangle("line", x, y, TABLE_CONFIG.gridSlotSize, TABLE_CONFIG.gridSlotSize, 3, 3)
            end
        end
    end

    -- Отрисовка карт на поле боя
    local function drawBattlefieldCards(battlefield)
        -- Рассчитываем общую ширину сетки
        local gridTotalWidth = TABLE_CONFIG.gridCols * TABLE_CONFIG.gridSlotSize +
                              (TABLE_CONFIG.gridCols - 1) * TABLE_CONFIG.gridSpacing
        local gridStartX = (self.canvasWidth - gridTotalWidth) / 2

        for row = 1, TABLE_CONFIG.gridRows do
            for col = 1, TABLE_CONFIG.gridCols do
                local slotContent = battlefield[row] and battlefield[row][col]
                if slotContent then
                    -- Support both single card (legacy) and list of cards (squad)
                    local stack = slotContent
                    -- Check if it's a single card object (has 'suit' field)
                    if stack.suit then
                        stack = {stack}
                    end
                    -- Sort cards in ascending rank order (low → high) so highest appears on top
                    if #stack > 1 then
                        table.sort(stack, function(a, b)
                        local rankA = combinations.RANK_VALUES[a.rank] or 0
                        local rankB = combinations.RANK_VALUES[b.rank] or 0
                        if rankA == rankB then
                            return (combinations.SUIT_ORDER[a.suit] or 0) < (combinations.SUIT_ORDER[b.suit] or 0)
                        else
                            return rankA < rankB
                        end
                        end)
                    end

                    local slotX = gridStartX + (col - 1) * (TABLE_CONFIG.gridSlotSize + TABLE_CONFIG.gridSpacing)
                    local slotY = TABLE_CONFIG.gridStartY + (row - 1) * (TABLE_CONFIG.gridSlotSize + TABLE_CONFIG.gridSpacing)

                    local stackOffset = 16 -- Offset for stacked cards
                    
                    for i, card in ipairs(stack) do
                        -- Draw card with offset
                        -- local cardX = slotX + (i - 1) * stackOffset
                        local cardX = slotX
                        local cardY = slotY + (i - 1) * stackOffset
                        
                        -- Рисуем карту
                        card:draw(cardX, cardY, self.tableConfig, self.suitSprites)
                    end
                end
            end
        end
    end

    -- Отрисовка стола
    function self:draw(draggedCard, draggedCardIndex, isDraggingCard, battlefield)
        love.graphics.clear(0.1, 0.5, 0.1)  -- Зеленый фон стола

        if not self.player or not self.enemy then
            return
        end

        -- Отрисовка сетки поля боя
        drawBattleGrid(isDraggingCard)

        -- Отрисовка карт на поле боя
        if battlefield then
            drawBattlefieldCards(battlefield)
        end

        -- Отрисовка подкреплений противника (скрытые карты)
        local enemyCards = self.enemy:getReinforcementsCount()
        local totalWidth = enemyCards * TABLE_CONFIG.cardWidth + (enemyCards - 1) * TABLE_CONFIG.cardSpacing
        local startX = (self.canvasWidth - totalWidth) / 2

        for i = 1, enemyCards do
            local x = startX + (i - 1) * (TABLE_CONFIG.cardWidth + TABLE_CONFIG.cardSpacing)
            drawHiddenCard(x, TABLE_CONFIG.enemyY)
        end

        -- Отрисовка подкреплений игрока (видимые карты), исключая перетаскиваемую
        local playerCards = self.player:getReinforcementsCount()
        totalWidth = playerCards * TABLE_CONFIG.cardWidth + (playerCards - 1) * TABLE_CONFIG.cardSpacing
        startX = (self.canvasWidth - totalWidth) / 2

        for i, card in ipairs(self.player.reinforcements) do
            if card then -- Check if card is not nil
                if not draggedCardIndex or i ~= draggedCardIndex then
                    local x = startX + (i - 1) * (self.tableConfig.cardWidth + self.tableConfig.cardSpacing)
                    card:draw(x, self.tableConfig.playerY, self.tableConfig, self.suitSprites)
                end
            else
                -- This should not happen if table.remove works correctly, but for safety:
                print(string.format("Player reinforcement %d is nil. This indicates a potential logic error.", i))
            end
        end

        -- Отрисовка текста с количеством карт
        love.graphics.setColor(1, 1, 1)
        local font = Fonts.regular[14]
        love.graphics.setFont(font)

        -- Текст для противника
        local enemyText = "Enemy: " .. enemyCards .. " reinforcements"
        love.graphics.print(enemyText, TABLE_CONFIG.tableMargin, TABLE_CONFIG.enemyY - 25)

        -- Текст для игрока
        local playerText = "Player: " .. playerCards .. " reinforcements"
        love.graphics.print(playerText, TABLE_CONFIG.tableMargin, TABLE_CONFIG.playerY + TABLE_CONFIG.cardHeight + 5)
    end

    return self
end

return gameTable