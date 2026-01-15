local player = {}

-- Создание нового игрока
function player.new(name, isHuman)
    local self = {
        name = name,
        isHuman = isHuman,
        hand = {},  -- Рука игрока (массив карт)
        reinforcements = {}  -- Подкрепления (карты для варгейма)
    }

    -- Добавление карты в руку
    function self:addCardToHand(card)
        table.insert(self.hand, card)
    end

    -- Добавление подкрепления
    function self:addReinforcement(card)
        table.insert(self.reinforcements, card)
    end

    -- Удаление подкрепления по индексу
    function self:removeReinforcement(index)
        if index >= 1 and index <= #self.reinforcements then
            return table.remove(self.reinforcements, index)
        end
        return nil
    end

    -- Получение количества подкреплений
    function self:getReinforcementsCount()
        return #self.reinforcements
    end

    -- Очистка руки и подкреплений
    function self:clear()
        self.hand = {}
        self.reinforcements = {}
    end

    return self
end

return player