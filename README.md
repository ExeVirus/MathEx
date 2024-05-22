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
