--------------------------------------------------------------------------------
--- Load needed modules
--------------------------------------------------------------------------------

require("torch")

--------------------------------------------------------------------------------
--- Player with Q-learning
--------------------------------------------------------------------------------

local QPlayer = {}
QPlayer.__index = QPlayer

function QPlayer.create(Game, opt)                       -- intialize new player
   self = {}
   setmetatable(self, QPlayer)
   self.Q = {}                    -- initalize a table for (state-action) values

   self.epsilon = opt.epsilon or 0.1
   self.learningRate = opt.learningRate or 0.1
   self.discount = opt.discount or 0.99

   self.actionsNo = #(Game.getActions())           -- how many actions available
   return self
end

function QPlayer:move(state, isTraining)
   local actions = self.Q[state] or {}               -- knowns state-value pairs
   local bestAction

   if (not isTraining) or (torch.rand(1)[1] >= self.epsilon) then
      local idxs = torch.randperm(self.actionsNo)
      local bestQ = nil
      for i = 1, self.actionsNo do
         if not actions[idxs[i]] then      -- if there is an unexplored action
            return idxs[i]
         elseif (not bestQ) or (actions[idxs[i]] > bestQ) then
            bestQ = actions[idxs[i]]
            bestAction = idxs[i]
         end
      end
   else
      bestAction = torch.random(self.actionsNo)
   end
   return bestAction
end

function QPlayer:feedback(state, action, reward, nextState)
   self.Q[state] = self.Q[state] or {}
   local actions = self.Q[state]
   local oldValue = actions[action]

   local nextActions = self.Q[nextState] or {}
   if nextState then
      if oldValue then
         self.Q[state][action] = (1-self.learningRate) * oldValue +
            self.learningRate * reward
      else
         self.Q[state][action] = self.learningRate * reward
      end
   else
      local maxNext = 0
      for _, q in pairs(nextActions) do
         if q > maxNext then maxNext = q end
      end
      if oldValue then
         self.Q[state][action] = (1-self.learningRate) * oldValue +
            self.learningRate * (reward + self.discount * maxNext)
      else
         self.Q[state][action] = reward + self.discount * maxNext
      end
   end
end

return QPlayer
