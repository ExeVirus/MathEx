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

1. Regex/patterns(lua) is used to tokenize
2. Shunting yard variation using the resulting tokens

# Some background:
https://www.geeksforgeeks.org/java-program-to-implement-shunting-yard-algorithm/
https://en.wikipedia.org/wiki/Shunting_yard_algorithm
https://en.wikipedia.org/wiki/Operator-precedence_parser

## Gemini 1.5 flash Output for explanation on variation:

Let's break down how to handle functions and commas in your shunting-yard algorithm.

**Shunting Yard Fundamentals**

The shunting yard algorithm, originally developed by Edsger W. Dijkstra, is a method for converting infix mathematical expressions (where operators appear between operands) into postfix notation (operators follow operands). This postfix form is easier for computers to evaluate directly.

**Handling Functions and Commas**

1. **Tokenization:** You've already done this, but it's crucial. Your input expression needs to be broken down into individual tokens (numbers, operators, function names, commas).

2. **Operator Precedence:** Define the precedence of operators (including functions) to determine the order of evaluation.  Functions generally have higher precedence than most operators.

3. **Function Handling:**

   * **Identify functions:** Look for tokens representing function names.
   * **Push functions onto the operator stack:** Functions are treated as operators with high precedence.
   * **Process Commas:** Commas serve as delimiters within function arguments.
      * When you encounter a comma, keep pushing arguments onto the output queue.
      * Once a closing parenthesis is encountered, pop the function from the operator stack and add it to the output queue.
      * Push the function onto the operator stack.

4. **Parenthesis Handling:**
   * **Opening parenthesis ( ):** Push the parenthesis onto the operator stack.
   * **Closing parenthesis ):** Pop operators from the stack until an opening parenthesis is found. Discard both the opening and closing parentheses.

5. **Operator Stack:**
   * **Push operators onto the stack:** When you encounter an operator, compare its precedence to the top operator on the stack.
     * If the current operator has higher precedence, push it onto the stack.
     * If the current operator has lower or equal precedence, pop operators from the stack and add them to the output queue until you encounter a lower-precedence operator or an opening parenthesis. 
   * **Pop all remaining operators:** After processing all input tokens, pop all remaining operators from the stack and add them to the output queue.

**Example: `max(2 + 3, 5)`**

1. **Tokens:**  `max`, `(`, `2`, `+`, `3`, `)`, `,`, `5`
2. **Output Queue:**  `2`, `3`, `+`, `5`, `max` 

**Explanation:**

* **`max`:**  Pushed onto the operator stack (function).
* **`(`:** Pushed onto the operator stack.
* **`2`, `3`, `+`:** Pushed onto the output queue.
* **`)`:** Pop `+` from the operator stack and push it onto the output queue. Pop `(` and discard it.
* **`,`:** Push `max` from the operator stack onto the output queue and push it back onto the operator stack.
* **`5`:** Push onto the output queue.
* **End of input:** Pop `max` from the operator stack and push it onto the output queue.

**Postfix notation:** `2 3 + 5 max` 

**Key Points**

* **Function Precedence:** Make sure your precedence rules prioritize functions over most other operators.
* **Commas:** Use commas as delimiters within function arguments to separate them.
* **Output Queue:** The final output queue contains the postfix expression ready for evaluation.

**Let me know if you have any more specific questions about handling functions and commas in the shunting-yard algorithm!** 

(3+4)*5^max(6+3,3)

3 4 + 5 6 3 + 3 max ^ *
7 5 6 3 + 3 max ^ *
7 5 9 3 max ^ *
7 5 9 ^ *
