# Mathex `Regex for Equations`

## Overview

Mathex allows you to specify your input validation logic in a
human-readable, verfiable, matinainable way, as opposed to putting
validation logic in language specific code that is error prone,
time-consuming, and highly specific.

Mathex provides aims to provide the same interface in every language:

```
    mathex("equation", val1, val2,...valN)
    mathex("equation", arrayOfValues)

e.g.
    mathex("max(A,B) > C << 2", val, val, val)
```

The return value for a *valid* mathex call is either 0 or 1.

-1 indicates an error during processing.

For lua's mathex library, Error strings are *returned*:
```lua
result, errorstr = mathex("equation", val1, val2,...valN)
if result < 0 then error(errorstr)
```

Mathex expects valid IEEE Floating point values for all Value inputs

## Syntax

Mathex has 5 different "things" in the language:

1. `Numbers      (###.###)`
2. `Variables    (A, B, C, AA, BB, CC, etc.)`
3. `Math Symbols (+-*/^%&|!=(), etc.)`
4. `Functions    (min, max, abs, etc.)`
5. `Commas       ,`

C++ Operator Precedence is used, with the addition of ^ for power

#### Example:
```lua
"max(5^A, 300) < abs(A) << 5"
```
#### Further details can be read in the comments of [mathex.lua](/mathex.lua) - it's quite detailed
