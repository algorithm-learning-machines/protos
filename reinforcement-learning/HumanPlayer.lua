--------------------------------------------------------------------------------
--- Load needed modules
--------------------------------------------------------------------------------

require("torch")

util = require("util")

--------------------------------------------------------------------------------
--- Human player implementation
--------------------------------------------------------------------------------

local HumanPlayer = {}
HumanPlayer.__index = HumanPlayer

function HumanPlayer.create(Game)
   self = {}
   setmetatable(self, HumanPlayer)
   self.actions = {
      w = Game.NORTH,
      a = Game.WEST,
      s = Game.SOUTH,
      d = Game.EAST
   }
   self.default = Game.NOOP
   return self
end

function HumanPlayer:move()
   local c = util.getch_unix()
   if self.actions[c] then
      return self.actions[c]
   else
      return self.default
   end
end

function HumanPlayer:feedback()
   do end
end

return HumanPlayer
