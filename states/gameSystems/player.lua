local player = {}

-- Создание нового игрока
function player.new(name, isHuman)
    local self = {
        name = name,
        isHuman = isHuman,
        hand = {},  -- Рука игрока (массив карт)
        reinforcements = {},  -- Подкрепления (карты для варгейма)
        
        -- Animation state
        isShaking = false,
        shakeTimer = 0,
        shakeDuration = 0.2,
        shakeIntensity = 2
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

    -- Запуск анимации тряски карт
    function self:shakeCards()
        self.isShaking = true
        self.shakeTimer = self.shakeDuration
    end

    -- Обновление состояния игрока (анимации)
    function self:update(dt)
        if self.isShaking then
            self.shakeTimer = self.shakeTimer - dt
            if self.shakeTimer <= 0 then
                self.isShaking = false
                self.shakeTimer = 0
            end
        end
    end

    -- Получение смещения для эффекта тряски
    function self:getShakeOffset()
        if not self.isShaking then return 0, 0 end
        
        local dx = (love.math.random() - 0.5) * 2 * self.shakeIntensity
        local dy = (love.math.random() - 0.5) * 2 * self.shakeIntensity
        return dx, dy
    end

    return self
end

return player