--       ███╗   ███╗ █████╗ ████████╗██╗  ██╗███████╗██╗  ██╗
--       ████╗ ████║██╔══██╗╚══██╔══╝██║  ██║██╔════╝╚██╗██╔╝
--       ██╔████╔██║███████║   ██║   ███████║█████╗   ╚███╔╝
--       ██║╚██╔╝██║██╔══██║   ██║   ██╔══██║██╔══╝   ██╔██╗
--       ██║ ╚═╝ ██║██║  ██║   ██║   ██║  ██║███████╗██╔╝ ██╗
--       ╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝
--
--                     Regex for equations
--
--                   Copyright 2024 ExeVirus
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
--           3. Tokenization Implementation (validation step #1)
--           4. PostTokenization Validation (validation step #2)
--           5. Stack Builder Algorithm (shunting-yard variant, validation step #3)
--           6. Execution Algorithm
--           7. Actual Mathex Function Definition
--           8. Language-Specific Utility Functions
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
-- -1 indicates an error during processing.
--
-- For lua's mathex library, Error strings are *returned*:
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
--                  No Whitespace allowed (for now)!
--
-- C++ Operator Precedence is used, with the addition of ^ for power
--                   See the symbols table below
--
-------------------------------------------------------------------------------------

local types = {"Number","Variable","Symbol","Function","Comma",}

local typesToNum = {}
for i=1, #types do
    typesToNum[types[i]] = i
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
-- 0 left only, 1 right only, 2 both
local symbolNumtoAssociativity = {
    1,0,
    1,1,
    2,
    2,2,2,
    2,2,
    2,2,
    2,2,2,2,
    2,2,
    2,
    2,
    2,
    2
}

local symbolToNum = {}
for i=1, #symbols do
    symbolToNum[symbols[i]] = i
end

local functions = {
    "abs", "acos", "asin", "atan2", "ceil", "cos", "cosh", "deg", "exp", "floor", "log", "rad", "sin", "sinh", "tan", "tanh",
    "max", "min", "pow", -- two argument functions
}

local functionToNum = {}
for i=1, #functions do
    functionToNum[functions[i]] = i
end

local function isTwoArgFunction(id) return id > functionToNum.tanh end

local humanReadableValue = {
    function(v) return v end,           -- Number
    function(v)                         -- Variable
        local numCharacters = tonumber(math.floor(tonumber(v) ^ (1/26)))
        local str = ""
        for i=1,numCharacters do
            str = str .. string.char((v % (26 ^ i))+64)
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
--     pos = position_in_original_expression
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
local postTokenizationValidation

local patterns = {
    Number   = "^%d+%.?%d*",
    Variable = "^%u+",
    Symbol   = "^[%(%)%+%-%*/%%<>=|&%^~!]",
    Function = "^%l+",
    Comma    = "^,",
    Space    = "^%s+"
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
    -- handle spaces by moving position forward past them
    if exp:match(patterns.Space) then
        local start, stop = exp:find(patterns.Space)
        pos = pos + stop
        exp = expression:sub(pos)
    end
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
        type = typesToNum.Number,
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
        type = typesToNum.Variable,
        value = value,
        pos = pos,
    }, pos + stop
end

----------- handleSymbol()
local symbolMatchingArray -- defined in Language-Specific section
handleSymbol = function(exp, pos)
    local match = nil
    -- find match
    for i=1, #symbolMatchingArray do
        local symbolToMatch = symbolMatchingArray[i]
        if #exp:sub(exp:find(patterns.Symbol)) == #symbolToMatch and string.sub(exp, 1, #symbolToMatch) == symbolToMatch then
            match = symbolToMatch
            break
        end
    end
    if match == nil then
        return tokenizationError(pos, "Invalid symbol '" .. exp:sub(exp:find(patterns.Symbol)) .. "'")
    end
    return {
        type = typesToNum.Symbol,
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
        if #exp:sub(exp:find(patterns.Function)) == #functionToMatch and string.sub(exp, 1, #functionToMatch) == functionToMatch then
            match = functionToMatch
            break
        end
    end
    if match == nil then
        return tokenizationError(pos, "Invalid function '" .. exp:sub(exp:find(patterns.Function)) .. "'")
    end
    return {
        type = typesToNum.Function,
        value = functionToNum[match],
        pos = pos,
    }, pos + match:len()
end

----------- handleComma()
handleComma = function(exp, pos)
    return {
        type = typesToNum.Comma,
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
    return table.concat({types[token.type], " '", humanReadableValue[token.type](token.value), "'", " at ", token.pos})
end

-------------------------------------------------------------------------------------
--     __   ___   _    ___ ___   _ _____ ___ ___  _  _   ___
--     \ \ / /_\ | |  |_ _|   \ /_\_   _|_ _/ _ \| \| | |_  )
--      \ V / _ \| |__ | || |) / _ \| |  | | (_) | .` |  / /
--       \_/_/ \_\____|___|___/_/ \_\_| |___\___/|_|\_| /___|
--              (There's actually 2 validation steps)
--
-- Validation happens in three places, tokenization(1), which garuntees
-- that only valid tokens are given. This phase validates:
-- 
-- * Functions having a following opening parenthesis
-- * Each operator has its associative operands (1 or 2) beside it
-- * No operand is to the left of another operand
-- * No operand is to the left of any function
-- * Variables start at A and are contiguous thereafter, i.e. no skipping
-------------------------------------------------------------------------------------
local isLeftAssociative, isRightAssociative
postTokenizationValidation = function(tokens, variables)
    local variableTracker = {} -- will slowly populate
    for i=1, #tokens do
        local last = tokens[i-1]
        local current = tokens[i]
        local next = tokens[i+1]
        local function makeError(token, str)
            return table.concat({"Syntax Error: ", types[token.type], " '", humanReadableValue[token.type](token.value), "' at ", token.pos, str})
        end

    -- Functions require '(''
        if current.type == typesToNum.Function then
            if not (next.type == typesToNum.Symbol and next.value == symbolToNum["("]) then
                return makeError(current, " requires an opening '(' immediately following.")
            end
        elseif current.type == typesToNum.Symbol then
    -- Each left associative operator has a left operand
            if isLeftAssociative(current) then
                if not last then
                    return makeError(current, " requires a value to the left.")
                elseif not (
                                last.type == typesToNum.Number   or 
                                last.type == typesToNum.Variable or
                                (last.type == typesToNum.Symbol and last.value == symbolToNum[")"])
                           ) then
                    return makeError(current, " requires a value to the left.")
                end
            end
    -- Each Right associative operator has a right operand
            if isRightAssociative(current) then
                if not next then
                    return makeError(current, " requires a value to the right.")
                elseif not (
                                next.type == typesToNum.Number   or 
                                next.type == typesToNum.Variable or
                                next.type == typesToNum.Function or
                                (next.type == typesToNum.Symbol and next.value == symbolToNum["("])
                           ) then
                    return makeError(current, " requires a value to the right.")
                end
            end
        elseif current.type == typesToNum.Number or current.type == typesToNum.Variable then
    -- Each operand is not left of any function or operand, or parenthesis
            if next and (
                next.type == typesToNum.Number   or
                next.type == typesToNum.Variable or
                next.type == typesToNum.Function or
                (next.type == typesToNum.Symbol and symbols[next.value] == "(")
                ) then
                return makeError(current, table.concat({" cannot be directly left of ", types[next.type], " '", humanReadableValue[next.type](next.value), "'."}))
            end
    -- Count variables to check at the end
            if current.type == typesToNum.Variable then
                variableTracker[current.value] = true
            end
        end
    end
    -- Count handle Variable mismatches
    local count = 0
    for _ in pairs(variableTracker) do count = count + 1 end
    if count < #variables then
        return table.concat({"Syntax Error: The provided expression uses less variables than the number provided."}) 
    elseif count > #variables then
        return table.concat({"Syntax Error: The provided expression uses more variables than the number provided."}) 
    end
    for i=1, #variables do
        if variableTracker[i] == nil then
            if i > count then
                return table.concat({"Syntax Error: The provided expression uses less variables than the number provided."})
            else
                return table.concat({"Syntax Error: The provided expression skips using variable '", humanReadableValue[typesToNum.Variable](i) ,"'."})
            end
        end
    end
    return nil
end

isLeftAssociative = function(token)
    local associativity = symbolNumtoAssociativity[token.value]
    return associativity == 0 or associativity == 2
end

isRightAssociative = function(token)
    local associativity = symbolNumtoAssociativity[token.value]
    return associativity >= 1
end

-------------------------------------------------------------------------------------
--
--     ___ _____ _   ___ _  __  ___ _   _ ___ _    ___  ___ ___ 
--    / __|_   _/_\ / __| |/ / | _ ) | | |_ _| |  |   \| __| _ \
--    \__ \ | |/ _ \ (__| ' <  | _ \ |_| || || |__| |) | _||   /
--    |___/ |_/_/ \_\___|_|\_\ |___/\___/|___|____|___/|___|_|_\
--                       (And validation step 3)
-------------------------------------------------------------------------------------
local copy, isSymbol, dumpStack, validateArguments
local function buildStack(tokens)
    local outputStack = {}
    local operatorStack = {}
    local function popOperator(token)
        table.insert(outputStack, token)
        operatorStack[#operatorStack] = nil
        return operatorStack[#operatorStack]
    end
    local function makeError(token, str)
        return nil, table.concat({"Syntax Error: ", types[token.type], " '", humanReadableValue[token.type](token.value), "' at ", token.pos, str})
    end

    for i=1, #tokens do
        local token = tokens[i]
        if token.type == typesToNum.Number or token.type == typesToNum.Variable then
    -- Numbers and Variables go directly to output stack
            table.insert(outputStack, token)
        elseif token.type == typesToNum.Function then
    -- All functions go directly to operator stack
            table.insert(operatorStack, token)
        elseif token.type == typesToNum.Symbol then
    -- All '(' go directly to operator stack
            if isSymbol(token, "(") then
                table.insert(operatorStack, token)
    -- All ')' pop operators until a matching '(' is found, pops it, and any function immediately after
            elseif isSymbol(token, ")") then
                local top = operatorStack[#operatorStack]
                if top == nil then
                    return makeError(token, " no matching '(' found.")
                end
                while not isSymbol(top, "(") do
                    table.insert(outputStack, top)
                    operatorStack[#operatorStack] = nil
                    top = operatorStack[#operatorStack]
                    if top == nil then
                        return makeError(token, " no matching '(' found.")
                    end
                end
                -- pop '('
                operatorStack[#operatorStack] = nil
                -- pop function if there
                top = operatorStack[#operatorStack]
                if top and top.type == typesToNum.Function then
                    table.insert(outputStack, top)
                    operatorStack[#operatorStack] = nil --pop
                end
            else
    -- All other operator symbols use precedence and left associativity to determine stack
                local top = operatorStack[#operatorStack]
                -- while there is an operator and it's not '('
                while top and not isSymbol(top, "(") do
                    if symbolNumToPrecedence[top.value] < symbolNumToPrecedence[token.value] then
                        top = popOperator(top)
                    elseif symbolNumToPrecedence[top.value] == symbolNumToPrecedence[token.value] and isLeftAssociative(token) then
                        top = popOperator(top)
                    else
                        break
                    end
                end
                table.insert(operatorStack, token)
            end
    -- Commas pop until they reach a '('
        elseif token.type == typesToNum.Comma then
            local top = operatorStack[#operatorStack]
            while top and not isSymbol(top, "(") do
                top = popOperator(top)
            end
        end
    end
    -- pop the rest of the operatorStack, if any
    local top = operatorStack[#operatorStack]
    while top ~= nil do
        top = popOperator(top)
    end

    -- validate all parenthesis are gone
    for i=1, #outputStack do
        local token = outputStack[i]
        if isSymbol(token, "(") then
            return makeError(token, " no matching ')' found.")
        end
    end

    -- validate all argument requirements are met
    local result, errorstr = validateArguments(outputStack)
    if errorstr ~= nil then
        return nil, errorstr
    end

    return outputStack
end

isSymbol = function(token, sym)
    return token.type == typesToNum.Symbol and symbols[token.value] == sym
end

local validateSymbol, validateFunction
validateArguments = function(inStack)
    local stack = copy(inStack) -- don't modify the original
    local function makeError(token, str)
        return nil, table.concat({"Syntax Error: ", types[token.type], " '", humanReadableValue[token.type](token.value), "' at ", token.pos, str})
    end
    local operandStack = {}
    for i=1, #stack do
        local token = stack[i]
        if token.type == typesToNum.Number then
            table.insert(operandStack, 1)
        elseif token.type == typesToNum.Variable then
            table.insert(operandStack, 1)
        elseif token.type == typesToNum.Symbol then
            local errorstr = validateSymbol(operandStack, token.value)
            if errorstr then
                return makeError(token, errorstr)
            end
        elseif token.type == typesToNum.Function then
            local errorstr = validateFunction(operandStack, token.value)
            if errorstr then
                return makeError(token, errorstr)
            end
        end
    end
end

validateSymbol = function(stack, sym)
    local assoc = symbolNumtoAssociativity[sym]
    if assoc == 0 then
        return " - MAJOR ERROR - there should be no ')' remaining."
    elseif assoc == 1 then
        if #stack < 1 then
            return " no required right operand value."
        end
    else
        if #stack > 1 then -- pop 1
            stack[#stack] = nil
        else
            return " no required first and second operand values."
        end
    end
end

validateFunction = function(stack, func)
    local isTwoArg = isTwoArgFunction(func)
    if not isTwoArg then
        if #stack < 1 then
            return " no required single operand value."
        end
    else
        if #stack > 1 then -- pop 
            stack[#stack] = nil
        else
            return " no required first and second operand values."
        end
    end
end

-------------------------------------------------------------------------------------
--     ___ _____ _   ___ _  __  _____  _____ ___ _   _ _____ ___  ___
--    / __|_   _/_\ / __| |/ / | __\ \/ / __/ __| | | |_   _/ _ \| _ \
--    \__ \ | |/ _ \ (__| ' <  | _| >  <| _| (__| |_| | | || (_) |   /
--    |___/ |_/_/ \_\___|_|\_\ |___/_/\_\___\___|\___/  |_| \___/|_|_\
-------------------------------------------------------------------------------------
local executeSymbol, executeFunction
local function executeStack(stack, variables)
    local operandStack = {}

    for i=1, #stack do
        local token = stack[i]
        if token.type == typesToNum.Number then
            table.insert(operandStack, token.value)
        elseif token.type == typesToNum.Variable then
            table.insert(operandStack, variables[token.value])
        elseif token.type == typesToNum.Symbol then
            executeSymbol(operandStack, token.value)
        elseif token.type == typesToNum.Function then
            executeFunction(operandStack, token.value)
        end
    end

    if #operandStack ~= 1 then
        return nil, "MAJOR ERROR: there are " .. #operandStack .. " numbers on the execution stack."
    end
    return operandStack[1] ~= 0
end

local bit = require("bit")
executeSymbol = function(stack, sym)
    sym = symbols[sym] or sym
    local function pop()
        local val = stack[#stack]
        stack[#stack] = nil
        if tonumber(val) == nil then 
            return 0
        else
            return tonumber(val)
        end
    end
    local function push(val)
        table.insert(stack, val)
    end
    local op2 = pop() -- op2, if relevant is on the top of the stack, always
    if sym == "~" then
        push(bit.bnot(math.floor(op2)))
    elseif sym == "!" then
        if (op2 == 0) then
            push(1)
        else
            push(0)
        end
    elseif sym == "^" then
        push(pop() ^ op2)
    elseif sym == "*" then
        push(pop() * op2)
    elseif sym == "/" then
        push(pop() / op2)
    elseif sym == "%" then
        push(math.floor(pop()) / math.floor(op2))
    elseif sym == "+" then
        push(pop() + op2)
    elseif sym == "-" then
        push(pop() - op2)
    elseif sym == "<<" then
        push(bit.lshift(math.floor(pop()), math.floor(op2)))
    elseif sym == ">>" then
        push(bit.rshift(math.floor(pop()), math.floor(op2)))
    elseif sym == "<" then
        if (pop() < op2) then
            push(1)
        else
            push(0)
        end
    elseif sym == "<=" then
        if (pop() <= op2) then
            push(1)
        else
            push(0)
        end
    elseif sym == ">" then
        if (pop() > op2) then
            push(1)
        else
            push(0)
        end
    elseif sym == ">=" then
        if (pop() >= op2) then
            push(1)
        else
            push(0)
        end
    elseif sym == "==" then
        if (pop() == op2) then
            push(1)
        else
            push(0)
        end
    elseif sym == "!=" then
        if (pop() ~= op2) then
            push(1)
        else
            push(0)
        end
    elseif sym == "&" then
        push(bit.band(math.floor(pop()), math.floor(op2)))
    elseif sym == "&&" then
        if (pop() and op2) then
            push(1)
        else
            push(0)
        end
        push(pop() and op2)
    elseif sym == "|" then
        push(bit.bor(math.floor(pop()), math.floor(op2)))
    elseif sym == "||" then
        if (pop() or op2) then
            push(1)
        else
            push(0)
        end
    else
        error("Unrecognized symbol: " .. sym)
    end
end

-- "abs", "acos", "asin", "atan2", "ceil", "cos", "cosh", "deg", "exp", "floor", "log", "max", "min", "pow", "rad", "sin", "sinh", "tan", "tanh",
executeFunction = function(stack, func)
    func = functions[func] or func
    local function pop()
        local val = stack[#stack]
        stack[#stack] = nil
        return val
    end
    local function push(val)
        table.insert(stack, val)
    end
    local op2 = pop() -- op2, if relevant is on the top of the stack, always
    if func == "abs" then
        push(math.abs(op2))
    elseif func == "acos" then
        push(math.acos(op2))
    elseif func == "asin" then
        push(math.asin(op2))
    elseif func == "atan2" then
        push(math.atan2(op2))
    elseif func == "ceil" then
        push(math.ceil(op2))
    elseif func == "cos" then
        push(math.cos(op2))
    elseif func == "cosh" then
        push(math.cosh(op2))
    elseif func == "deg" then
        push(math.deg(op2))
    elseif func == "exp" then
        push(math.exp(op2))
    elseif func == "floor" then
        push(math.floor(op2))
    elseif func == "log" then
        push(math.log(op2))
    elseif func == "max" then
        push(math.max(pop(), op2))
    elseif func == "min" then
        push(math.min(pop(), op2))
    elseif func == "pow" then
        push(pop()^op2)
    elseif func == "rad" then
        push(math.rad(op2))
    elseif func == "sin" then
        push(math.sin(op2))
    elseif func == "sinh" then
        push(math.sinh(op2))
    elseif func == "tan" then
        push(math.tan(op2))
    elseif func == "tanh" then
        push(math.tanh(op2))
    else
        error("Unrecognized function: " .. func)
    end
end

-- "abs", "acos", "asin", "atan2", "ceil", "cos", "cosh", "deg", "exp", "floor", "log", "rad", "sin", "sinh", "tan", "tanh",
-- "max", "min", "pow", -- two argument functions

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
    if errorstr then
        return -1, errorstr
    end

    local errorstr = postTokenizationValidation(tokens, variables)
    if errorstr then
        return -1, errorstr
    end

    local stack, errorstr = buildStack(tokens)
    if errorstr then
        return -1, errorstr
    end

    -- local toDump = {}
    -- for i=1, #stack do
    --     table.insert(toDump, humanReadableValue[stack[i].type](stack[i].value) .. " ")
    -- end
    -- print(table.concat(toDump))

    local result, errorstr = executeStack(stack, variables)
    if errorstr then
        return -1, errorstr
    end

    return result
end
-------------------------------------------------------------------------------------
--     _   _  _____  ___  _     ___  _____  ___  ___  ___
--    | | | ||_   _||_ _|| |   |_ _||_   _||_ _|| __|/ __|
--    | |_| |  | |   | | | |__  | |   | |   | | | _| \__ \
--     \___/   |_|  |___||____||___|  |_|  |___||___||___/
--         (Language-Specific Utility Functionality)
-------------------------------------------------------------------------------------
----------- copy()
copy = function(obj, seen)
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
        else
            return {select(1, ...)}
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

----------- dumpStack()
dumpStack = function(stack)
    local toDump = {}
    for i=1, #stack do
         table.insert(toDump, humanReadableValue[stack[i].type](stack[i].value) .. " ")
    end
    print(table.concat(toDump))
end

symbolMatchingArray = copy(symbols)
table.sort(symbolMatchingArray, function(a,b) return #b < #a end)

return {
    tokenize = tokenize,
    humanReadableToken = humanReadableToken,
    mathex = mathex
}