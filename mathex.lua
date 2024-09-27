-- ███╗   ███╗ █████╗ ████████╗██╗  ██╗███████╗██╗  ██╗
-- ████╗ ████║██╔══██╗╚══██╔══╝██║  ██║██╔════╝╚██╗██╔╝
-- ██╔████╔██║███████║   ██║   ███████║█████╗   ╚███╔╝
-- ██║╚██╔╝██║██╔══██║   ██║   ██╔══██║██╔══╝   ██╔██╗
-- ██║ ╚═╝ ██║██║  ██║   ██║   ██║  ██║███████╗██╔╝ ██╗
-- ╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝
--
-- Regex for equations
--
-- Copyright 2024 ExeVirus
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
--                          Table of Contents
--
--           1. Overview
--           2. Syntax
--           3. Tokenization Implementation
--           4. Mathex Algorithm
--           5. Actual Mathex Function Definition
--           6. Appendix A: Error Codes and their meaning
--           7. Language-Specific Utility Functions
--
--         ___ __   __ ___  ___ __   __ ___  ___ __      __
--        / _ \\ \ / /| __|| _ \\ \ / /|_ _|| __|\ \    / /
--       | (_) |\ V / | _| |   / \ V /  | | | _|  \ \/\/ /
--        \___/  \_/  |___||_|_\  \_/  |___||___|  \_/\_/
--
-- Mathex allows you to specify your input validation logic in a
-- human-readable, verfiable, matinainable way, as opposed to putting
-- validation logic in language specific code that is error prone,
-- time-consuming, and highly specific.
--
-- Mathex provides aims to provide the same interface in every language:
-- 
--     mathex("equation", val1, val2,...valN)
--     mathex("equation", arrayOfValues)
--
-- The return value for a *valid* mathex call is either 0 or 1.
-- Negative values indicate an error during processing.
-- The table of supported processing errors are in Appendix A.
--
-- For lua's mathex library, Error strings are also returned:
----
-- result, errorstr = mathex("equation", val1, val2,...valN)
-- if result < 0 then error(errorstr)
----
--
-- Mathex expects valid IEEE Floating point values for all Value inputs
-- The "equation" systax is as follows:
--
--              ___ __   __ _  _  _____  _   __  __
--             / __|\ \ / /| \| ||_   _|/_\  \ \/ /
--             \__ \ \ V / | .` |  | | / _ \  >  <
--             |___/  |_|  |_|\_|  |_|/_/ \_\/_/\_\
--          (Dare: track # of times you check this section)
--
--    Mathex has 5 different "things" in the language:
--
--               1. Numbers      (###.###)
--               2. Variables    (A, B, C, AA, BB, CC, etc.)
--               3. Math Symbols (+-*/^%&|!=(), etc.)
--               4. Functions    (min, max, abs, etc.)
--               5. Commas       ,
--
--                     Whitespace is ignored.
--
-- C++ Operator Precedence is used, with the addition of ^ for power
--                   See the symbols table below
--
-------------------------------------------------------------------------------------

local tokens = {"Number","Variable","Symbol","Function","Comma",}

local tokensToNum = {}
for i=1, #tokens do
    tokensToNum[tokens[i]] = i
end

local symbols = {
    "(",")",
    "~","!",
    "^",
    "*","/","%",
    "+","-",
    "<<", ">>",
    "<", "<=", ">", ">=",
    "==", "!=",
    "&",
    "|",
    "&&",
    "||",
}

local symbolNumToPrecedence = {
    1,1,
    2,2,
    3,
    4,4,4,
    5,5,
    6,6,
    7,7,7,7,
    8,8,
    9,
    10,
    11,
    12,
}

local symbolToNum = {}
for i=1, #symbols do
    symbolToNum[symbols[i]] = i
end

local functions = {
    "abs", "log", "exp", "sin", "cos", "tan", "asin", "acos", "atan2", "sinh", "cosh", "tanh", "asinh", "acosh", "atanh", "ceil", "floor", "trunc",
    "max", "min", "pow", -- two-argument functions
}

local functionToNum = {}
for i=1, #functions do
    functionToNum[functions[i]] = i
end

local function isTwoArgFunction(id) return id > functionToNum.trunc end

local humanReadableValue = {
    function(v) return v end,           -- Number
    function(v)                         -- Variable
        local numCharacters = tonumber(math.floor(tonumber(v) ^ (1/26)))
        local str = ""
        for i=1,numCharacters do
            str = str .. string.char((i % (26 ^ i))+64)
        end
        return str
    end,
    function(v) return symbols[v] end,  -- Symbol
    function(v) return functions[v] end,-- Function
    function(v) return "," end,         -- Comma
}

-------------------------------------------------------------------------------------
--  _____ ___  _  _____ _  _ ___ ____  _ _____ ___ ___  _  _
-- |_   _/ _ \| |/ / __| \| |_ _|_  / /_\_   _|_ _/ _ \| \| |
--   | || (_) | ' <| _|| .` || | / / / _ \| |  | | (_) | .` |
--   |_| \___/|_|\_\___|_|\_|___/___/_/ \_\_| |___\___/|_|\_|
--               (Fancy term for text->number)
--
--            Tokenization occurs in a single pass
-- During this pass, no errors besides invalid tokens are handled
-- In that case, an error string is returned by tokenize
--
-- Tokens take the form of a table:
-- {
--     type = ["num","var","sym","func"]
--     value = [value,value,enum]
-- }
--
-- However, type is stored as a number, just as all the values
-- * 1 - Numbers are stored as their value
-- * 2 - Vars are stored as their equivalent argument number. I.e A = 1, AB = 28
-- * 3 - Symbols are stored as numbers in order of their precedence,
--          with equivalent precendence grouped next to each other
-- * 4 - Functions are stored as a number
-- * 5 - Commas are stored separately, as they have no precendence
--
-------------------------------------------------------------------------------------
-- Declare all tokenization functions
local tokenize, getNextToken
local handleNumber, handleVariable, handleSymbol, handleFunction, handleComma
local tokenizationError, humanReadableToken

local patterns = {
    Number   = "^%d+%.?%d*",
    Variable = "^%u+",
    Symbol   = "^[%(%)%+%-%*/%%<>=|&%^~!]",
    Function = "^%l+",
    Comma    = "^,"
}

----------- Tokenize
tokenize =  function(expression)
    local tokens = {}
    local pos, token = 1, nil
    while pos < #expression+1 do
        token, pos = getNextToken(expression, pos)
        if (token.type == false) then
            return nil, token.value;
        end
        table.insert(tokens,token)
    end
    return tokens
end

----------- getNextToken()
getNextToken = function(expression, pos)
    local exp = expression:sub(pos)
    if(exp:match(patterns.Number)) then
        return handleNumber(exp, pos)
    elseif(exp:match(patterns.Variable)) then
        return handleVariable(exp, pos)
    elseif(exp:match(patterns.Symbol)) then
        return handleSymbol(exp, pos)
    elseif(exp:match(patterns.Function)) then
        return handleFunction(exp, pos)
    elseif(exp:match(patterns.Comma)) then
        return handleComma(exp, pos)
    else
        return tokenizationError(pos, "Invalid character starting at '" .. expression:sub(pos, pos +5) .. "'")
    end
end

----------- handleNumber()
handleNumber = function(exp, pos)
    local start, stop = exp:find(patterns.Number)
    if(exp:sub(stop,stop) == ".") then
        return tokenizationError(pos+stop-1, "Remove Terminating decimal place '.'")
    end
    return {
        type = tokensToNum.Number,
        value = tonumber(exp:sub(start,stop)),
        pos = pos,
    }, pos + stop
end

----------- handleVariable()
handleVariable = function(exp, pos)
    local function toValue(letter) return string.byte(letter) - 64 end -- helper
    local start, stop = exp:find(patterns.Variable)
    local match = exp:sub(start,stop)
    local value = 0
    for i = 1, #match do
        value = value + toValue(match:sub(i,i)) * 26 ^ (#match-i)
    end
    return {
        type = tokensToNum.Variable,
        value = value,
        pos = pos,
    }, pos + stop
end

----------- handleSymbol()
local symbolMatchingArray -- defined in Language-Specific section
handleSymbol = function(exp, pos)
    local match = nil
    -- find match
    for _, symbolToMatch in ipairs(symbolMatchingArray) do
        if string.sub(exp, 1, #symbolToMatch) == symbolToMatch then
            match = symbolToMatch
            break
        end
    end
    return {
        type = tokensToNum.Symbol,
        value = symbolToNum[match],
        pos = pos,
    }, pos + match:len()
end

----------- handleFunction()
handleFunction = function(exp, pos)
    local match = nil
    -- find match
    for i=1, #functions do
        local functionToMatch = functions[i]
        if string.sub(exp, 1, #functionToMatch) == functionToMatch then
            match = functionToMatch
            break
        end
    end
    if match == nil then
        tokenizationError(pos, "Invalid function '" .. exp:sub(exp:find(patterns.Function)) .. "'")
    end
    return {
        type = tokensToNum.Function,
        value = functionToNum[match],
        pos = pos,
    }, pos + match:len()
end

----------- handleComma()
handleComma = function(exp, pos)
    return {
        type = tokensToNum.Comma,
        value = ",",
        pos = pos,
    }, pos + 1
end

----------- tokenizationError()
tokenizationError = function(pos, str)
    return {
        type = false,
        value = table.concat({"Tokenization Error: ", str, " at ", pos})
    }
end

----------- humanReadableToken()
humanReadableToken = function(token)
    return table.concat({tokens[token.type], " '", humanReadableValue[token.type](token.value), "'", " at ", token.pos})
end

-------------------------------------------------------------------------------------
--          _   _    ___  ___  ___ ___ _____ _  _ __  __
--         /_\ | |  / __|/ _ \| _ \_ _|_   _| || |  \/  |
--        / _ \| |_| (_ | (_) |   /| |  | | | __ | |\/| |
--       /_/ \_\____\___|\___/|_|_\___| |_| |_||_|_|  |_|
--              (Spent all 3 brain cells on this one)
-------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------
local verifyInput
--   _____ _  _ ___   ___ _   _ _  _  ___ _____ ___ ___  _  _
--  |_   _| || | __| | __| | | | \| |/ __|_   _|_ _/ _ \| \| |
--    | | | __ | _|  | _|| |_| | .` | (__  | |  | | (_) | .` |
--    |_| |_||_|___| |_|  \___/|_|\_|\___| |_| |___\___/|_|\_|
--                (The thing we came here for)
-------------------------------------------------------------------------------------
local function mathex(expression, ...)
    local variables, errorstr = verifyInput(expression, ...)
    if errorstr then
        return -1, errorstr
    end
    local tokens, errorstr = tokenize(expression)
    if errorstr then --error
        return -1, errorstr
    end
    for i=1, #tokens do 
        print(humanReadableToken(tokens[i]))
    end

end

--          _   ___ ___ ___ _  _ ___ _____  __    _
--         /_\ | _ \ _ \ __| \| |   \_ _\ \/ /   /_\
--        / _ \|  _/  _/ _|| .` | |) | | >  <   / _ \
--       /_/ \_\_| |_| |___|_|\_|___/___/_/\_\ /_/ \_\
--                  (Appendix A: Error Codes)

--     _   _  _____  ___  _     ___  _____  ___  ___  ___
--    | | | ||_   _||_ _|| |   |_ _||_   _||_ _|| __|/ __|
--    | |_| |  | |   | | | |__  | |   | |   | | | _| \__ \
--     \___/   |_|  |___||____||___|  |_|  |___||___||___/
--         (Language-Specific Utility Functionality)

----------- copy()
local function copy(obj, seen)
    if type(obj) ~= 'table' then return obj end
    if seen and seen[obj] then return seen[obj] end
    local s = seen or {}
    local res = setmetatable({}, getmetatable(obj))
    s[obj] = res
    for k, v in pairs(obj) do res[copy(k, s)] = copy(v, s) end
    return res
end

----------- isArrayOfNumbers()
local function isArrayOfNumbers(t)
    local i = 0
    for _ in pairs(t) do
        i = i + 1
        if type(t[i]) ~= "number" then return false end
        if t[i] == nil then return false end
    end
    return true
end

----------- verifyInput()
verifyInput = function(expression, ...)
    if select('#', ...) == 1 then
        if type(select(1, ...)) == "table" then
            local inputArray = select(1, ...)
            if isArrayOfNumbers(inputArray) then
                return inputArray
            else
                return nil, "mathex() error: your second argument is not a valid array of numbers."
            end
        elseif type(select(1, ...)) ~= "number" then
            return nil, "mathex() error: your second argument is not a table or number."
        end
    else
        local variables = {}
        for i=1, select('#', ...) do
            local var = select(i, ...)
            if type(var) ~= "number" then 
                return nil, "mathex() Error: argument ".. i+1 .." is not a number."
            end
            table.insert(variables, var)
        end
        return variables
    end
end

symbolMatchingArray = copy(symbols)
table.sort(symbolMatchingArray, function(a,b) return #b < #a end)

return {
    tokenize = tokenize,
    humanReadableToken = humanReadableToken,
    mathex = mathex
}