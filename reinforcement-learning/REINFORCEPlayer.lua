--------------------------------------------------------------------------------
-- Load needed modules
--------------------------------------------------------------------------------

require("torch")
require("nn")
require("optim")

--------------------------------------------------------------------------------
-- Player that learns through Williams' REINFORCE Algorithm
--------------------------------------------------------------------------------

local REINFORCEPlayer = {}
REINFORCEPlayer.__index = REINFORCEPlayer

function REINFORCEPlayer.create(Game, opt)              -- initialize new player
   self = {}
   setmetatable(self, REINFORCEPlayer)

   self.actionsNo = #(Game.getActions())

   -----------------------------------------------------------------------------
   -- Initialize network
   -----------------------------------------------------------------------------

   self.screenHeight = Game.screenHeight
   self.screenWidth = Game.screenWidth

   self.R = nn.Sequential()

   self.R:add(nn.SpatialConvolutionMM(1, 32, 3, 3, 1, 1, 1, 1))   -- convolution
   self.R:add(nn.ReLU())                                                  --ReLU
   self.R:add(nn.SpatialMaxPooling(2, 2, 2, 2))                   -- max pooling

   local _screenHeight = math.floor(self.screenHeight / 2)
   local _screenWidth = math.floor(self.screenWidth / 2)

   self.R:add(nn.SpatialConvolutionMM(32, 32, 3, 3, 1, 1, 1, 1))  -- convolution
   self.R:add(nn.ReLU())                                                  --ReLU
   self.R:add(nn.SpatialMaxPooling(2, 2, 2, 2))                   -- max pooling

   _screenHeight = math.floor(_screenHeight / 2)
   _screenWidth = math.floor(_screenWidth / 2)

   self.R:add(nn.Reshape(_screenHeight * _screenWidth * 32))
   self.R:add(nn.Linear(_screenHeight * _screenWidth * 32, self.actionsNo))
   self.R:add(nn.SoftMax())


   -----------------------------------------------------------------------------
   -- Miscellanous
   -----------------------------------------------------------------------------

   self.epsilon = opt.epsilon
   self.learningRate = opt.learningRate or 0.1
   self.baseline = opt.baseline or 0.0

   return self
end


function REINFORCEPlayer:move(state, isTraining)
   if (not isTraining) or (torch.rand(1)[1] >= self.epsilon) then
      local _, bestAction = torch.max(self.R:forward(state), 1)
      return bestAction[1]
   else
      return torch.random(self.actionsNo)
   end
end



function REINFORCEPlayer:feedback(repr, action, reward, nextRepr, gameState)

   -----------------------------------------------------------------------------
   --- Optimize network
   -----------------------------------------------------------------------------

   local y = torch.Tensor(self.actionsNo):fill(0)
   y[action] = 1
   local p = self.R.output
   local dG = (y - p):cdiv(torch.cmul(p, ((p - 1) * (-1))))

   self.R:backward(repr, dG)                             -- accumulate gradients

   -----------------------------------------------------------------------------
   -- Perform REINFORCE Update of parameters
   -----------------------------------------------------------------------------

   if (gameState:isFinal()) then
      local p, dP = self.R:getParameters()

      dW = dP * self.learningRate * (reward - self.baseline)
      p:add(dP)

      dP:zero()                                                -- zero gradients
   end
end


return REINFORCEPlayer
