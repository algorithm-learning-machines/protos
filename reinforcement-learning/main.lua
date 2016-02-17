--------------------------------------------------------------------------------
--- Load modules
--------------------------------------------------------------------------------

require("torch")

--------------------------------------------------------------------------------
--- Define command line arguments (options)
--------------------------------------------------------------------------------

cmd = torch.CmdLine()
cmd:text()
cmd:text("Training players for various games using Reinforcement Learning")
cmd:text()
cmd:text("Options:")
cmd:option("-game", "pacman", "Game to be used")
cmd:option("-player", "random", "Who's playing")

cmd:option("-seed", 666, "Seed for the random number generator")

--------------------------------------------------------------------------------
--- Game specific options
--------------------------------------------------------------------------------

cmd:option("-height", 10, "Maze height")
cmd:option("-width", 10, "Maze width")


--------------------------------------------------------------------------------
--- Parse arguments and let the hammers go (dăm drumul la ciocane)
--------------------------------------------------------------------------------

opt = cmd:parse(arg)
torch.manualSeed(opt.seed)

--------------------------------------------------------------------------------
--- Initialize game and player
--------------------------------------------------------------------------------

local Game = require(opt.game)
local player

if opt.player == "random" then                 -- player performs random actions
   player = function (state) return torch.random(#(Game.getActions())) end
end

state = Game.create(opt)
state:display()
local i = 8
while not state:isFinal() and i > 4 do
   i = i - 1
   local action = player(state)
   oldState = state:clone()
   reward = oldState:applyAction(action)
   oldState:display()
   state = oldState
end

print(state:serialize())

print("Done!")
