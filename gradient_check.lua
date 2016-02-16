-- gradient checker for nn modules

require 'nn'


-- checks that module parameter gradients are computed correctly according to a certain criterion
-- model -> the nn module in use
-- h -> addition to gradients used for checking; should be really small
-- e -> tolerance in gradient difference
-- criterion -> the criterion/error function to be minimized
-- input/correct_out -> dummy values to test the gradients
-- returns: true if gradients are computed correctly, false otherwise
function gradient_check(model, h, e, criterion, input, correct_out)
    -- get parameters and gradients now, after executin local out = model:forward(input)
    local out = model:forward(input)
    local err = criterion:forward(out, correct_out)

    -- get derivatives with respect to the criterion that we are minimizing
    local df_do = criterion:backward(out, correct_out)
    model:backward(input, df_do)

    -- extract params flattened and corresponding derivatives
    local params,dParams = model:getParameters()

    -- definition of derivative ->  h-> 0; dJ/dW = j(W + h) - j(W - h) / (2*h)
    -- computed gradient should be similar to this
    for i=1,params:size(1) do
        local e_i = torch.zeros(params:size())
        local o_val = params[i]
        -- phi_i - eps
        params[i] = params[i] - h
        -- J(phi_i - eps)
        local out1 = criterion:forward(model:forward(input):clone(), correct_out)
        -- phi_i + eps
        params[i] = params[i] + 2 * h
        -- J(phi_i + eps)
        local out2 = criterion:forward(model:forward(input):clone(), correct_out)

        local est_g = (out2 - out1) /  (2 * h) -- estimated gradient
        params[i] = params[i] - h -- original param value

        local my_g = dParams[i]
        local rel_err = math.abs(my_g - est_g) / (math.abs(my_g) + math.abs(est_g)) -- relative error
        if (rel_err > e) then
            print("param_num: "..i)
            print("relative error: "..rel_err)
            print("computed gradient: "..my_g)
            print("estimated gradient: "..est_g)
            return false
        end
    end
    return true
end

-- small test function to prove gradient checker works
function test()
    local input_size = 25
    local output_size = 30
    model = nn.Sequential()
    model:add(nn.Reshape(input_size))
    model:add(nn.Linear(input_size, output_size))
    --model:add(nn.LogSoftMax())
    --model:add(nn.Tanh())
    --model:add(nn.Linear(hidden_size, output_size))
    --criterion = nn.ClassNLLCriterion()
    criterion = nn.MSECriterion()
    --dummy input/output
    i = torch.rand(input_size) * 0.001 
    o = torch.rand(output_size):fill(0)
    o[1] = 1

    r = gradient_check(model, 0.0001, 0.01, criterion, i, o)
    if (r) then
        print("gradient check successful!")
    else
        print("gradient check failed!")
    end
end

--call test
torch.manualSeed(666) -- numărul diavolului
test()
