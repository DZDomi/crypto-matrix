//
// Created by Dominik De Zordo on 20.12.20.
//

#include <cmath>
#include <algorithm>
#include "util.h"

namespace util {
    void log(const string& type, const string& text) {
        auto timeNow = chrono::system_clock::to_time_t(chrono::system_clock::now());
        cout << "[" << timeNow << "] " << type << ": " << text << endl;
    }

    string formatPrice(const string price, const int maxLength) {
        double convertedPrice = stod(price);

        stringstream stream;
        stream.setf(ios::fixed);

        int targetPrecision;
        // If price is lower then 100, we want to show everything possible
        // -2 of the 0 and the comma, for prices above we are showing max 2
        if (convertedPrice < pow(10, 2)) {
            targetPrecision = maxLength - 2;
        } else {
            targetPrecision = 2;
        }
        stream.precision(targetPrecision);
        stream << convertedPrice;
        string result = stream.str();

        while(result.length() > maxLength || endsWith(result, ".")) {
            result.pop_back();
        }

        return result;
    }

    void toUpperCase(string& str) {
        transform(str.begin(), str.end(), str.begin(), ::toupper);
    }

    bool endsWith(std::string_view str, std::string_view suffix) {
        return str.size() >= suffix.size() && 0 == str.compare(str.size()-suffix.size(), suffix.size(), suffix);
    }
}