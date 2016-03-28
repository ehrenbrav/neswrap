function neswrap.createEnv(romName, extraConfig)
    return neswrap.NesEnv(romName, extraConfig)
end

local RAM_LENGTH = 128

-- Copies values from src to dst.
local function update(dst, src)
    for k, v in pairs(src) do
        dst[k] = v
    end
end

-- Copies the config. An error is raised on unknown params.
local function updateDefaults(dst, src)
    for k, v in pairs(src) do
        if dst[k] == nil then
            _print_usage(dst)
            error("unsupported param: " .. k)
        end
    end
    update(dst, src)
end

local Env = torch.class('neswrap.NesEnv')
function Env:__init(romPath, extraConfig)
    self.config = {
        -- An additional reward signal can be provided
        -- after the end of one game.
        -- Note that many games don't change the score
        -- when loosing or gaining a life.
        gameOverReward=0,
        -- Screen display can be enabled.
        display=false,
        -- The RAM can be returned as an additional observation.
        enableRamObs=false,
    }
    updateDefaults(self.config, extraConfig)

    self.win = nil
    self.nes = neswrap.newNes(romPath)
    local width = self.nes:getScreenWidth()
    local height = self.nes:getScreenHeight()
    local obsShapes = {{height, width}}
    if self.config.enableRamObs then
        obsShapes={{height, width}, {RAM_LENGTH}}
    end
    self.envSpec = {
        nActions=18,
        obsShapes=obsShapes,
    }
end

-- Returns a description of the observation shapes
-- and of the possible actions.
function Env:getEnvSpec()
    return self.envSpec
end

-- Returns a list of observations.
-- The integer palette values are returned as the observation.
function Env:envStart()
    self.nes:resetGame()
    return self:_generateObservations()
end

-- Does the specified actions and returns the (reward, observations) pair.
-- Valid actions:
--     {torch.Tensor(zeroBasedAction)}
-- The action number should be an integer from 0 to 17.
function Env:envStep(actions)
    assert(#actions == 1, "one action is expected")
    assert(actions[1]:nElement() == 1, "one discrete action is expected")

    if self.nes:isGameOver() then
        self.nes:resetGame()
        -- The first screen of the game will be also
        -- provided as the observation.
        return self.config.gameOverReward, self:_generateObservations()
    end

    local reward = self.nes:act(actions[1][1])
    return reward, self:_generateObservations()
end

function Env:getRgbFromPalette(obs)
    return neswrap.getRgbFromPalette(obs)
end

function Env:_createObs()
    -- The torch.data() function is provided by torchffi.
    local width = self.nes:getScreenWidth()
    local height = self.nes:getScreenHeight()
    local obs = torch.ByteTensor(height, width)
    self.nes:fillObs(torch.data(obs), obs:nElement())
    return obs
end

function Env:_createRamObs()
    local ram = torch.ByteTensor(RAM_LENGTH)
    self.nes:fillRamObs(torch.data(ram), ram:nElement())
    return ram
end

function Env:_display(obs)
    require 'image'
    local frame = self:getRgbFromPalette(obs)
    self.win = image.display({image=frame, win=self.win})
end

-- Generates the observations for the current step.
function Env:_generateObservations()
    local obs = self:_createObs()
    if self.config.display then
        self:_display(obs)
    end

    if self.config.enableRamObs then
        local ram = self:_createRamObs()
        return {obs, ram}
    else
        return {obs}
    end
end

function Env:saveState()
    self.nes:saveState()
end

function Env:loadState()
    return self.nes:loadState()
end

function Env:actions()
    local nactions = self.nes:numActions()
    local actions = torch.IntTensor(nactions)
    self.nes:actions(torch.data(actions), actions:nElement())
    return actions
end

function Env:lives()
    return self.nes:lives()
end

function Env:saveSnapshot()
    return self.nes:saveSnapshot()
end

function Env:restoreSnapshot(snapshot)
    self.nes:restoreSnapshot(snapshot)
end

function Env:getScreenWidth()
  return self.nes:getScreenWidth()
end

function Env:getScreenHeight()
  return self.nes:getScreenHeight()
end

