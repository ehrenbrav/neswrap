neswrap = {}
require 'paths'

paths.dofile('nesffi.lua')
paths.dofile('NesEnv.lua')

paths.dofile('NesLayer.lua')
paths.dofile('GameScreen.lua')
paths.dofile('GameEnvironment.lua')

return neswrap
