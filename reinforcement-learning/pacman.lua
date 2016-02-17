--------------------------------------------------------------------------------
--- Load modules
--------------------------------------------------------------------------------

require("torch")
local util = require("util")

--------------------------------------------------------------------------------
--- Description

--- Pacman is in a maze. He must collect magic '$'s
--- Pacman and the monsters take turns.
--- After pacman and monsters made their move, treats are 'decayed'
--- i.e. after a predefined time, treats disappear and regenerate in new
--- empty positions.
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
--- Implement pacman as a game
--------------------------------------------------------------------------------

--- Actions

local actionNames = {"north", "east", "south", "west", "noop"}
local getActionNames = function() return util.deepcopy(actionNames); end

local actionEffects = {          -- the effects of an action on pacman's postion
   north = { dy = -1, dx =  0},                                    -- move north
   east  = { dy =  0, dx =  1},                                     -- move east
   south = { dy =  1, dx =  0},                                    -- move south
   west  = { dy =  0, dx = -1},                                     -- move west
   noop  = { dy =  0, dx =  0}                                     -- do nothing
}

--- Cells

local EMPTY = "."                            -- empty cell, anything can go here
local WALL = "+"                                         -- great asciinese wall
local PACMAN = "P"                                                   -- our hero
local MONSTER = "M"                        -- bad bad monster, run away from him
local TREAT = "$"                                                     -- delight

--- Miscellaneous

local pacmanLives = 3                         -- how many live does the guy have
local treatLife = 10                    -- for how many rounds does a candy live

--------------------------------------------------------------------------------
--- The PacmanState class
--------------------------------------------------------------------------------

local PacmanState = {}
PacmanState.__index = PacmanState


PacmanState.NORTH = 1
PacmanState.EAST = 2
PacmanState.SOUTH = 3
PacmanState.WEST = 4
PacmanState.NOOP = 5

function PacmanState:__getRandomEmptyCell()
   local row = torch.random(self.height)
   local col = torch.random(self.width)
   while self.maze[row][col] ~= EMPTY do
      row = torch.random(self.height)
      col = torch.random(self.width)
   end
   return row, col
end

function PacmanState.create(opt)        -- returns the initial state of the game
   -----------------------------------------------------------------------------
   --- Create "object"
   -----------------------------------------------------------------------------
   self = {}
   setmetatable(self, PacmanState)
   -----------------------------------------------------------------------------
   --- Configure fields
   -----------------------------------------------------------------------------
   if getmetatable(opt) == PacmanState then                 -- used when cloning

      --- 1. Copy maze
      self.height = opt.height
      self.width = opt.width
      self.maze = {}
      for row, originalCells in pairs(opt.maze) do
         local cells = {}
         for col, cell in pairs(originalCells) do cells[col] = cell end
         self.maze[row] = cells
      end
      self.radius = opt.radius

      --- 2. The walls are the same

      --- 3. The monsters
      self.monsters = util.deepcopy(opt.monsters)

      --- 4. The monsters
      self.pacman = util.deepcopy(opt.pacman)

      --- 5. The treats
      self.treats = util.deepcopy(opt.treats)

      --- 6. Miscellaneous
      self.score = opt.score
      self.lives = opt.lives
      self.lastAction = opt.lastAction
   else                                                     -- used with options

      --- 1. Create maze
      self.height = opt.height or 10
      self.width = opt.width or 10
      self.maze = {}
      for row = 1, self.height do
         local cells = {}
         for col = 1, self.width do cells[#cells+1] = EMPTY; end
         self.maze[#(self.maze)+1] = cells
      end
      self.radius = opt.radius or 0

      --- 2. The walls
      if opt.walls ~= "random" then
         for coordsString in string.gmatch(opt.walls, "[%d]+,[%d]+") do
            local coords = coordsString:split(",")
            local y = tonumber(coords[1])
            local x = tonumber(coords[2])
            self.maze[y][x] = WALL
         end
      else                                              -- put some random walls
         if self.width > 4 then
            local row = torch.random(self.height - 2) + 1
            local startCol = torch.random(self.width - 4) + 1
            local stopCol = torch.random(self.width - startCol - 2) + startCol
            for col = startCol, stopCol do self.maze[row][col] = WALL; end
         end -- if self.width > 4
         if self.height > 4 then
            local col = torch.random(self.width - 2) + 1
            local startRow = torch.random(self.height - 4) + 1
            local stopRow = torch.random(self.height - startRow - 2) + startRow
            for row = startRow, stopRow do self.maze[row][col] = WALL; end
         end -- if self.height > 4
      end

      --- 3. The monsters
      self.monsters = {}
      if opt.monsters then
         for coordsString in string.gmatch(opt.monsters, "[%d]+,[%d]+") do
            local coords = coordsSring:split(",")
            local row = tonumber(coords[1])
            local col = tonumber(coords[2])
            assert(self.maze[row][col] == "EMPTY", "cannot place monster there")
            self.maze[row][col] = MONSTER
            self.monsters[#(self.monsters)+1] = {y = row, x = col}
         end
      else                                           -- put some random monsters
         local monstersNo = opt.monstersNo or 4
         while monstersNo > 0 do
            local row, col = self:__getRandomEmptyCell()
            self.maze[row][col] = MONSTER
            self.monsters[#(self.monsters)+1] = {y = row, x = col}
            monstersNo = monstersNo - 1
         end -- while monstersNo > 0
      end

      --- 4. The Pacman
      if opt.pacman then
         local coords = opt.pacman:split(",")
         local row = tonumber(coords[1])
         local col = tonumber(coords[2])
         assert(self.maze[row][col] == "EMPTY", "cannot place pacman there")
         self.maze[row][col] = PACMAN
         self.pacman = {y = row, x = col}
      else                                  -- place the pacman in a random cell
         local row, col = self:__getRandomEmptyCell()
         self.maze[row][col] = PACMAN
         self.pacman = {y = row, x = col}
      end

      --- 5. The treats
      self.treats = {}
      if opt.treats then
         for coordsString in string.gmatch(opt.treats, "[%d]+,[%d]+") do
            local coords = coordsSring:split(",")
            local row = tonumber(coords[1])
            local col = tonumber(coords[2])
            -- treats spawn in empty cells
            assert(self.maze[row][col] == "EMPTY", "cannot place treat there")
            self.maze[row][col] = TREAT
            self.treats[#(self.treats)+1] = {y= row, x= col, life= treatLife}
         end
      else                                           -- put some random monsters
         local treatsNo = opt.treatsNo or 4
         while treatsNo > 0 do
            local row, col = self:__getRandomEmptyCell()
            self.maze[row][col] = TREAT
            self.treats[#(self.treats)+1] = {y= row, x= col, life= treatLife}
            treatsNo = treatsNo - 1
         end -- while monstersNo > 0
      end

      --- 6. Miscellaneous
      self.score = 0
      self.step = 0
      self.lives = pacmanLives
      self.lastAction = nil
   end

   return self
end

function PacmanState:__movePacman(action)
   self.lastAction = actionNames[action]
   self.maze[self.pacman.y][self.pacman.x] = EMPTY        -- erase previous cell
   local dCoords = actionEffects[actionNames[action]]
   local newY = dCoords.dy + self.pacman.y                 -- compute target row
   local newX = dCoords.dx + self.pacman.x                 -- compute target col

   if newY < 1 or newY > self.height or newX < 1 or newX > self.width then
      self.maze[self.pacman.y][self.pacman.x] = PACMAN           -- pacman stays
      return 0, "Pacman hit the wall!"
   elseif self.maze[newY][newX] == EMPTY then                     -- boring move
      self.pacman.y, self.pacman.x = newY, newX
      self.maze[self.pacman.y][self.pacman.x] = PACMAN
      return 0, "Pacman moved to new cell."
   elseif self.maze[newY][newX] == MONSTER then     -- pacman stepped on monster
      self.lives = self.lives - 1                                -- he dies once
      self.score = self.score - 10                            -- loses 10 points
      self.pacman.y, self.pacman.x = self:__getRandomEmptyCell()
      self.maze[self.pacman.y][self.pacman.x] = PACMAN               -- respawns
      return -10, "Pacman ran into monster!"
   elseif self.maze[newY][newX] == TREAT then            -- pacman grabbed treat
      self.score = self.score + 2
      self.pacman.y, self.pacman.x = newY, newX
      self.maze[self.pacman.y][self.pacman.x] = PACMAN
      return 1, "Pacman grabbed a cookie!"
   elseif self.maze[newY][newX] == WALL then
      self.maze[self.pacman.y][self.pacman.x] = PACMAN           -- pacman stays
      return 0, "Pacman hit the wall!"
   else
      assert(false)
   end
end


function PacmanState:__chooseMonsterMove(y, x)
   local bestActions = {{y  = y, x = x}}                  -- best action is noop
   local minDistance = self.width + self.height

   for _, actionName in pairs(actionNames) do
      local dCoords = actionEffects[actionName]
      local newY = dCoords.dy + y                          -- compute target row
      local newX = dCoords.dx + x                          -- compute target col
      local isOK =
         not (newY < 1 or newY > self.height or newX < 1 or newX > self.width)
      if isOK then
         if self.maze[newY][newX] == EMPTY then                 -- an empty cell
            local distance =
               math.abs(newY - self.pacman.y) + math.abs(newX - self.pacman.x)
            if distance < minDistance then
               bestActions = {{y  = newY, x = newX}}
               minDistance = distance
            elseif distance == minDistance then
               bestActions[#bestActions + 1] = {y  = newY, x = newX}
            end
         elseif self.maze[newY][newX] == PACMAN then
            return newY, newX                     -- shortcut if pacman in range
         end
      end
   end -- for
   local randomAction = torch.random(#bestActions)
   return bestActions[randomAction].y, bestActions[randomAction].x
end

function PacmanState:__moveMonsters()
   local reward = 0
   local message = "Monsters chase the pacman."
   local monstersOrder = torch.randperm(#(self.monsters))
   for i = 1, #(self.monsters) do
      local idx = monstersOrder[i]
      self.maze[self.monsters[idx].y][self.monsters[idx].x] = EMPTY
      local newY, newX =
         self:__chooseMonsterMove(self.monsters[idx].y, self.monsters[idx].x)
      if self.maze[newY][newX] == EMPTY then
         self.monsters[idx].y, self.monsters[idx].x = newY, newX
         self.maze[newY][newX] = MONSTER
      elseif self.maze[newY][newX] == PACMAN then
         self.monsters[idx].y, self.monsters[idx].x = newY, newX
         self.maze[newY][newX] = MONSTER
         self.lives = self.lives - 1                             -- he dies once
         self.score = self.score - 10                         -- loses 10 points
         self.pacman.y, self.pacman.x = self:__getRandomEmptyCell()
         self.maze[self.pacman.y][self.pacman.x] = PACMAN            -- respawns
         reward = reward - 10
         message = "Monsters got the pacman."
      else
         assert(false)
      end
   end
   return reward, message
end

function PacmanState:__decayTreats()
   for i = 1, #(self.treats) do                              -- check all treats
      local treat = self.treats[i]
      if treat.life <= 1 or (self.maze[treat.y][treat.x] ~= TREAT) then
         if self.maze[treat.y][treat.x] == TREAT then           -- if treat aged
            self.maze[treat.y][treat.x] = EMPTY           -- erase previous cell
         end
         treat.y, treat.x = self:__getRandomEmptyCell()
         self.maze[treat.y][treat.x] = TREAT
         treat.life = treatLife
      else                                                     -- treat survived
         treat.life = treat.life - 1
      end
   end
end

function PacmanState:applyAction(action)      -- player performs action in state
   local reward1, message1 = self:__movePacman(action)            -- move pacman
   local reward2, message2 = self:__moveMonsters()              -- move monsters
   self:__decayTreats()                                          -- decay treats
   local reward = reward1 + reward2                      -- compute total reward
   local message = message1 .. " " .. message2
   self.step = self.step + 1
   return reward, message                                      -- returns reward
end

function PacmanState.getActions()          -- STATIC: returns the set of actions
   return getActionNames()
end

function PacmanState:isFinal()               -- checks if a given state is final
   return (self.lives < 1) or (self.step >= 100)
end

function PacmanState:__getScreen()

   screen = "=="                                                   -- top border
   for i = 1, self.width do screen = screen .. "==" end
   screen = screen .. "=\n"

   local fmt = "Score:%" .. (self.width * 2 + 3 - 6) .. "d\n"           -- score
   screen = screen .. string.format(fmt, self.score)

   fmt = "Lives:%" .. (self.width * 2 + 3 - 6) .. "d\n"            -- lives left
   screen = screen .. string.format(fmt, self.lives)

   fmt = "Last:%" .. (self.width * 2 + 3 - 5) .. "s\n"            -- last action
   screen = screen .. string.format(fmt, self.lastAction or "")

   screen = screen .. "+-"                                           -- top wall
   for i = 1, self.width do screen = screen .. "--" end
   screen = screen .. "+\n"

   for row = 1, self.height do                                       -- the rows
      screen = screen .. "| "
      local cells = self.maze[row]
      for col = 1, self.width do screen = screen .. cells[col] .. " "; end
      screen = screen .. "|\n"
   end

   screen = screen .. "+-"                                        -- bottom wall
   for i = 1, self.width do screen = screen .. "--" end
   screen = screen .. "+\n"

   screen = screen .. "=="                                      -- bottom border
   for i = 1, self.width do screen = screen .. "==" end
   screen = screen .. "=\n"

   return screen
end

function PacmanState:display()                         -- displays a given state
   io.write(self:__getScreen())
end

function PacmanState:serialize()                     -- serializes a given state
   local stateString = ""
   if self.radius == 0 then
      for row = 1, self.height do
         stateString = stateString .. table.concat(self.maze[row])
      end
      stateString = stateString .. "|" .. self.lives
      return stateString
   else
      local topPadding = math.max(0, self.radius - self.pacman.y + 1)
      local bottomPadding =
         math.max(0, self.pacman.y - self.height + self.radius)

      local leftPadding = math.max(0, self.radius - self.pacman.x + 1)
      local rightPadding = math.max(0, self.pacman.x - self.width + self.radius)

      local startRow = math.max(1, self.pacman.y - self.radius)
      local stopRow = math.min(self.height, self.pacman.y + self.radius)

      local startCol = math.max(1, self.pacman.x - self.radius)
      local stopCol = math.min(self.width, self.pacman.x + self.radius)

      if topPadding > 0 then
         stateString = stateString ..
            string.rep(string.rep(WALL, self.radius*2+1) .. "\n", topPadding)
      end

      for row = startRow, stopRow do
         stateString = stateString .. string.rep(WALL, leftPadding)
         for col = startCol, stopCol do
            stateString = stateString .. self.maze[row][col]
         end
         stateString = stateString .. string.rep(WALL, rightPadding) .. "\n"
      end

      if bottomPadding > 0 then
         stateString = stateString ..
            string.rep(string.rep(WALL, self.radius*2+1) .. "\n", bottomPadding)
      end
      return stateString
   end
end

function PacmanState:clone()              -- creates a copy of the current state
   return PacmanState.create(self)
end

function PacmanState:reset()                     -- go back to the initial state
   assert(false, "Not implemented yet!")
   -- TODO: not implemented
end

function PacmanState:getScore()
   return self.score
end

return PacmanState



--[[

event_list = {"pac_moved", "pac_got_treat", "pac_got_eaten", "monsters_moved"} -- list of events, for reference


-- reinit maze to initial state
function re_init()
    local pac_pos = {3,4}
    local dim_x = 8
    local dim_y = 8
    local treat_pos = {{6,6}}
    local monster_pos = {{4,6}, {2,2}}
    local wall_pos = {{3,3}, {4,3}, {5,3}}
    init_maze(dim_y, dim_x, pac_pos, monster_pos, treat_pos, wall_pos)
end


-- get all free cells in maze
function get_free_positions()
    local dim_y = #maze
    local dim_x = #maze[1]
    local free_cells = {}
    for i=1,dim_y do
        for j=1,dim_x do
            if (maze[i][j] == ".") then
                free_cells[#free_cells + 1] = {i,j}
            end
        end
    end
    return free_cells
end

-- launch an iteration of the game
-- main function
function play()
    local pac_pos = {3,4}
    local dim_x = 8
    local dim_y = 8
    local treat_pos = {{6,6}}
    local monster_pos = {{4,6}, {2,2}}
    local wall_pos = {{3,3}, {4,3}, {5,3}}
    init_maze(dim_y, dim_x, pac_pos, monster_pos, treat_pos, wall_pos)
    print_maze()
    while(true) do
        io.write("----------------------\n")
        pac_turn()
        io.stdin:read'*l'

        monster_turn()
        io.stdin:read'*l'
        decay_treats()
    end
end
-- let the game begin
play()
--]]
