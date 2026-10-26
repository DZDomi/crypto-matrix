//
// Created by Dominik De Zordo on 20.12.20.
//

#include "ledmatrix.h"

LedMatrix* LedMatrix::instance = nullptr;

LedMatrix* LedMatrix::getInstance(){
    if(instance != nullptr){
        return instance;
    }
    instance = new LedMatrix();
    return instance;
}

LedMatrix::LedMatrix() {

    log("LedMatrix", "Trying to initialize led wall...");

    rgb_matrix::RGBMatrix::Options matrix_options;
    rgb_matrix::RuntimeOptions runtime_opt;

    matrix_options.chain_length = 2;
    matrix_options.parallel = 2;
    matrix_options.show_refresh_rate = false;
    matrix_options.brightness = 100;

    runtime_opt.drop_privileges = 0;
    runtime_opt.gpio_slowdown = 4;

    this->matrix = rgb_matrix::RGBMatrix::CreateFromOptions(matrix_options, runtime_opt);

    this->font = rgb_matrix::Font();
    this->font.LoadFont("fonts/5x8.bdf");

    this->matrix->Clear();

    this->canvas = new TrackPixelCanvas(this->matrix->CreateFrameCanvas());

    log("LedMatrix", "Initialization of led wall completed");

}

LedMatrix::~LedMatrix() {
    this->matrix->Clear();
    delete canvas;
    delete matrix;
}

void LedMatrix::printChart(models::Interval interval) {

    //TODO: Put into consts
    int candleWith = 3;
    auto candles = interval.mutable_candles();

    if (interval.candles_size() > this->canvas->width() / candleWith) {
        int maxCandlesPossible = this->canvas->width() / candleWith;
        if (interval.candles_size() > maxCandlesPossible) {
            interval.mutable_candles()->DeleteSubrange(0, interval.candles_size() - maxCandlesPossible);
            candles = interval.mutable_candles();
        }
    }

    //TODO: Make the amount matching with amount of candles we can show
//    else if (interval.candles_size() < this->canvas->width() / candleWith) {
//        // If the default candle size is too small we have to adjust the candle with
//        while (interval.candles_size() < this->canvas->width() / candleWith) {
//            candleWith++;
//        }
//    }

    double highest = 0;
    double lowest = numeric_limits<double>::max();

    for (const models::Candle& candle : *candles) {
        double high = stod(candle.high());
        double low = stod(candle.low());
        // Find out the highest value
        if (high > highest) {
            highest = high;
        }
        //Find out the lowest value
        if (low < lowest) {
            lowest = low;
        }
    }

    double maxHeight = highest - lowest;
    double valueInPixelHeight = maxHeight / (this->canvas->height() - this->font.height());

    this->writeMutex.lock();
    this->clearFromXToY(0, 0, this->canvas->width(), this->canvas->height() - this->font.height());


    for (int i = 0; i < candles->size(); i++) {
        const models::Candle& candle = candles->Get(i);

        auto high = stod(candle.high());
        auto low = stod(candle.low());
        int yPosHigh = (highest - high) / valueInPixelHeight;
        int yPosLow = (highest - low) / valueInPixelHeight;

        auto open = stod(candle.open());
        auto close = stod(candle.close());
        bool isBullish = close > open;
        int yPosOpen = (highest - open) / valueInPixelHeight;
        int yPosClose = (highest - close) / valueInPixelHeight;

        if (yPosHigh >= yPosLow) {
            for (int xPos = i * candleWith; xPos < i * candleWith + candleWith; xPos++) {
                if (isBullish) {
                    this->canvas->SetPixel(xPos, yPosHigh, 0, 255, 0);
                } else {
                    this->canvas->SetPixel(xPos, yPosHigh, 255, 0, 0);
                }
            }
            continue;
        }

        for (int yPos = yPosHigh; yPos < yPosLow; yPos++) {
            if (isBullish) {
                if (yPos < yPosClose) {
                    this->canvas->SetPixel(i * candleWith + 1, yPos, 0, 255, 0);
                    continue;
                } else if (yPos > yPosOpen) {
                    this->canvas->SetPixel(i * candleWith + 1, yPos, 0, 255, 0);
                    continue;
                }
            } else {
                if (yPos < yPosOpen) {
                    this->canvas->SetPixel(i * candleWith + 1, yPos, 255, 0, 0);
                    continue;
                }
                if (yPos > yPosClose) {
                    this->canvas->SetPixel(i * candleWith + 1, yPos, 255, 0, 0);
                    continue;
                }
            }

            for (int xPos = i * candleWith; xPos < i * candleWith + candleWith; xPos++) {
                if (isBullish) {
                    this->canvas->SetPixel(xPos, yPos, 0, 255, 0);
                } else {
                    this->canvas->SetPixel(xPos, yPos, 255, 0, 0);
                }
            }
        }
    }
    this->matrix->SwapOnVSync(this->canvas->GetFrameCanvas());
    this->writeMutex.unlock();
}

void LedMatrix::printText(const int row, const string& text, const rgb_matrix::Color color) {

    if (row > MAX_LINES) {
        log("LedMatrix", "Got row: " + to_string(row) + ", not printing.");
        return;
    }

    int yPos = this->font.height() * row - this->font.height();

    this->writeMutex.lock();

    this->clearFromXToY(0, yPos, this->canvas->width(), this->font.height() + yPos);

    rgb_matrix::DrawText(this->canvas, this->font, 0, yPos + this->font.baseline(), color, nullptr, text.c_str());
    this->matrix->SwapOnVSync(this->canvas->GetFrameCanvas());
    this->writeMutex.unlock();
}

void LedMatrix::setBrightness(int percent) {
    this->writeMutex.lock();
    this->matrix->SetBrightness(percent);
    this->canvas->RestorePixels();
    this->matrix->SwapOnVSync(this->canvas->GetFrameCanvas());
    this->writeMutex.unlock();
}

void LedMatrix::clearFromXToY(int xPosStart, int yPostStart, int xPosEnd, int yPosEnd) {
    for (int x = xPosStart; x < xPosEnd; x++){
        for (int y = yPostStart; y < yPosEnd; y++){
            this->canvas->SetPixel(x, y, 0, 0, 0);
        }
    }
}

void LedMatrix::emptyRow(int row) {
    if (row > LedMatrix::MAX_LINES) {
        log("LedMatrix", "Got row: " + to_string(row) + ", not emptying.");
        return;
    }
    int yPos = this->font.height() * row - this->font.height();
    this->writeMutex.lock();
    this->clearFromXToY(0, yPos, this->canvas->width(), this->font.height() + yPos);
    this->matrix->SwapOnVSync(this->canvas->GetFrameCanvas());
    this->writeMutex.unlock();
}

void LedMatrix::clear() {
    this->writeMutex.lock();
    this->canvas->Clear();
    this->matrix->SwapOnVSync(this->canvas->GetFrameCanvas());
    this->writeMutex.unlock();
}

int LedMatrix::getMaxCharacters(){
    return ceil(this->canvas->width() / (double)this->font.CharacterWidth('W'));
}