//
// Created by Dominik De Zordo on 20.12.20.
//

#ifndef DISPLAY_UTIL_H
#define DISPLAY_UTIL_H

#include <iostream>
#include <chrono>
#include <sstream>
#include <string>
#include <string_view>

using namespace std;

namespace util {
    void log(const string& type, const string& text);
    string formatPrice(const string price, const int maxLength);
    void toUpperCase(string& str);
    bool endsWith(std::string_view str, std::string_view suffix);
}

#endif //DISPLAY_UTIL_H
