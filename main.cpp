#include "mathex.h"

int main(int argc, char** argv)
{
    std::vector<double> arguments({0.1,0.2,0.3});
    std::string expression = "max(1,!2)";
    std::cout << expression << " : " << (mathex::mathex(expression,arguments) ? "TRUE" : "FALSE") << std::endl;
    return 0;
}