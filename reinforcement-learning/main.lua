--------------------------------------------------------------------------------
--- Load modules
--------------------------------------------------------------------------------

require("torch")

--------------------------------------------------------------------------------
--- Define command line arguments (options)
--------------------------------------------------------------------------------

cmd = torch.CmdLine()
cmd:text()
cmd:text("Training players for various games using Reinforcement Learning")
cmd:text()
cmd:text("Options:")
cmd:option("-game", "pacman", "Game to be used")

cmd:option("-seed", 666, "Seed for the random number generator")

--------------------------------------------------------------------------------
--- Parse arguments and let the hammers go (dăm drumul la ciocane)
--------------------------------------------------------------------------------

opt = cmd:parse(arg)

torch.manualSeed(opt.seed)

print("Done!")
