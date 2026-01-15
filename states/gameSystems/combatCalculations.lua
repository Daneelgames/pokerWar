local combatCalculations = {}
local Combinations = require 'states.gameSystems.combinations'

-- Расчет исхода боя между двумя стеками
-- returns: winner ("attacker" or "defender"), survivors (table of cards)
function combatCalculations.resolveCombat(attackerStack, defenderStack)
    local atkResult = Combinations.evaluate(attackerStack)
    local defResult = Combinations.evaluate(defenderStack)
    
    local atkScore = atkResult and atkResult.score or 0
    local defScore = defResult and defResult.score or 0
    
    print(string.format("Combat! Atk Score: %d (%s) vs Def Score: %d (%s)", 
        atkScore, atkResult and atkResult.name or "None", 
        defScore, defResult and defResult.name or "None"))

    if atkScore > defScore then
        -- Атакующий победил
        local losses = combatCalculations.calculateLosses(atkScore, defScore)
        local survivors = combatCalculations.applyLosses(attackerStack, losses)
        return "attacker", survivors
    elseif defScore > atkScore then
        -- Обороняющийся победил
        local losses = combatCalculations.calculateLosses(defScore, atkScore)
        local survivors = combatCalculations.applyLosses(defenderStack, losses)
        return "defender", survivors
    else
        -- Ничья (в пользу обороняющегося, но с потерями для обоих?)
        -- Для простоты: обороняющийся победил, но потерял половину отряда
        local survivors = combatCalculations.applyLosses(defenderStack, 2)
        return "defender", survivors
    end
end

-- Вычисление количества потерянных карт для победителя
function combatCalculations.calculateLosses(winScore, loseScore)
    local diff = winScore - loseScore
    
    -- Примерная логика:
    -- Если победа с огромным отрывом (например, Straight Flush vs High Card) -> потери 0-1
    -- Если победа минимальная (Pair vs Pair) -> потери 2-3
    
    if diff >= 500 then return 0 end
    if diff >= 300 then return 1 end
    if diff >= 100 then return 2 end
    return 3
end

-- Применение потерь к стеку (удаление самых дешевых карт)
function combatCalculations.applyLosses(stack, numLosses)
    -- Копируем стек, чтобы не менять оригинал раньше времени
    local newStack = {}
    for _, c in ipairs(stack) do table.insert(newStack, c) end
    
    -- Сортируем карты по ценности (как в gameTable)
    table.sort(newStack, function(a, b)
        local rankA = Combinations.RANK_VALUES[a.rank] or 0
        local rankB = Combinations.RANK_VALUES[b.rank] or 0
        if rankA == rankB then
            return (Combinations.SUIT_ORDER[a.suit] or 0) < (Combinations.SUIT_ORDER[b.suit] or 0)
        else
            return rankA < rankB
        end
    end)
    
    -- Удаляем карты с начала (самые дешевые)
    -- Победитель всегда сохраняет хотя бы одну карту
    local actualLosses = math.min(numLosses, #newStack - 1)
    for i = 1, actualLosses do
        table.remove(newStack, 1)
    end
    
    return newStack
end

return combatCalculations
