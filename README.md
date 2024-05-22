# Mathex

variable check = 5;
if(mathex("A%2!=0",check) {
    odd!
} else {
    even!
}

## Supported tokens:
- Number: 0-9, with optional period . for decimal
- Capital Letters (A, B, C, AA, AB): are variables
- lowercase letters: must be followed by a parenthesis and be a function: abs()
- symbols: +-*/%^| || & && , etc are also functions, just like a calculator
- comparisons are also symbols: !=, ==, >=, >, etc.

## Method

1. Regex is used to tokenize
2. Shunting yard variation using the resulting tokens

## Gemini Output for explanation on variation:

There are two main approaches to handle functions with variable arguments (including subexpressions) within the shunting-yard algorithm:

1. Recursive Shunting-Yard:

    Modify the existing shunting-yard algorithm to be recursive.
    When encountering a function call:
        Push the function name onto the operator stack.
        Call the shunting-yard algorithm recursively, with the closing parenthesis ')' as the stopping token. This parses the function arguments (including subexpressions).
        Once the closing parenthesis is reached, the recursion stops, and you know you have all the arguments.
        Pop the function name from the operator stack and add it to the output queue along with the parsed arguments (in reverse order).

2. Multi-Pass Shunting-Yard:

    Perform the shunting-yard algorithm in two passes:
        Pass 1: Parse the entire expression identifying functions and their arguments.
            Track the number of arguments encountered for each function call.
            During this pass, don't process function calls fully, just mark them with placeholders and the expected number of arguments.
        Pass 2: Perform the regular shunting-yard algorithm again.
            This time, when encountering a function call, you already know the expected number of arguments.
            Pop the arguments from the output queue and treat the function call as a single unit with its arguments.
            Push the entire function call (function name and arguments) onto the operator stack.

Both approaches achieve the same result of converting the expression with functions into postfix notation.

Here are some additional points to consider:

    You'll need a way to store the expected number of arguments for each function. This could be a separate table or symbol information associated with the function name.
    Ensure proper error handling if the number of arguments found doesn't match the expected number for a function call.

Further resources:

    Stack Overflow discussion on shunting-yard with function support: [Stack Overflow shunting yard function ON Stack Overflow stackoverflow.com]
