//
// Created by Dominik De Zordo on 20.12.20.
//

#ifndef DISPLAY_LEDMATRIX_H
#define DISPLAY_LEDMATRIX_H

#include <thread>
#include <string>
#include <cmath>
#include <mutex>
#include <csignal>
#include <condition_variable>
#include <graphics.h>

#include "util.h"
#include "led-matrix.h"
#include "interval.pb.h"
#include "trackpixelcanvas.h"

using namespace std;
using namespace util;

class LedMatrix {
    public:

        static const int MAX_LINES = 8;
        static const int CANDLE_WIDTH = 3;

        static LedMatrix* getInstance();
        LedMatrix(LedMatrix const&) = delete;
        void operator=(LedMatrix const&) = delete;
        ~LedMatrix();

        void printText(int row, const string& text, rgb_matrix::Color color);
        void printChart(models::Interval interval);
        void setBrightness(int percent);
        void emptyRow(int row);
        void clear();
        int getMaxCharacters();

    private:

        void clearFromXToY(int xPosStart, int yPostStart, int xPosEnd, int yPosEnd);

        rgb_matrix::RGBMatrix *matrix;
        TrackPixelCanvas *canvas;
        rgb_matrix::Font font;

        mutex writeMutex;

        static LedMatrix* instance;
        LedMatrix();
};


#endif //DISPLAY_LEDMATRIX_H
