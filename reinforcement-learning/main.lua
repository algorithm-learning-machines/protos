--------------------------------------------------------------------------------
--- Load modules
--------------------------------------------------------------------------------

require("torch")
require("gnuplot")

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
cmd:option("-sleep", 0, "Sleep")

cmd:option("-justForFun", false, "No training, no plots")
cmd:option("-episodes", 10000, "Number of episodes to be played")
cmd:option("-evalEvery", 200, "Eval the strategy every n games")
cmd:option("-evalEpisodes", 20, "Number of episodes to use for evaluation")

cmd:option("-seed", 666, "Seed for the random number generator")

cmd:option("-discount", 0.95, "Discount factor")
cmd:option("-learningRate", 0.1, "Learning rate")
cmd:option("-epsilon", 0.1, "Probability to choose a random action")

--------------------------------------------------------------------------------
--- Game specific options
--------------------------------------------------------------------------------

cmd:option("-height", 10, "Maze height")
cmd:option("-width", 10, "Maze width")
cmd:option("-monstersNo", 4, "Number of monsters")
cmd:option("-treatsNo", 4, "Number of monsters")
cmd:option("-walls", "random", "Where to place walls (e.g. '1,2;1,3;2,4'")
cmd:option("-radius", 0, "How much does the pacman see around him")

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
elseif opt.player == "Q" then
   Player = require("QPlayer")
end

player = Player.create(Game, opt)

if opt.justForFun then
   for ep = 1, tonumber(opt.episodes) do
      local state = Game.create(opt)
      local repr = state:serialize()
      local action, message
      if opt.display then state:display() end

      while not state:isFinal() do
         action = player:move(repr, true)
         _, message = state:applyAction(action)
         repr = state:serialize()
         if opt.display then
            print("Breaking news: " .. message)
            state:display()
            print(repr)
         end
      end -- while not state:isFinal()
   end
   os.exit()
end

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
      local repr = state:serialize()
      local oldState, action, reward, message, oldRepr

      if opt.display then
         state:display()
         print(repr)
         sys.sleep(tonumber(opt.sleep))
      end

      while not state:isFinal() do
         oldRepr = repr
         action = player:move(state:serialize(), true)
         reward, message = state:applyAction(action)
         repr = state:serialize()
         player:feedback(oldRepr, action, reward, repr)
         if opt.display then
            print("Breaking news: " .. message)
            state:display()
            sys.sleep(tonumber(opt.sleep))
         end
      end -- while not state:isFinal()

      trainingScores[(s-1) * evalEvery + e] = state:getScore()
   end -- for e

   gnuplot.figure(1)
   gnuplot.plot({'Training scores', trainingScores[{{1, s * evalEvery}}], "-"})

   local totalScore = 0

   for e = 1, evalEpisodesNo do
      local state = Game.create(opt)

      if opt.verbose then state:display() end

      while not state:isFinal() do
         action = player:move(state:serialize(), false)
         reward, message = state:applyAction(action)
      end -- while not state:isFinal()

      totalScore = totalScore + state:getScore()
   end -- for e

   evalScores[s] = (totalScore / evalEpisodesNo)

   gnuplot.figure(2)
   gnuplot.plot({'Evaluation scores', evalScores[{{1, s}}], "-"})

end

print("Done!")
