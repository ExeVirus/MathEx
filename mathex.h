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
#include "peglib.h"

#pragma once

namespace mathex {

// 1. Count number of variables given to the function
// 2. Figure out what letter combination that count == (i.e. 27 = AA)
// 3. Walk the string, looking for capital letter groupings AAA
//     a. Note the letters found in an ordered Set
//          1. If a group is already present, error
//          2. If Set.size() > number expected, error
//     b. If find A and find count letter (e.g. AFE), note that
//     c. Replace the captured string with the right variable entry
// 4. Once done walking, if Count != Number Found or Not A and or !AFE, then error
// 5. Now we have a single string to parse with Peg... do so, returning errors as needed

std::string getLetters(uint64_t num)
{
    num--;
    if(num == 0) {
        return "A";
    }
    std::string retString;
    while(num > 0) {
        retString += static_cast<char>((num % 26)+65);
        num = num / 26;
    }
    return retString;
}

uint64_t getNumber(std::string letters)
{
    uint64_t retVal = 0;
    for(int i = 0; i < letters.length(); i++) {
        retVal += static_cast<uint8_t>(letters.at(i)-65);
    }
    return retVal;
}

int64_t mathex(std::string exp, std::vector<double>& args)
{
    uint64_t count = args.size();
    std::string lastLetters = getLetters(count);
    std::cout << lastLetters << ":" << getNumber(lastLetters) << std::endl;
    return true;
}


}