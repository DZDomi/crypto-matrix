//
// Created by dominik on 25.01.21.
//

#ifndef DISPLAY_TRACKPIXELCANVAS_H
#define DISPLAY_TRACKPIXELCANVAS_H

#include <graphics.h>
#include "led-matrix.h"
#include "util.h"
#include <unordered_map>

using namespace util;
using namespace std;

struct hash_pair {
    template <class T1, class T2>
    size_t operator()(const pair<T1, T2>& p) const
    {
        auto hash1 = hash<T1>{}(p.first);
        auto hash2 = hash<T2>{}(p.second);
        return hash1 ^ hash2;
    }
};

class TrackPixelCanvas : public rgb_matrix::Canvas {
    public:
        TrackPixelCanvas(rgb_matrix::FrameCanvas *canvas) : delegate_(canvas) {
            for (int x = 0; x < this->delegate_->width(); x++){
                for (int y = 0; y < this->delegate_->height(); y++){
                    this->points[pair(x, y)] = rgb_matrix::Color();
                }
            }
        }
        int width() const { return delegate_->width(); }
        int height() const { return delegate_->height(); }
        void Fill(uint8_t red, uint8_t green, uint8_t blue) { delegate_->Fill(red, green, blue);}
        void Clear() {
            for (int x = 0; x < this->delegate_->width(); x++){
                for (int y = 0; y < this->delegate_->height(); y++){
                    rgb_matrix::Color color = rgb_matrix::Color(0, 0, 0);
                    this->points[pair(x,y)] = color;
                }
            }
            delegate_->Clear();
        }


        void SetPixel(int x, int y, uint8_t red, uint8_t green, uint8_t blue) {
            this->points[pair(x,y)] = rgb_matrix::Color(red, green, blue);
            delegate_->SetPixel(x, y, red, green, blue);
        }

        void RestorePixels() {
            for (int x = 0; x < this->delegate_->width(); x++){
                for (int y = 0; y < this->delegate_->height(); y++){
                    rgb_matrix::Color color = this->points[pair(x, y)];
                    this->delegate_->SetPixel(x, y, color.r, color.g, color.b);
                }
            }
        }

        rgb_matrix::FrameCanvas *GetFrameCanvas() {
            return this->delegate_;
        }

    private:
        rgb_matrix::FrameCanvas *const delegate_;
        unordered_map<pair<int, int>, rgb_matrix::Color, hash_pair> points;

};


#endif //DISPLAY_TRACKPIXELCANVAS_H
