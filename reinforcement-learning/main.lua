--------------------------------------------------------------------------------
--- Load modules
--------------------------------------------------------------------------------

require("torch")

local util = require("util")

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
cmd:option("-display", false, "Display game info")
cmd:option("-episodes", 1000, "Number of episodes to be played")
cmd:option("-evalEvery", 10, "Eval the strategy every n games")
cmd:option("-evalEpisodes", 10, "Number of episodes to use for evaluation")

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
elseif opt.player == "human" then                      -- play from the keyboard
   player = function (state)
      local c = util.getch_unix()
      if c == "w" then return state.NORTH;
      elseif c == "a" then return state.WEST;
      elseif c == "s" then return state.SOUTH;
      elseif c == "d" then return state.EAST;
      else return state.NOOP; end                                        -- noop
   end
end

state = Game.create(opt)
state:display()

while not state:isFinal() do
   local action = player(state)
   oldState = state:clone()
   reward, message = oldState:applyAction(action)
   print(message)
   oldState:display()
   state = oldState
end

print(state:serialize())

print("Done!")
