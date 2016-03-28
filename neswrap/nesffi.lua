require 'paths'

-- Reads the whole content of the specified file.
local function readContent(path)
    local file = io.open(path)
    local content = file:read("*a")
    file:close()
    return content
end

-- Appends all srcList values to the destList.
local function appendAll(destList, srcList)
    for _, val in ipairs(srcList) do
        table.insert(destList, val)
    end
end


local ffi = require 'ffi'
-- We let the nes::NESInterface look like a C struct.
ffi.cdef("typedef struct NESInterface NESInterface;")
ffi.cdef(readContent(paths.thisfile("neswrap.inl")))
local lib = ffi.load(package.searchpath('libneswrap',package.cpath))

-- Defining the metatable for NESInterface userdata.
local mt = {}
mt.__index = mt
mt.act = lib.nes_act
mt.getScreenWidth = lib.nes_getScreenWidth
mt.getScreenHeight = lib.nes_getScreenHeight
mt.fillObs = lib.nes_fillObs
mt.isGameOver = lib.nes_isGameOver
mt.resetGame = lib.nes_resetGame
mt.loadState = lib.nes_loadState
mt.saveState = lib.nes_saveState
mt.numActions = lib.nes_numLegalActions
mt.actions = lib.nes_legalActions
mt.lives = lib.nes_livesRemaining

mt.restoreSnapshot = function(self, snapshot)
    lib.nes_restoreSnapshot(self, snapshot, #snapshot)
end

mt.saveSnapshot = function(self)
    local size = lib.nes_getSnapshotLength(self)
    local buf = ffi.new("char[?]", size)
    lib.nes_saveSnapshot(self, buf, size)
    return ffi.string(buf, size)
end


ffi.metatype("NESInterface", mt)

-- Creates a new NESInterface instance.
function neswrap.newNes(romPath)
    if not paths.filep(romPath) then
        error(string.format('no such ROM file: %q', romPath))
    end
    return ffi.gc(lib.nes_new(romPath), lib.nes_gc)
end

-- Converts the palette values to RGB values.
-- A new ByteTensor is returned.
function neswrap.getRgbFromPalette(obs)
    obs = obs:contiguous()
    assert(obs:nElement() == obs:storage():size(),
        "the obs should not share a bigger storage")
    local rgbShape = {3}
    appendAll(rgbShape, obs:size():totable())

    local rgb = torch.ByteTensor(unpack(rgbShape))
    lib.nes_fillRgbFromPalette(torch.data(rgb), torch.data(obs),
            rgb:nElement(), obs:nElement())
    return rgb
end



