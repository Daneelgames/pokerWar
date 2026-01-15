local tooltip = {}

function tooltip.new()
    local self = {
        text = "",
        x = 0,
        y = 0,
        visible = false,
        padding = 10,
        maxWidth = 200,
        backgroundColor = {0, 0, 0, 0.8},
        textColor = {1, 1, 1, 1},
        titleColor = {1, 0.8, 0, 1}
    }

    function self:set(text, x, y)
        self.text = text
        self.x = x
        self.y = y
        self.visible = true
    end

    function self:hide()
        self.visible = false
    end

    function self:draw()
        if not self.visible or self.text == "" then return end

        local font = Fonts.regular[12]
        local boldFont = Fonts.bold[14]
        
        -- Разбиваем текст на заголовок и описание если есть переносы
        local lines = {}
        for line in self.text:gmatch("[^\n]+") do
            table.insert(lines, line)
        end

        local totalHeight = 0
        local maxW = 0
        
        for i, line in ipairs(lines) do
            local f = (i == 1) and boldFont or font
            maxW = math.max(maxW, f:getWidth(line))
            totalHeight = totalHeight + f:getHeight() + 2
        end

        local bgW = maxW + self.padding * 2
        local bgH = totalHeight + self.padding * 2
        
        -- Позиционирование (смещаем чтобы не было под курсором)
        local drawX = self.x + 15
        local drawY = self.y + 15
        
        -- Проверка границ экрана (упрощенно)
        if drawX + bgW > 800 then drawX = self.x - bgW - 5 end
        if drawY + bgH > 600 then drawY = self.y - bgH - 5 end

        -- Рисуем фон
        love.graphics.setColor(self.backgroundColor)
        love.graphics.rectangle("fill", drawX, drawY, bgW, bgH, 5, 5)
        
        -- Рисуем рамку
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.rectangle("line", drawX, drawY, bgW, bgH, 5, 5)

        -- Рисуем текст
        local currentY = drawY + self.padding
        for i, line in ipairs(lines) do
            if i == 1 then
                love.graphics.setColor(self.titleColor)
                love.graphics.setFont(boldFont)
            else
                love.graphics.setColor(self.textColor)
                love.graphics.setFont(font)
            end
            love.graphics.print(line, drawX + self.padding, currentY)
            currentY = currentY + love.graphics.getFont():getHeight() + 2
        end
    end

    return self
end

return tooltip
