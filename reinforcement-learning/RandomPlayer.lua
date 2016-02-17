--------------------------------------------------------------------------------
--- Load needed modules
--------------------------------------------------------------------------------

require("torch")

--------------------------------------------------------------------------------
--- Random player implementation
--------------------------------------------------------------------------------

local RandomPlayer = {}
RandomPlayer.__index = RandomPlayer

function RandomPlayer.create(Game)
   self = {}
   setmetatable(self, RandomPlayer)
   self.actionsNo = #(Game.getActions())
   return self
end

function RandomPlayer:move()
   return torch.random(self.actionsNo)
end

function RandomPlayer:feedback()
   do end
end

return RandomPlayer
