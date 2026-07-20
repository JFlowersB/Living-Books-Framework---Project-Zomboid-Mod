--C:\Users\Joan\Zomboid\Workshop\DonQuijoteDeLaMancha\Contents\mods\DonQuijoteDeLaMancha\42\media\lua\client\QJBookSystem\BookLoader.lua--

local chcjson = require "QJBookSystem/Json"

BookLoader = {}

-- Caché: la primera llamada lee y parsea el JSON, las siguientes
-- devuelven la misma tabla sin volver a tocar el disco.
BookLoader.cachedBook = nil

function BookLoader.load()

    if BookLoader.cachedBook then
        return BookLoader.cachedBook
    end

    local file = getModFileReader(
        "DonQuijoteDeLaMancha",
        "media/books/DonQuijote.json",
        false
    )

    if not file then
        print("[DonQuijote] No se encontró DonQuijote.json")
        return nil
    end

    -- Acumulamos en tabla + table.concat en vez de concatenar en el
    -- bucle (más rápido para un JSON grande como este).
    local lines = {}

    while true do
        local line = file:readLine()
        if not line then break end
        lines[#lines + 1] = line
    end

    file:close()

    local text = table.concat(lines, "\n")

    local ok, data = pcall(chcjson.Decode, text)

    if not ok then
        print("[DonQuijote] Error al parsear el JSON: " .. tostring(data))
        return nil
    end

    BookLoader.cachedBook = data

    return data
end