--------------------------------------------------------------------------
-- BookPreloader.lua (C:\Users\Joan\Zomboid\Workshop\DonQuijoteDeLaMancha\Contents\mods\DonQuijoteDeLaMancha\42\media\lua\client\QJBookSystem\BookPreloader.lua)
--
-- Pagina el libro completo una sola vez, lo antes posible (al llegar al
-- menú principal, antes de elegir partida). Como red de seguridad
-- también se engancha a OnGameStart por si OnMainMenuEnter no llegara a
-- dispararse. run() es idempotente (comprueba .ready).
--
-- Las constantes de maquetación de aquí abajo tienen que coincidir con
-- las de BookReader.lua para que la paginación sea idéntica.
--------------------------------------------------------------------------

require "QJBookSystem/BookLoader"
require "QJBookSystem/BookPaginator"

BookPreloader = {}

BookPreloader.book = nil
BookPreloader.pages = nil
BookPreloader.spreads = nil
BookPreloader.openWidth = nil
BookPreloader.openHeight = nil
BookPreloader.ready = false

-- Deben coincidir con BookReader.lua
local BOOK_TEXT_FONT       = UIFont.Medium
local TOP_MARGIN           = 80
local BOTTOM_MARGIN        = 90
local PARAGRAPH_GAP        = 18
local LINE_SPACING         = 6
local LINE_HEIGHT_FALLBACK = 22
local COLUMN_MARGIN        = 70
local GUTTER               = 50

-- Debe coincidir con el cálculo de w/h que hace BookTest.lua al abrir
-- la ventana (mismo tamaño de panel "abierto" = mismo ancho de columna).
local function computeOpenDimensions()
    local sw = getCore():getScreenWidth()
    local sh = getCore():getScreenHeight()
    local h = math.floor(sh * 0.82)
    local w = math.floor(h * 1.60)
    return w, h
end

function BookPreloader.run()

    if BookPreloader.ready then
        return -- ya está precargado, no repetir el trabajo
    end

    local book = BookLoader.load()

    if not book then
        print("[DonQuijote] No se pudo precargar el libro")
        return
    end

    local openWidth, openHeight = computeOpenDimensions()
    local columnWidth = (openWidth / 2) - (GUTTER / 2) - (COLUMN_MARGIN * 2)

    local title = book.filename and book.filename:gsub("%.pdf", "") or "Sin titulo"
    local subtitle = book.author or book.subtitle

    local layout = {
        columnWidth = columnWidth,
        font = BOOK_TEXT_FONT,
        topMargin = TOP_MARGIN,
        bottomMargin = BOTTOM_MARGIN,
        paragraphGap = PARAGRAPH_GAP,
        lineSpacing = LINE_SPACING,
        lineHeightFallback = LINE_HEIGHT_FALLBACK,
        openHeight = openHeight,
        coverTitle = title,
        coverSubtitle = subtitle,
    }

    -- Pagina el libro completo de golpe en este mismo frame. Con un
    -- libro largo puede notarse un pequeño parón al entrar al menú; si
    -- hiciera falta, se podría repartir en varios Events.OnTick como
    -- hace BookReader con su carga por lotes.
    local pages = BookPaginator.buildPages(book, layout)
    local spreads = BookPaginator.buildSpreads(pages)

    BookPreloader.book = book
    BookPreloader.pages = pages
    BookPreloader.spreads = spreads
    BookPreloader.openWidth = openWidth
    BookPreloader.openHeight = openHeight
    BookPreloader.ready = true

end

-- Precarga real: en cuanto se llega al menú principal, antes de elegir
-- nueva partida o cargar una.
Events.OnMainMenuEnter.Add(BookPreloader.run)

-- Red de seguridad: por si OnMainMenuEnter no llegase a dispararse.
Events.OnGameStart.Add(BookPreloader.run)

return BookPreloader