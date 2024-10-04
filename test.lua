local inspect = require("inspect")
local mathex = require("mathex")
math.randomseed(3)

local symbols = {
    "(",")","~","!","^","*","/","%","+","-","<<", ">>","<", "<=", ">", ">=","==", "!=","&","|","&&","||",","
}
local functions = {
    "abs(", "acos(", "asin(", "atan2(", "ceil(", "cos(", "cosh(", "deg(", "exp(", "floor(", "log(", "max(", "min(", "pow(", "rad(", "sin(", "sinh(", "tan(", "tanh(",
}
local function numToVariableName(v) -- Variable
    local numCharacters = tonumber(math.floor(tonumber(v) ^ (1/26)))
    local str = ""
    for i=1,numCharacters do
        str = str .. string.char((v % (26 ^ i))+64)
    end
    return str
end

local function generateFullRandomExpression()
    local len = math.random(1,100)
    local numVariables = 0
    local expr = {}
    for i=1, len do
        local whichType = math.random(1,4)
        if whichType == 1 then -- symbol
            table.insert(expr, symbols[math.random(1,#symbols)])
        elseif whichType == 2 then -- function
            table.insert(expr, functions[math.random(1,#functions)])
        elseif whichType == 3 then -- number
            table.insert(expr, math.random() * 1000)
        else -- variable
            numVariables = numVariables + 1
            table.insert(expr, numToVariableName(numVariables))
        end
    end
    return table.concat(expr), numVariables
end

local function generateArray(num)
    local numbers = {}
    for i=1, num do
        table.insert(numbers, math.random()*20-40)
    end
    return numbers
end

local function doRandomMathex()
    local expr, numVars = generateFullRandomExpression()
    local array = generateArray(numVars)
    local result, errorstr = mathex.mathex(expr,array)
end

local function doValidMathex()
    local expr, numVars = generateValidExpression()
    local array = generateArray(numVars)
    local result, errorstr = mathex.mathex(expr,array)
end

local start = os.clock()
local numToExecute = 5000000
for i=1, numToExecute do
    doRandomMathex()
end
local elapsed = os.clock() - start
print("Elapsed time:", elapsed, "seconds")
print("Number Processed per second: ", numToExecute / elapsed)