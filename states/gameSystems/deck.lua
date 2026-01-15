local deck = {}
local card = require 'states.gameSystems.card'

-- Создание новой колоды
function deck.new()
    local self = {}

    -- Инициализация колоды с 52 картами
    self.cards = {}
    for _, suit in pairs(card.suits) do
        for _, rank in ipairs(card.ranks) do
            table.insert(self.cards, card.new(suit, rank))
        end
    end

    -- Перетасовка колоды
    function self:shuffle()
        for i = #self.cards, 2, -1 do
            local j = love.math.random(i)
            self.cards[i], self.cards[j] = self.cards[j], self.cards[i]
        end
    end

    -- Взятие карты сверху колоды
    function self:draw()
        if #self.cards > 0 then
            return table.remove(self.cards)
        end

        self.cards = {}
        for _, suit in pairs(card.suits) do
            for _, rank in ipairs(card.ranks) do
                table.insert(self.cards, card.new(suit, rank))
            end
        end

        return table.remove(self.cards)
    end

    -- Количество оставшихся карт
    function self:size()
        return #self.cards
    end

    return self
end

return deck