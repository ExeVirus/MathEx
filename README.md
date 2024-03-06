# MathEx

A New standard and compliment to XSD Regex for parsing and validation of schemas and data.

It merely returns a boolean result.

# Key Features

- Supports unlimited arguments into the expression
- Garunteed safety and security
- Concise, Human Readable syntax; use Common Mathematical symbols and expressions
- Restrictable to terminable expressions
- Supports tiny implementations for constrained devices

# Supported functions

- \+
- \-
- \*
- /
- %
- ^
- ()
- abs
- max
- min
- log
- pow
- sin
- cos
- tan
- asin
- acos
- atan (atan2)
- sinh
- cosh
- tanh
- asinh
- acosh
- atanh
- ceil
- floor
- <
- \>
- <=
- \>=
- ==
- ||
- &&
- |
- ~
- <<
- \>\>
- !


# Design

This library is implemented using the cpp-peglib library, which builds an AST from a PEG grammer. 
PEG is language agnostic, as is the AST. 

Porting this library is as simple as:

1. Selecting a PEG parser for the language
2. Creating an AST from the PEG parser (if not provided)
3. Recursively parsing the AST and providing the needed math functions to operate on the callbacks.