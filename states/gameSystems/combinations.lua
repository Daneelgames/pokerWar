local combinations = {}

-- Карта весов рангов для сравнения
local SUIT_ORDER = {
    hearts = 1,
    diamonds = 2,
    clubs = 3,
    spades = 4
}
-- Export suit order for deterministic sorting
combinations.SUIT_ORDER = SUIT_ORDER

local RANK_VALUES = {
    ["2"] = 2, ["3"] = 3, ["4"] = 4, ["5"] = 5, ["6"] = 6,
    ["7"] = 7, ["8"] = 8, ["9"] = 9, ["10"] = 10,
    ["J"] = 11, ["Q"] = 12, ["K"] = 13, ["A"] = 14
}
combinations.RANK_VALUES = RANK_VALUES

-- Типы комбинаций (шаблоны) в порядке возрастания силы
combinations.TYPES = {
    HIGH_CARD = { id = 1, name = "High Card", score = 100 },
    ONE_PAIR = { id = 2, name = "One Pair", score = 200 },
    TWO_PAIR = { id = 3, name = "Two Pair", score = 300 },
    THREE_OF_A_KIND = { id = 4, name = "Three of a Kind", score = 400 },
    STRAIGHT = { id = 5, name = "Straight", score = 500 },
    FLUSH = { id = 6, name = "Flush", score = 600 },
    FULL_HOUSE = { id = 7, name = "Full House", score = 700 },
    FOUR_OF_A_KIND = { id = 8, name = "Four of a Kind", score = 800 },
    STRAIGHT_FLUSH = { id = 9, name = "Straight Flush", score = 900 },
    ROYAL_FLUSH = { id = 10, name = "Royal Flush", score = 1000 }
}

-- Вспомогательная функция для сортировки карт по рангу
local function sortCards(cards)
    table.sort(cards, function(a, b)
        return RANK_VALUES[a.rank] < RANK_VALUES[b.rank]
    end)
    return cards
end

-- Анализ руки (максимум 5 карт)
function combinations.evaluate(cards)
    if #cards == 0 then return nil end
    
    -- Сортируем карты для упрощения анализа
    sortCards(cards)
    
    local ranks = {}
    local suits = {}
    local values = {}
    
    for _, card in ipairs(cards) do
        local r = card.rank
        local s = card.suit
        local v = RANK_VALUES[r]
        
        ranks[r] = (ranks[r] or 0) + 1
        suits[s] = (suits[s] or 0) + 1
        table.insert(values, v)
    end
    
    local isFlush = false
    for s, count in pairs(suits) do
        if count >= 5 then isFlush = true break end
    end
    
    local isStraight = false
    local consecutive = 0
    -- Проверка стрита (учитываем, что values отсортированы)
    -- Но проблема с тузом (A, 2, 3, 4, 5) - здесь A=14.
    -- Упрощенная проверка
    for i = 1, #values - 1 do
        if values[i+1] == values[i] + 1 then
            consecutive = consecutive + 1
        else
            if values[i+1] ~= values[i] then -- если не пара
                consecutive = 0
            end
        end
    end
    if consecutive >= 4 then isStraight = true end
    
    -- Спецпроверка для A-2-3-4-5 (Wheel)
    if not isStraight and values[#values] == 14 then
        -- Проверяем наличие 2,3,4,5
        local has2 = false; local has3 = false; local has4 = false; local has5 = false
        for _, v in ipairs(values) do
            if v == 2 then has2 = true
            elseif v == 3 then has3 = true
            elseif v == 4 then has4 = true
            elseif v == 5 then has5 = true end
        end
        if has2 and has3 and has4 and has5 then isStraight = true end
    end

    -- Подсчет пар/троек/каре
    local pairs_count = 0
    local three = false
    local four = false
    
    for r, count in pairs(ranks) do
        if count == 2 then pairs_count = pairs_count + 1
        elseif count == 3 then three = true
        elseif count == 4 then four = true end
    end
    
    -- Определение комбинации
    if isFlush and isStraight then
        -- Проверка на Royal Flush (если старшая карта A и стрит)
        local hasAce = ranks["A"] and ranks["A"] > 0
        local hasKing = ranks["K"] and ranks["K"] > 0
        if hasAce and hasKing then -- Упрощение, но работает для straight flush с тузом наверху
             return combinations.TYPES.ROYAL_FLUSH
        end
        return combinations.TYPES.STRAIGHT_FLUSH
    end
    
    if four then return combinations.TYPES.FOUR_OF_A_KIND end
    if three and pairs_count >= 1 then return combinations.TYPES.FULL_HOUSE end
    if isFlush then return combinations.TYPES.FLUSH end
    if isStraight then return combinations.TYPES.STRAIGHT end
    if three then return combinations.TYPES.THREE_OF_A_KIND end
    if pairs_count >= 2 then return combinations.TYPES.TWO_PAIR end
    if pairs_count == 1 then return combinations.TYPES.ONE_PAIR end
    
    return combinations.TYPES.HIGH_CARD
end

return combinations