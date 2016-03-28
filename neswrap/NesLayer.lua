--[[ Game class that provides an interface for the roms.

In general, you would want to use:
    neswrap.game(gamename)
]]

require 'torch'
local game = torch.class('neswrap.game')
require 'paths'


--[[
Parameters:

 * `gamename` (string) - one of the rom names without '.zip' extension.
 * `options`  (table) - a table of options

Where `options` has the following keys:

 * `useRGB`   (bool) - true if you want to use RGB pixels.
 TODO - remove this next option?
 * `useRAM`   (bool) - true if you want to use the RAM.

]]
function game:__init(gamename, options, roms_path)
    options = options or {}

    self.useRGB   = options.useRGB
    self.useRAM   = options.useRAM

    self.name = gamename
    local path_to_game = paths.concat(roms_path, gamename) .. '.zip'
    local msg, err = pcall(neswrap.createEnv, path_to_game,
                           {enableRamObs = self.useRAM})
    if not msg then
        error("Cannot find rom " .. path_to_game)
    end
    self.env = err
    self.observations = self.env:envStart()
    self.action = {torch.Tensor{0}}

    self.game_over = function() return self.env.nes:isGameOver() end

    -- setup initial observations by playing a no-action command
    self:saveState()
    local x = self:play(0)
    self.observations[1] = x.data
    self:loadState()
end


function game:stochastic()
    return false
end


function game:shape()
    return self.observations[1]:size():totable()
end


function game:nObsFeature()
    return torch.prod(torch.Tensor(self:shape()),1)[1]
end


function game:saveState()
    self.env:saveState()
end


function game:loadState()
    return self.env:loadState()
end


function game:actions()
    return self.env:actions():storage():totable()
end


function game:lives()
    return self.env:lives()
end


--[[
Parameters:
 * `action` (int [0-17]), the action to play

Returns a table containing the result of playing given action, with the
following keys:
 * `reward` - reward obtained
 * `data`   - observations
 * `pixels` - pixel space observations
 * `ram`    - ram of the ATARI if requested
 * `terminal` - (bool), true if the new state is a terminal state
]]
function game:play(action)
    action = action or 0
    self.action[1][1] = action

    -- take the step in the environment
    local reward, observations = self.env:envStep(self.action)
    local is_game_over = self.game_over(reward)

    local pixels = observations[1]
    local ram = observations[2]
    local data = pixels
    local gray = pixels

    if self.useRGB then
        data = self.env:getRgbFromPalette(pixels)
        pixels = data
    end

    return {reward=reward, data=data, pixels=pixels, ram=ram,
            terminal=is_game_over, gray=gray, lives=self:lives()}
end


function game:getState()
    return self.env:saveSnapshot()
end


function game:restoreState(state)
    self.env:restoreSnapshot(state)
end
