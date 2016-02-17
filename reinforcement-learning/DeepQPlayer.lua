--------------------------------------------------------------------------------
--- Load needed modules
--------------------------------------------------------------------------------

require("torch")
require("nn")
require("optim")

--------------------------------------------------------------------------------
--- Player with Deep Q-learning (similar to Deep Mind's work)
--------------------------------------------------------------------------------

local DeepQPlayer = {}
DeepQPlayer.__index = DeepQPlayer

function DeepQPlayer.create(Game, opt)                 -- initialized new player
   self = {}
   setmetatable(self, DeepQPlayer)

   self.actionsNo = #(Game.getActions())

   -----------------------------------------------------------------------------
   --- Initialize network
   -----------------------------------------------------------------------------

   self.screenHeight = Game.screenHeight
   self.screenWidth = Game.screenWidth

   self.Q1 = nn.Sequential()

   self.Q1:add(nn.SpatialConvolutionMM(1, 32, 3, 3, 1, 1, 1, 1))  -- convolution
   self.Q1:add(nn.ReLU())                                                 --ReLU
   self.Q1:add(nn.SpatialMaxPooling(2, 2, 2, 2))                  -- max pooling

   local _screenHeight = math.floor(self.screenHeight / 2)
   local _screenWidth = math.floor(self.screenWidth / 2)

   self.Q1:add(nn.SpatialConvolutionMM(32, 32, 3, 3, 1, 1, 1, 1)) -- convolution
   self.Q1:add(nn.ReLU())                                                 --ReLU
   self.Q1:add(nn.SpatialMaxPooling(2, 2, 2, 2))                  -- max pooling

   _screenHeight = math.floor(_screenHeight / 2)
   _screenWidth = math.floor(_screenWidth / 2)

   self.Q1:add(nn.Reshape(_screenHeight * _screenWidth * 32))
   self.Q1:add(nn.Linear(_screenHeight * _screenWidth * 32, self.actionsNo))

   self.Q2 = self.Q1:clone()


   -----------------------------------------------------------------------------
   --- Initialize database for experience replay
   -----------------------------------------------------------------------------

   self.experiences = {}
   self.partitionsNo = 3
   self.partitionSize = 20
   self.databaseFull = false
   self.crtIdx = 1
   self.crtPartition = 1

   for i = 1, self.partitionsNo do
      table.insert(
         self.experiences,
         {
            states = torch.Tensor(self.partitionSize, 1,
                                 self.screenHeight, self.screenWidth),
            actions = torch.LongTensor(self.partitionSize),
            rewards = torch.Tensor(self.partitionSize),
            nextStates = torch.Tensor(self.partitionSize, 1,
                                      self.screenHeight, self.screenWidth),
         }
      )
   end

   --------------------------------------------------------------------------------
   --- Miscellaneous
   -----------------------------------------------------------------------------

   self.discount = opt.discount
   self.epsilon = opt.epsilon

   return self
end

function DeepQPlayer:move(state, isTraining)
   if (not isTraining) or (torch.rand(1)[1] >= self.epsilon) then
      local _, bestAction = torch.max(self.Q1:forward(state), 1)
      return bestAction[1]
   else
      return torch.random(self.actionsNo)
   end
end


function DeepQPlayer:feedback(state, action, reward, nextState)

   -----------------------------------------------------------------------------
   --- Save experience
   -----------------------------------------------------------------------------

   self.experiences[self.crtPartition].states[self.crtIdx]:copy(state)
   self.experiences[self.crtPartition].actions[self.crtIdx] = action
   self.experiences[self.crtPartition].rewards[self.crtIdx] = reward * 0.1
   self.experiences[self.crtPartition].nextStates[self.crtIdx]:copy(nextState)

   -----------------------------------------------------------------------------
   --- Move the pointer to the next position in the database
   -----------------------------------------------------------------------------

   local shouldLearn = false
   local shouldCopy = false

   self.crtIdx = self.crtIdx + 1
   if self.crtIdx > self.partitionSize then
      self.crtIdx = 1
      self.crtPartition = self.crtPartition + 1
      if self.crtPartition > self.partitionsNo then
         self.databaseFull = true
         self.crtPartition = 1
      end
      shouldLearn = self.databaseFull
   end

   -----------------------------------------------------------------------------
   --- Optimize network
   -----------------------------------------------------------------------------

   if shouldLearn then self:__optimizeQNetwork(); end

   -----------------------------------------------------------------------------
   --- Copy parameters from Q1 to Q2
   -----------------------------------------------------------------------------

   if shouldCopy then
      local q1Params = Q1:getParameters()
      local q2Params = Q2:getParameters()
      q2Params:copy(q1Params)
   end
end

function DeepQPlayer:__optimizeQNetwork()
   -- TODO: Prepare batch & optimize
end

return DeepQPlayer
