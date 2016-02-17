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
local Player

if opt.player == "random" then                 -- player performs random actions
   Player = require("RandomPlayer")
elseif opt.player == "human" then                      -- play from the keyboard
   Player = require("HumanPlayer")
end

player = Player.create(Game)


--------------------------------------------------------------------------------
--- Train and eval
--------------------------------------------------------------------------------

local episodesNo = tonumber(opt.episodes)
local evalEvery = tonumber(opt.evalEvery)
local evalEpisodesNo = tonumber(opt.evalEpisodes)
local evalSessionsNo = torch.ceil(episodesNo / evalEvery)

trainingScores = torch.Tensor(episodesNo)
evalScores = torch.Tensor(evalSessionsNo)

for s = 1, evalSessionsNo do
   for e = 1, evalEvery do
      local state = Game.create(opt)
      local oldState, action, reward, message

      if opt.display then state:display() end

      while not state:isFinal() do
         action = player:move(state, true)
         oldState = state:clone()
         reward, message = state:applyAction(action)
         player:feedback(oldState, action, reward, state)
         if opt.display then
            print("Breaking news: " .. message)
            state:display()
         end
      end -- while not state:isFinal()

      trainingScores[(s-1) * evalEvery + e] = state:getScore()
   end -- for e

   local totalScore = 0

   for e = 1, evalEpisodesNo do
      local state = Game.create(opt)

      if opt.verbose then state:display() end

      while not state:isFinal() do
         action = player:move(state, false)
         reward, message = state:applyAction(action)
      end -- while not state:isFinal()

      totalScore = totalScore + state:getScore()
   end -- for e

   evalScores[s] = (totalScore / evalEpisodesNo)
end

print("Done!")
