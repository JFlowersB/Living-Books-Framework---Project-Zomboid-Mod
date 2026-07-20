require "Items/ProceduralDistributions"

local ITEM = "Quijote.DonQuijoteDeLaMancha"
local BASE_CHANCE = 2.5

local PRESET_MULTIPLIERS = {
    [1] = 0,
    [2] = 0.1,
    [3] = 0.2,
    [4] = 0.4,
    [5] = 0.6,
    [6] = 2.0,
    [7] = 3.0,
}

local function getMultiplier()
    local sv = SandboxVars.Quijote
    local preset = (sv and sv.SpawnChance) or 5
    return PRESET_MULTIPLIERS[preset] or PRESET_MULTIPLIERS[5]
end

-- Devuelve true si el item es un libro de literatura de vanilla.
local function isLiteratureBook(item)

    if type(item) ~= "string" then
        return false
    end

    -- Algunas distribuciones usan Base.Book_XXX
    item = item:gsub("^Base%.", "")

    -- Libros antiguos
    if item:match("^BookFancy_") then
        return true
    end

    -- Libro genérico
    if item == "Book" then
        return true
    end

    -- Debe empezar por Book_
    if not item:match("^Book_") then
        return false
    end

    -- Excluir libros de habilidades
    if item:match("^Book_Aiming") then return false end
    if item:match("^Book_Axe") then return false end
    if item:match("^Book_Blunt") then return false end
    if item:match("^Book_Carpentry") then return false end
    if item:match("^Book_Cooking") then return false end
    if item:match("^Book_Electricity") then return false end
    if item:match("^Book_Farming") then return false end
    if item:match("^Book_FirstAid") then return false end
    if item:match("^Book_Fishing") then return false end
    if item:match("^Book_LongBlade") then return false end
    if item:match("^Book_LongBlunt") then return false end
    if item:match("^Book_Maintenance") then return false end
    if item:match("^Book_Mechanics") then return false end
    if item:match("^Book_MetalWelding") then return false end
    if item:match("^Book_ShortBlade") then return false end
    if item:match("^Book_ShortBlunt") then return false end
    if item:match("^Book_Sneak") then return false end
    if item:match("^Book_Spear") then return false end
    if item:match("^Book_Strength") then return false end
    if item:match("^Book_Tailoring") then return false end
    if item:match("^Book_Trapping") then return false end

    return true
end

local function hasLiteratureBook(items)
    for i = 1, #items, 2 do
        if isLiteratureBook(items[i]) then
            return true
        end
    end
    return false
end

local function alreadyHasItem(items, itemName)
    for i = 1, #items, 2 do
        if items[i] == itemName then
            return true
        end
    end
    return false
end

local function addSpawns()

    if not (ProceduralDistributions and ProceduralDistributions.list) then
        print("[Quijote] ERROR: ProceduralDistributions.list no disponible")
        return
    end

    local mult = getMultiplier()

    if mult <= 0 then
        print("[Quijote] Spawn desactivado.")
        return
    end

    local chance = BASE_CHANCE * mult
    local seen = {}
    local inserted = 0
    local scanned = 0

    for _, dist in pairs(ProceduralDistributions.list) do

        if type(dist) == "table" and type(dist.items) == "table" then
            scanned = scanned + 1

            if not seen[dist.items] then
                seen[dist.items] = true

                if hasLiteratureBook(dist.items)
                and not alreadyHasItem(dist.items, ITEM) then

                    table.insert(dist.items, ITEM)
                    table.insert(dist.items, chance)
                    inserted = inserted + 1
                end
            end
        end
    end

    print("[Quijote] insertado en "..inserted.." distribuciones.")
end

Events.OnPreDistributionMerge.Add(addSpawns)