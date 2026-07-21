--Contents\mods\LivingBooks\42\media\lua\shared\LivingBooksSystemShared\LivingBooksPaginator.lua
-- Lógica de paginación PURA (sin estado de UI), compartida entre:
--   - LivingBooksReader.lua      (construcción perezosa, por lotes, como red
--                          de seguridad si no hubo precarga)
--   - LivingBooksPreloader   (construcción completa de una sola vez, al
--                          arrancar la partida)
-- Vive en "shared" porque no depende de nada específico de un panel de
-- UI concreto, solo de getTextManager() (disponible en cliente).
--------------------------------------------------------------------------

BookPaginator = {}

-- Envuelve un texto en líneas que quepan en maxWidth con la fuente dada.
function BookPaginator.wrapText(text, maxWidth, font)

    local lines = {}
    local line = ""

    for word in text:gmatch("%S+") do

        local test = (line == "") and word or (line .. " " .. word)

        if getTextManager():MeasureStringX(font, test) > maxWidth then
            table.insert(lines, line)
            line = word
        else
            line = test
        end

    end

    if line ~= "" then
        table.insert(lines, line)
    end

    return lines

end

--------------------------------------------------------------------------
-- Construye TODAS las páginas del libro de una sola vez.
--
-- layout = {
--   columnWidth        = ancho de columna para el wrap del texto
--   font               = fuente del cuerpo de texto
--   topMargin          = margen superior de las páginas de texto
--   bottomMargin       = margen inferior reservado (botones/nº página)
--   paragraphGap       = espacio extra tras cada párrafo
--   lineSpacing        = espacio entre líneas
--   lineHeightFallback = altura de línea si getFontHeight() falla
--   openHeight         = alto del panel "abierto" (2 páginas)
--   coverTitle         = texto de portada (título)
--   coverSubtitle      = texto de portada (autor/subtítulo)
-- }
--------------------------------------------------------------------------
function BookPaginator.buildPages(book, layout)

    local font = layout.font
    local lineHeight = getTextManager():getFontHeight(font) or layout.lineHeightFallback
    local textWidth = layout.columnWidth
    local maxY = layout.openHeight - layout.bottomMargin

    local pages = {}

    ------------------------------------------------------------------
    -- Página de portada
    ------------------------------------------------------------------
    table.insert(pages, {
        type = "title",
        text = layout.coverTitle,
        subtitle = layout.coverSubtitle
    })

    ------------------------------------------------------------------
    -- Aplanamos + paginamos el resto del contenido
    ------------------------------------------------------------------
    local currentLines = {}
    local currentY = layout.topMargin

    local function flushTextPage()
        if #currentLines > 0 then
            table.insert(pages, { type = "text", lines = currentLines })
            currentLines = {}
        end
        currentY = layout.topMargin
    end

    for _, srcPage in ipairs(book.pages or {}) do

        for _, heading in ipairs(srcPage.headings or {}) do
            flushTextPage()
            table.insert(pages, {
                type = "heading",
                text = heading.text,
                level = heading.level
            })
        end

        for _, paragraph in ipairs(srcPage.paragraphs or {}) do

            local wrapped = BookPaginator.wrapText(paragraph, textWidth, font)

            for _, line in ipairs(wrapped) do

                if currentY + lineHeight + layout.lineSpacing > maxY then
                    flushTextPage()
                end

                table.insert(currentLines, line)
                currentY = currentY + lineHeight + layout.lineSpacing

            end

            currentY = currentY + layout.paragraphGap

            if currentY > maxY then
                flushTextPage()
            end

        end

    end

    flushTextPage()

    return pages

end

-- Agrupa páginas en spreads (pares izquierda/derecha), portada sola.
-- Es barato (solo agrupa referencias), así que se puede llamar entero
-- cada vez sin preocuparse de rendimiento.
function BookPaginator.buildSpreads(pages)

    local spreads = {}

    if #pages == 0 then
        return spreads
    end

    table.insert(spreads, { single = true, left = pages[1] })

    local i = 2

    while i <= #pages do
        table.insert(spreads, {
            single = false,
            left = pages[i],
            right = pages[i + 1]
        })
        i = i + 2
    end

    return spreads

end

return BookPaginator