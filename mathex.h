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

// 1. Parse with PEG Grammar
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

double parseAST(const peg::Ast &ast, std::vector<double>& args, bool& error) {
    constexpr uint64_t EXPRESSION_ATOMIC(0);
    constexpr uint64_t NUMBER(1);
    constexpr uint64_t VARIABLE(2);
    constexpr uint64_t FUNCTION(3);
    constexpr uint64_t OPERATOR(4);

    std::unordered_map<std::string, uint64_t> operationLookup = {
        {"Expression", EXPRESSION_ATOMIC},
        {"Atomic", EXPRESSION_ATOMIC},
        {"Number", NUMBER},
        {"Variable", VARIABLE},
        {"Function", FUNCTION},
        {"Operator", OPERATOR},
    };

    if(!operationLookup.count(ast.name)) {
        error = true;
        std::cerr << "AST error, had an unexpected Name" << std::endl;
        return 0.0;
    }

    const auto &nodes = ast.nodes;

    switch(operationLookup[ast.name]) {
        case EXPRESSION_ATOMIC:
            return parseAST(*nodes[1], args, error);
        case NUMBER:
            return nodes[0]->token_to_number<double>();
            break;
        case VARIABLE:
            auto varNum = getNumber(nodes[0]->token_to_string());
            //TODO
            break;
        case FUNCTION:
            //TODO
            break;
        case OPERATOR:
            //TODO
            break;
    }
}

bool evaluateMathexAST(const peg::Ast &ast, std::vector<double>& args, double epislon = std::numeric_limits<double>::epsilon()) {
    bool error = false;
    double result = parseAST(ast, args, error);
    return !error && (std::abs(result) < epislon);
}

int64_t mathex(std::string exp, std::vector<double>& args)
{
    peg::parser parser(R"(
        Expression  <-  Atomic (Operator Atomic)*
        Atomic      <-  Number
                    /   Variable
                    /   Function '(' Expression ')'
                    /   '(' Expression ')'
        Number      <-  [0-9]+ '.' [0-9]+
                    /   [0-9]+
        Variable    <-  [A-P]+
        Function    <-  'abs'
                    /   'max'
                    /   'min'
                    /   'log'
                    /   'pow'
                    /   'sin'
                    /   'cos'
                    /   'tan'
                    /   'asin'
                    /   'acos'
                    /   'atan2'
                    /   'sinh'
                    /   'cosh'
                    /   'tanh'
                    /   'asinh'
                    /   'acosh'
                    /   'atanh2'
                    /   'ceil'
                    /   'floor'
        Operator    <-  '+'
                    /   '-'
                    /   '*'
                    /   '/'
                    /   '%'
                    /   '<'
                    /   '>'
                    /   '<='
                    /   '>='
                    /   '=='
                    /   '||'
                    /   '&&'
                    /   '&'
                    /   '|'
                    /   '^'
                    /   '~'
                    /   '!'
    )",peg::Rules());
    parser.enable_ast();
    parser.enable_packrat_parsing();

    std::shared_ptr<peg::Ast> ast;
    if (parser.parse(exp, ast)) {
        //ast = parser.optimize_ast(ast);
        std::cout << ast_to_s(ast);
        //std::cout << exp << " = " << eval(*ast) << std::endl;
        return 0;
    } else {
        //error
    }
    return true;
}


}