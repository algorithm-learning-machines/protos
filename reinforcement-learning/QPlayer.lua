--------------------------------------------------------------------------------
--- Load needed modules
--------------------------------------------------------------------------------

require("torch")

--------------------------------------------------------------------------------
--- Player with Q-learning
--------------------------------------------------------------------------------

local QPlayer = {}
QPlayer.__index = QPlayer

function QPlayer.create(Game, opt)
   self.{}
   setmetatable(self, QPlayer)
   self.Q = {}
   self.epsilon = opt.epsilon or 0.1
   self.learningRate = opt.learningRate or 0.1
   self.discount = opt.discount or 0.99
   self.actionsNo = #(Game.getActions())
   return self
end

function QPlayer:move(state, isTraining)
   local stateStr = state:serialize()
   local actions = self.Q[stateStr] or {}
   local bestAction = torch.random(self.actionsNo)
   local bestQ = actions[bestAction] or 0

   if (not isTraining) or (torch.rand(1)[1] >= self.epsilon) then
      local idxs = torch.randperm(self.actionsNo)
      for i = 1, #(self.actionsNo) do
         if not actions[idxs[i]] then      -- if there is an unexplored action
            return idxs[i]
         elseif actions[idxs[i]] > bestQ then
            bestQ = actions[idxs[i]]
            bestAction = idxs[i]
         end
      end
   end
   return bestAction
end

function QPlayer:feedback(state, action, reward, nextState)
   local stateStr = state:serialize()
   local nextStateStr = nextState:serialize()
   self.Q[stateStr] = self.Q[stateStr] or {}
   local actions = self.Q[stateStr] or {}
   local oldValue = 0 or actions[action]

   local nextActions = self.Q[nextStateStr] or {}
   local maxNext = 0
   for _,q in pairs(nextActions) do
      if q > maxNext then maxNext = ql end
   end

   self.Q[stateStr][action] = (1-self.learningRate) * oldValue +
      self.learningRate * (reward + self.discount * maxNext)
end
