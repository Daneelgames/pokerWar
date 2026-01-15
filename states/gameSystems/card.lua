local card = {}

-- Metatable для объектов карт
local card_mt = {
    __index = card
}

-- Масти карт
card.suits = {
    hearts = "hearts",      -- Червы (красные)
    diamonds = "diamonds",  -- Бубны (красные)
    clubs = "clubs",        -- Крести (черные)
    spades = "spades"       -- Пики (черные)
}

-- Номиналы карт
card.ranks = {
    "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"
}

-- Цвета мастей
card.suitColors = {
    hearts = {1, 0.2, 0.2},    -- Красный
    diamonds = {1, 0.2, 0.2},  -- Красный
    clubs = {0.2, 0.2, 0.2},   -- Черный
    spades = {0.2, 0.2, 0.2}   -- Черный
}

-- Создание новой карты
function card.new(suit, rank)
    local newCard = {
        suit = suit,
        rank = rank,
        color = card.suitColors[suit]
    }
    setmetatable(newCard, card_mt)
    return newCard
end

-- Метод для получения текстового представления карты
function card:toString()
    return self.rank .. " of " .. self.suit
end

-- Метод для получения короткого текстового представления (для отладки)
function card:toShortString(self)
    return self.rank .. " of " .. self.suit
end

-- Тинты для разных владельцев карт
card.ownerTints = {
    player = {0.8, 0.8, 1},    -- Синеватый для игрока
    enemy = {1, 0.8, 0.8},     -- Красный для AI
    player2 = {0.9, 1, 0.9}    -- Зеленый для второго игрока
}

-- Метод для отрисовки карты
function card:draw(x, y, table_config, suit_sprites)
    -- Определяем цвет фона карты в зависимости от владельца
    local tint = {1, 1, 1}
    if self.owner and card.ownerTints[self.owner] then
        tint = card.ownerTints[self.owner]
    end

    love.graphics.setColor(tint)  -- Card background with tint
    love.graphics.rectangle("fill", x, y, table_config.cardWidth, table_config.cardHeight, 5, 5)

    love.graphics.setColor(0, 0, 0)  -- Black border
    love.graphics.rectangle("line", x, y, table_config.cardWidth, table_config.cardHeight, 5, 5)

    -- Draw card rank
    love.graphics.setColor(self.color)
    local font = Fonts.regular[16]
    love.graphics.setFont(font)
    local text = self.rank
    local textWidth = font:getWidth(text)
    local textY = y 
    love.graphics.print(text, x + 2, textY)

    -- Draw suit sprite
    love.graphics.setColor(1, 1, 1)
    local spriteSize = 20
    local spriteX = x + 38
    local spriteY = y
    love.graphics.draw(suit_sprites[self.suit], spriteX, spriteY, 0, spriteSize / suit_sprites[self.suit]:getWidth(), spriteSize / suit_sprites[self.suit]:getHeight())
end

return card