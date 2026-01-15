local aiPlayer = {}

local Combinations = require 'states.gameSystems.combinations'

-- Оценка ценности размещения карты в конкретный слот
-- Возвращает числовое значение (чем выше, тем лучше)
local function evaluateSlotValue(battlefield, row, col, card, hand)
    if not battlefield[row] then return 0 end
    
    local slotContent = battlefield[row][col]
    local currentCards = {}
    
    -- Собираем текущие карты в слоте
    if slotContent then
        -- Проверка на владельца: ИИ не может ставить карту в слот, занятый игроком
        local firstCard = slotContent.suit and slotContent or slotContent[1]
        if firstCard and firstCard.owner ~= "enemy" then
            return -1 -- Невалидный ход
        end

        if slotContent.suit then
            -- Одна карта (старый формат)
            table.insert(currentCards, slotContent)
        else
            -- Массив карт
            for _, c in ipairs(slotContent) do
                table.insert(currentCards, c)
            end
        end
    end
    
    -- Добавляем новую карту
    table.insert(currentCards, card)
    
    -- Ограничиваем до 5 карт максимум
    if #currentCards > 5 then
        return -1  -- Не можем добавить больше 5 карт (используем -1, чтобы отличить от валидного хода с 0 очков)
    end
    
    -- Оцениваем текущую комбинацию
    local currentCombination = Combinations.evaluate(currentCards)
    local baseScore = currentCombination and currentCombination.score or 0
    
    -- Бонус за потенциал улучшения комбинации
    local potentialBonus = aiPlayer.calculatePotential(currentCards, hand, card)
    
    return baseScore + potentialBonus
end

-- Вычисляет потенциал для улучшения комбинации
function aiPlayer.calculatePotential(currentCards, hand, placedCard)
    local bonus = 0
    
    -- Подсчитываем ранги в текущих картах
    local rankCounts = {}
    local suitCounts = {}
    
    for _, card in ipairs(currentCards) do
        rankCounts[card.rank] = (rankCounts[card.rank] or 0) + 1
        suitCounts[card.suit] = (suitCounts[card.suit] or 0) + 1
    end
    
    -- Проверяем карты в руке на совпадения
    for _, handCard in ipairs(hand) do
        if handCard ~= placedCard then  -- Не учитываем карту, которую уже положили
            -- Бонус за совпадение рангов (потенциал для пары/тройки/каре)
            if rankCounts[handCard.rank] then
                if rankCounts[handCard.rank] == 1 then
                    bonus = bonus + 50  -- Потенциал для пары
                elseif rankCounts[handCard.rank] == 2 then
                    bonus = bonus + 100  -- Потенциал для тройки
                elseif rankCounts[handCard.rank] == 3 then
                    bonus = bonus + 200  -- Потенциал для каре
                end
            end
            
            -- Бонус за совпадение мастей (потенциал для флеша)
            if suitCounts[handCard.suit] then
                if suitCounts[handCard.suit] >= 2 then
                    bonus = bonus + 30  -- Потенциал для флеша
                end
            end
        end
    end
    
    return bonus
end

-- Вспомогательная функция для проверки, занят ли конец колонны ИИ-игроком
local function isColumnBlockedByAI(battlefield, col)
    local lastRow = CONFIG.game.gridRows
    if battlefield[lastRow] and battlefield[lastRow][col] then
        local slot = battlefield[lastRow][col]
        local firstCard = slot.suit and slot or slot[1]
        if firstCard and firstCard.owner == "enemy" then
            return true
        end
    end
    return false
end

-- Выбирает лучший слот для размещения карты
function aiPlayer.chooseBestSlot(battlefield, hand)
    if not hand or #hand == 0 then
        return nil, nil
    end
    
    local cols = CONFIG.game.gridCols
    
    -- 33% шанс сделать полностью случайный, но валидный ход
    if love.math.random() < 0.33 then
        local validMoves = {}
        for cardIndex, card in ipairs(hand) do
            for col = 1, cols do
                -- Проверяем, что колонка не перекрыта в конце и ход валиден
                if not isColumnBlockedByAI(battlefield, col) and evaluateSlotValue(battlefield, 1, col, card, hand) >= 0 then
                    table.insert(validMoves, {cardIndex = cardIndex, col = col})
                end
            end
        end
        
        if #validMoves > 0 then
            local move = validMoves[love.math.random(#validMoves)]
            print("AI logic: Random chaotic move chosen (33% chance)")
            return move.cardIndex, move.col
        end
    end

    -- Находим пустые слоты в первом ряду, исключая заблокированные колонны
    local emptyCols = {}
    for col = 1, cols do
        if not isColumnBlockedByAI(battlefield, col) and battlefield[1][col] == nil then
            table.insert(emptyCols, col)
        end
    end

    -- 50% шанс предпочесть пустые слоты, если они есть
    -- Это заставляет ИИ атаковать по разным направлениям
    local useOnlyEmpty = #emptyCols > 0 and love.math.random() < 0.5
    
    local colsToSearch = {}
    if useOnlyEmpty then
        colsToSearch = emptyCols
    else
        for col = 1, cols do
            -- Добавляем только те колонны, которые не заблокированы в конце
            if not isColumnBlockedByAI(battlefield, col) then
                table.insert(colsToSearch, col)
            end
        end
    end
    
    -- Если после фильтрации не осталось колонок для поиска, пробуем найти хоть что-то валидное
    -- (на случай, если все колонны "заблокированы", но играть надо)
    if #colsToSearch == 0 then
        for col = 1, cols do
            table.insert(colsToSearch, col)
        end
    end
    
    local bestScore = -1
    local bestCardIndex = nil
    local bestCol = nil
    
    -- Перебираем все карты в руке
    for cardIndex, card in ipairs(hand) do
        for _, col in ipairs(colsToSearch) do
            local score = evaluateSlotValue(battlefield, 1, col, card, hand)
            
            if score > bestScore then
                bestScore = score
                bestCardIndex = cardIndex
                bestCol = col
            end
        end
    end
    
    -- Если мы пытались найти только в пустых, но ничего не нашли, 
    -- ищем по всем доступным (не заблокированным) слотам
    if bestScore == -1 and useOnlyEmpty then
        for cardIndex, card in ipairs(hand) do
            for col = 1, cols do
                if not isColumnBlockedByAI(battlefield, col) then
                    local score = evaluateSlotValue(battlefield, 1, col, card, hand)
                    if score > bestScore then
                        bestScore = score
                        bestCardIndex = cardIndex
                        bestCol = col
                    end
                end
            end
        end
    end

    return bestCardIndex, bestCol
end

-- Выполняет ход AI
function aiPlayer.makeMove(battlefield, hand)
    local cardIndex, col = aiPlayer.chooseBestSlot(battlefield, hand)
    
    if cardIndex and col then
        local card = hand[cardIndex]
        print("AI chose " .. card.rank .. " " .. card.suit .. " for column " .. col)
        return cardIndex, col
    end
    
    print("AI can't make a move")
    return nil, nil
end

return aiPlayer
