-- This file defines the neswrap.GameEnvironment class.

-- The GameEnvironment class.
local gameEnv = torch.class('neswrap.GameEnvironment')


function gameEnv:__init(_opt)
    local _opt = _opt or {}
    -- defaults to emulator speed
    self.game_path      = _opt.game_path or '.'
    self.verbose        = _opt.verbose or 0
    self._actrep        = _opt.actrep or 1
    self._random_starts = _opt.random_starts or 1
    self.gameOverPenalty = _opt.gameOverPenalty or 0
    self._screen        = neswrap.GameScreen(_opt.pool_frms, _opt.gpu)
    self:reset(_opt.env, _opt.env_params, _opt.gpu)
    return self
end


function gameEnv:_updateState(frame, reward, terminal, lives)
    self._state.reward       = reward
    self._state.terminal     = terminal
    self._state.prev_lives   = self._state.lives or lives
    self._state.lives        = lives
    return self
end


function gameEnv:getState()
    -- grab the screen again only if the state has been updated in the meantime
    self._state.observation = self._state.observation or self._screen:grab():clone()
    self._state.observation:copy(self._screen:grab())

    -- lives will not be reported externally
    return self._state.observation, self._state.reward, self._state.terminal
end


function gameEnv:reset(_env, _params, _gpu)
    local env
    local params = _params or {useRGB=true}
    -- if no game name given use previous name if available
    if self.game then
        env = self.game.name
    end
    env = _env or env or 'ms_pacman'

    self.game       = neswrap.game(env, params, self.game_path)
    self._actions   = self:getActions()

    -- start the game
    if self.verbose > 0 then
        print('\nPlaying:', self.game.name)
    end

    self:_resetState()
    self:_updateState(self:_step(0))
    self:getState()
    return self
end


function gameEnv:_resetState()
    self._screen:clear()
    self._state = self._state or {}
    return self
end


-- Function plays `action` in the game and return game state.
function gameEnv:_step(action)
    assert(action)
    local x = self.game:play(action)
    self._screen:paint(x.data)
    return x.data, x.reward, x.terminal, x.lives
end


-- Function plays one random action in the game and return game state.
function gameEnv:_randomStep()
    return self:_step(self._actions[torch.random(#self._actions)])
end


function gameEnv:step(action, training)
    -- accumulate rewards over actrep action repeats
    local cumulated_reward = 0
    local frame, reward, terminal, lives
    for i=1,self._actrep do
        -- Take selected action; ATARI games' actions start with action "0".
        frame, reward, terminal, lives = self:_step(action)

        -- accumulate instantaneous reward
        cumulated_reward = cumulated_reward + reward

        -- Loosing a life will trigger a terminal signal in training mode.
        -- We assume that a "life" IS an episode during training, but not during testing
        if training and lives and lives < self._state.lives then
            terminal = true
            
            -- Penalty for getting killed.
            if self.gameOverPenalty > 0 then
               cumulated_reward = cumulated_reward - self.game:getCurrentScore()
            end
        end

        -- game over, no point to repeat current action
        if terminal then break end
    end
    self:_updateState(frame, cumulated_reward, terminal, lives)
    return self:getState()
end


-- Reset the game from the beginning.
function gameEnv:newGame()
    self._screen:clear()
    self.game:resetGame()
    -- take one null action in the new game
    return self:_updateState(self:_step(0)):getState()
end


--[[ Function advances the emulator state until a new (random) game starts and
returns this state.
]]
function gameEnv:nextRandomGame(k)
    local obs, reward, terminal = self:newGame()
    k = k or torch.random(self._random_starts)
    for i=1,k-1 do
        obs, reward, terminal, lives = self:_step(0)
        if terminal then
            print(string.format('WARNING: Terminal signal received after %d 0-steps', i))
        end
    end
    return self:_updateState(self:_step(0)):getState()
end


--[[ Function returns the number total number of pixels in one frame/observation
from the current game.
]]
function gameEnv:nObsFeature()
    return self.game:nObsFeature()
end


-- Function returns a table with valid actions in the current game.
function gameEnv:getActions()
    return self.game:actions()
end
