require "QJBookSystem/BookReader"
require "QJBookSystem/BookLoader"
require "QJBookSystem/BookPreloader"

require "TimedActions/ISInventoryTransferAction"
require "TimedActions/ISTimedActionQueue"
require "TimedActions/ISBaseTimedAction"

local BOOK_FULLTYPE = "Quijote.DonQuijoteDeLaMancha"
local BOOK_ICON = "Item_Book_OldFancy"
local READ_TIME = 20 -- duración de la action bar (ticks), ajusta a tu gusto

local window = nil

--------------------------------------------------------
-- Abrir libro
--------------------------------------------------------

local function OpenBook()

    local player = getPlayer()

    player:getEmitter():playSound("QuijoteSound")

    if window then
        window:removeFromUIManager()
        window = nil
    end

    local sw = getCore():getScreenWidth()
    local sh = getCore():getScreenHeight()

    local h = math.floor(sh * 0.82)
    local w = math.floor(h * 1.60)

    local book = BookLoader.load()

    if not book then
        print("[DonQuijote] No se pudo cargar el libro")
        return
    end

    window = BookReader:new(
        (sw - w) / 2,
        (sh - h) / 2,
        w,
        h,
        book
    )

    window:initialise()
    window:addToUIManager()

end

--------------------------------------------------------
-- TimedAction: leer el libro (action bar + quieto)
--------------------------------------------------------

ISReadQuijoteAction = ISBaseTimedAction:derive("ISReadQuijoteAction")

function ISReadQuijoteAction:isValidStart()
    return self.character:getInventory():contains(self.item)
end

function ISReadQuijoteAction:isValid()
    -- si el item desaparece de las manos o el jugador muere, se cancela
    return self.character:isAlive() and self.character:getInventory():contains(self.item)
end

function ISReadQuijoteAction:update()
    -- fuerza al personaje a mirar al frente mientras "lee"
    self.character:faceLocation(self.character:getX(), self.character:getY())
end

function ISReadQuijoteAction:start()
    self:setActionAnim("Read")
    self.character:reportEvent("EventReading")
    -- opcional: sujetar el libro visualmente igual que un libro normal
    self.character:setVariable("bookHoldType", "Big")
end

function ISReadQuijoteAction:stop()
    ISBaseTimedAction.stop(self)
end

function ISReadQuijoteAction:perform()
    ISBaseTimedAction.perform(self)
    OpenBook()
end

function ISReadQuijoteAction:new(character, item, time)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.item = item
    o.maxTime = time or READ_TIME

    -- clave para que SOLO se pueda hacer parado, como leer un libro vanilla
    o.stopOnWalk = true
    o.stopOnRun = true
    o.stopOnAim = true

    return o
end

--------------------------------------------------------
-- Buscar libro
--------------------------------------------------------

local function findBook(items)

    for _, entry in ipairs(items) do

        local item = entry

        if not instanceof(item, "InventoryItem") then
            if entry.items then
                item = entry.items[1]
            else
                item = nil
            end
        end

        if item and item:getFullType() == BOOK_FULLTYPE then
            return item
        end

    end

    return nil

end

--------------------------------------------------------
-- Leer
--------------------------------------------------------

local function ReadBook(item)

    local player = getPlayer()

    -- Si ya lo tiene encima, encolar directamente la action bar de lectura.
    if item:getContainer() == player:getInventory() then
        ISTimedActionQueue.add(ISReadQuijoteAction:new(player, item))
        return
    end

    -- Si está en un contenedor, cogerlo primero y luego leer con la action bar.
    local pickupAction = ISInventoryTransferAction:new(
        player,
        item,
        item:getContainer(),
        player:getInventory()
    )

    pickupAction:setOnComplete(function()
        ISTimedActionQueue.add(ISReadQuijoteAction:new(player, item))
    end)

    ISTimedActionQueue.add(pickupAction)

end

--------------------------------------------------------
-- Menú contextual
--------------------------------------------------------

local function AddMenu(playerNum, context, items)

    local item = findBook(items)

    if not item then
        return
    end

    local option = context:addOption(
        getText("UI_QJBook_Read"),
        item,
        ReadBook
    )

    option.iconTexture = getTexture(BOOK_ICON)

    table.insert(context.options, 1, table.remove(context.options))

end

Events.OnFillInventoryObjectContextMenu.Add(AddMenu)