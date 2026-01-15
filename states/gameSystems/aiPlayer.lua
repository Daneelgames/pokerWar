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

-- Выбирает лучший слот для размещения карты
function aiPlayer.chooseBestSlot(battlefield, hand)
    if not hand or #hand == 0 then
        return nil, nil
    end
    
    local bestScore = -1
    local bestCardIndex = nil
    local bestCol = nil
    
    -- Перебираем все карты в руке
    for cardIndex, card in ipairs(hand) do
        -- Перебираем все колонки в первом ряду (ближайший к AI)
        for col = 1, 5 do
            local score = evaluateSlotValue(battlefield, 1, col, card, hand)
            
            if score > bestScore then
                bestScore = score
                bestCardIndex = cardIndex
                bestCol = col
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
