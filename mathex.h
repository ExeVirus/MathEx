//  __  __   ___                       .              __.....__
// |  |/  `.'   `.                   .'|          .-''         '.
// |   .-.  .-.   '              .| <  |         /     .-''"'-.  `.
// |  |  |  |  |  |    __      .' |_ | |        /     /________\   \ ____     _____
// |  |  |  |  |  | .:--.'.  .'     || | .'''-. |                  |`.   \  .'    /
// |  |  |  |  |  |/ |   \ |'--.  .-'| |/.'''. \\    .-------------'  `.  `'    .'
// |  |  |  |  |  |`" __ | |   |  |  |  /    | | \    '-.____...---.    '.    .'
// |__|  |__|  |__| .'.''| |   |  |  | |     | |  `.             .'     .'     `.
//                 / /   | |_  |  '.'| |     | |    `''-...... -'     .'  .'`.   `.
//                 \ \._,\ '/  |   / | '.    | '.                   .'   /    `.   `.
//                  `--'  `"   `'-'  '---'   '---'                 '----'       '----'
#include <math.h>
#include <stdexcept>
#include "peglib.h"

#pragma once

namespace mathex {

// 1. Parse with regex
// 2. Recurse through AST
//     a. For each variable, find the corresponding argument.
//          b. If the variable is larger than max num arguments, error
//          c. track with a count var, number replaced
// 3. After parsing, ensure the count var is equal to number of arguments

uint64_t getNumber(std::string letters)
{
    uint64_t retVal = 0;
    bool lowOrder = true;
    for(int i = 0; i < letters.length(); i++) {
        uint64_t hexValue = static_cast<uint64_t>(letters.at(i)) - 65;
        if(lowOrder) retVal |= hexValue; else retVal |= hexValue << 4;
        lowOrder = !lowOrder;
    }
    return retVal;
}

double parseOperators(std::vector<std::shared_ptr<peg::Ast>> &nodes, std::vector<double>& args, bool& error);

double parseAST(std::shared_ptr<peg::Ast> &ast, std::vector<double>& args, bool& error, double epsilon = std::numeric_limits<double>::epsilon()) {
    enum Opts {
        ATOMIC,
        NUMBER,
        VARIABLE,
        FUNCTIONSINGLE,
        FUNCTIONDOUBLE,
        OPERATORSINGLE,
        OPERATORMULTIPLE,
    };

    std::unordered_map<std::string, uint64_t> operationLookup = {
        {"Atomic", ATOMIC},
        {"Number", NUMBER},
        {"Variable", VARIABLE},
        {"FunctionSingle", FUNCTIONSINGLE},
        {"FunctionDouble", FUNCTIONDOUBLE},
        {"Op1", OPERATORSINGLE},
        {"Op2", OPERATORMULTIPLE},
        {"Op3", OPERATORMULTIPLE},
        {"Op4", OPERATORMULTIPLE},
        {"Op5", OPERATORMULTIPLE},
        {"Op6", OPERATORMULTIPLE},
        {"Op7", OPERATORMULTIPLE},
        {"Op8", OPERATORMULTIPLE},
        {"Op9", OPERATORMULTIPLE},
        {"Op10", OPERATORMULTIPLE},
    };

    std::unordered_map<std::string, double(*)(double)> functionSingle = {
        {"abs", std::abs},
        {"log", std::log},
        {"sin", std::sin},
        {"cos", std::cos},
        {"tan", std::tan},
        {"asin", std::asin},
        {"acos", std::acos},
        {"sinh", std::sinh},
        {"cosh", std::cosh},
        {"tanh", std::tanh},
        {"asinh", std::asinh},
        {"acosh", std::acosh},
        {"atanh", std::atanh},
        {"ceil", std::ceil},
        {"floor", std::floor},
    };
    constexpr auto max = [](double a, double b) { return std::max(a, b); };
    constexpr auto min = [](double a, double b) { return std::min(a, b); };
    std::unordered_map<std::string, double(*)(double, double)> functionDouble = {
        {"max", max},
        {"min", min},
        {"pow", std::pow},
        {"atan2", std::atan2},
    };

    if(!operationLookup.count(ast->name)) {
        error = true;
        std::cerr << "AST error, had an unexpected Name" << std::endl;
        return 0.0;
    }

    std::vector<std::shared_ptr<peg::Ast>> &nodes = ast->nodes;

    // Burn down and simplify the Operation chains
    while(ast->name.substr(0, 2) == "Op") {
        nodes = ast->nodes;
        switch(operationLookup[ast->name]) {
            case OPERATORSINGLE:
                break;
            default: //OPERATORMULTIPLE
                break;
        }
    }

    //Now they are all atomics:
    switch(operationLookup[ast->nodes[0]->name]) {
        case FUNCTIONSINGLE:
            return functionSingle[ast->nodes[1]->token_to_string()](parseAST(ast->nodes[2], args, error, epsilon));
        case FUNCTIONDOUBLE:
            return functionDouble[ast->nodes[1]->token_to_string()](parseAST(ast->nodes[2], args, error, epsilon), parseAST(ast->nodes[3], args, error, epsilon));
        case NUMBER:
            return ast->token_to_number<double>();
        case VARIABLE: {
            auto varNum = getNumber(ast->token_to_string());
            if(varNum-1 > args.size()) {
                std::cerr << ast->token_to_string() << " is too large for the number of arguments provided." << std::endl;
                error = true;
                return std::numeric_limits<double>::quiet_NaN();
            }
            return args[varNum];
        }
        case OPERATORSINGLE: {
            break;
        }
        default:
            std::cerr << ast->nodes[0]->name << " is not a valid operation." << std::endl;
            error = true;
            return std::numeric_limits<double>::quiet_NaN();
    }
}

double parseOperators(std::vector<std::shared_ptr<peg::Ast>> &nodes, std::vector<double>& args, bool& error)
{
    return 0.0;
    //https://en.cppreference.com/w/cpp/language/operator_precedence
}

bool evaluateMathexAST(std::shared_ptr<peg::Ast> &ast, std::vector<double>& args, double epsilon = std::numeric_limits<double>::epsilon()) {
    bool error = false;
    double result = parseAST(ast, args, error);
    return !error && (std::abs(result) > epsilon);
}

int64_t mathex(std::string exp, std::vector<double>& args)
{
    peg::parser parser(R"(
        Atomic          <-  Number
                        /   Variable
                        /   FunctionSingle '(' Op10 ')'
                        /   FunctionDouble '(' Op10 ',' Op10 ')'
                        /   '(' Op10 ')'
        Number          <-  [0-9]+ '.' [0-9]+
                        /   [0-9]+
        Variable        <-  [A-P]+
        FunctionSingle  <-  'abs'
                        /   'log'
                        /   'sin'
                        /   'cos'
                        /   'tan'
                        /   'asin'
                        /   'acos'
                        /   'sinh'
                        /   'cosh'
                        /   'tanh'
                        /   'asinh'
                        /   'acosh'
                        /   'atanh2'
                        /   'ceil'
                        /   'floor'
        FunctionDouble  <-  'max'
                        /   'min'
                        /   'pow'
                        /   'atan2'
        Op1             <-  '!' Atomic
                        /   '~' Atomic
                        /   Atomic
          mul  <-  '*' / '/' / '%'
        Op2             <-  Op1 (mul Op1)*
          add  <-  '+' / '-'
        Op3             <-  Op2 (add Op2)*
          Comp <-  '<' / '>' / '<=' / '>='
        Op4             <-  Op3 (Comp Op3)*
          Equ  <-  '==' / '!='
        Op5             <-  Op4 (Equ Op4)*
        Op6             <-  Op5 ('&' Op5)*
        Op7             <-  Op6 ('^' Op6)*
        Op8             <-  Op7 ('|' Op7)*
        Op9             <-  Op8 ('&&' Op8)*
        Op10            <-  Op9 ('||' Op9)*
    )",peg::Rules());
    parser.enable_ast();
    parser.enable_packrat_parsing();

    std::shared_ptr<peg::Ast> ast;
    if (parser.parse(exp, ast)) {
        //ast = parser.optimize_ast(ast);
        std::cout << ast_to_s(ast);
        evaluateMathexAST(ast, args);
        //std::cout << exp << " = " << eval(*ast) << std::endl;
        return 0;
    } else {
        //error
    }
    return true;
}


}