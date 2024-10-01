local inspect = require("inspect")
local mathex = require("mathex")

print(mathex.mathex("A^B",1,6))
print(mathex.mathex("A^B",2,5))
print(mathex.mathex("A^B",3,4))
print(mathex.mathex("A^B",4,3))
print(mathex.mathex("A^B",5,2))
print(mathex.mathex("A^B",6,1))