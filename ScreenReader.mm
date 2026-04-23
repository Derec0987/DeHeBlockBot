#import "ScreenReader.hpp"
#include <vector>
#include <cmath>
#include <climits>
#include <algorithm>

@implementation ScreenReader

// ── Pixel buffer ─────────────────────────────────────────────

+ (void)renderImage:(UIImage *)image
          intoBuffer:(uint8_t *)buf
               width:(size_t)w
              height:(size_t)h {
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx   = CGBitmapContextCreate(
        buf, w, h, 8, w * 4, cs,
        kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextDrawImage(ctx, CGRectMake(0, 0, (CGFloat)w, (CGFloat)h), image.CGImage);
    CGContextRelease(ctx);
    CGColorSpaceRelease(cs);
}

// ── 3×3 averaged colour sample ───────────────────────────────

+ (void)sampleColorAtX:(int)x
                     y:(int)y
                pixels:(const uint8_t *)px
                 width:(size_t)w
                height:(size_t)h
                     r:(double *)outR
                     g:(double *)outG
                     b:(double *)outB {
    double sr = 0, sg = 0, sb = 0;
    int    cnt = 0;
    for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
            int nx = x + dx, ny = y + dy;
            if (nx < 0 || ny < 0 || nx >= (int)w || ny >= (int)h) continue;
            size_t idx = ((size_t)ny * w + (size_t)nx) * 4;
            sr += px[idx    ] / 255.0;
            sg += px[idx + 1] / 255.0;
            sb += px[idx + 2] / 255.0;
            cnt++;
        }
    }
    *outR = sr / cnt;
    *outG = sg / cnt;
    *outB = sb / cnt;
}

// ── Board reader ─────────────────────────────────────────────

+ (Engine::Board)readBoard:(UIImage *)img layout:(Screen::Layout)L {
    Engine::Board board = {};
    if (!img) return board;

    size_t w = (size_t)img.size.width;
    size_t h = (size_t)img.size.height;
    std::vector<uint8_t> px(w * h * 4);
    [self renderImage:img intoBuffer:px.data() width:w height:h];

    int    bx0   = (int)(w * L.boardLeft);
    int    by0   = (int)(h * L.boardTop);
    int    bx1   = (int)(w * L.boardRight);
    int    by1   = (int)(h * L.boardBottom);
    double cellW = (double)(bx1 - bx0) / 8.0;
    double cellH = (double)(by1 - by0) / 8.0;

    // Sample background from top-left board corner
    double bgR = 0, bgG = 0, bgB = 0;
    [self sampleColorAtX:(int)(bx0 + cellW * 0.5)
                       y:(int)(by0 + cellH * 0.5)
                  pixels:px.data() width:w height:h
                       r:&bgR g:&bgG b:&bgB];

    for (int r = 0; r < 8; r++) {
        for (int c = 0; c < 8; c++) {
            int    cx = bx0 + (int)((c + 0.5) * cellW);
            int    cy = by0 + (int)((r + 0.5) * cellH);
            double pr = 0, pg = 0, pb = 0;
            [self sampleColorAtX:cx y:cy
                          pixels:px.data() width:w height:h
                               r:&pr g:&pg b:&pb];
            double dist = std::sqrt(std::pow(pr - bgR, 2)
                                  + std::pow(pg - bgG, 2)
                                  + std::pow(pb - bgB, 2));
            if (dist > L.colorThreshold)
                board[r][c] = 1;
        }
    }
    return board;
}

// ── Block reader ─────────────────────────────────────────────

+ (std::vector<Engine::Block>)readBlocks:(UIImage *)img layout:(Screen::Layout)L {
    std::vector<Engine::Block> blocks;
    if (!img) return blocks;

    size_t w = (size_t)img.size.width;
    size_t h = (size_t)img.size.height;
    std::vector<uint8_t> px(w * h * 4);
    [self renderImage:img intoBuffer:px.data() width:w height:h];

    int sx0   = (int)(w * L.slotLeft);
    int sy0   = (int)(h * L.slotTop);
    int sx1   = (int)(w * L.slotRight);
    int sy1   = (int)(h * L.slotBottom);
    int slotW = (sx1 - sx0) / 3;

    double bgR = 0, bgG = 0, bgB = 0;
    [self sampleColorAtX:sx0 + 5 y:sy0 + 5
                  pixels:px.data() width:w height:h
                       r:&bgR g:&bgG b:&bgB];

    for (int i = 0; i < 3; i++) {
        int ax0    = sx0 + i * slotW;
        int ax1    = ax0 + slotW;
        int margin = 8;

        int minX = INT_MAX, minY = INT_MAX;
        int maxX = 0,       maxY = 0;
        bool found = false;

        for (int y = sy0 + margin; y < sy1 - margin; y++) {
            for (int x = ax0 + margin; x < ax1 - margin; x++) {
                size_t idx = ((size_t)y * w + (size_t)x) * 4;
                double pr = px[idx    ] / 255.0;
                double pg = px[idx + 1] / 255.0;
                double pb = px[idx + 2] / 255.0;
                double dist = std::sqrt(std::pow(pr - bgR, 2)
                                      + std::pow(pg - bgG, 2)
                                      + std::pow(pb - bgB, 2));
                if (dist > L.colorThreshold) {
                    minX = std::min(minX, x);
                    minY = std::min(minY, y);
                    maxX = std::max(maxX, x);
                    maxY = std::max(maxY, y);
                    found = true;
                }
            }
        }

        if (!found || (maxX - minX) < 12 || (maxY - minY) < 12)
            continue;

        double cellPx = (double)(sy1 - sy0) / 5.0;
        int bRows = std::max(1, std::min(5, (int)std::round((maxY - minY) / cellPx)));
        int bCols = std::max(1, std::min(5, (int)std::round((maxX - minX) / cellPx)));

        Engine::Block bk;
        bk.id   = i + 1;
        bk.rows = bRows;
        bk.cols = bCols;

        for (int r = 0; r < bRows; r++) {
            for (int c = 0; c < bCols; c++) {
                int sx = std::min((int)(minX + c * cellPx + cellPx / 2), (int)w - 1);
                int sy = std::min((int)(minY + r * cellPx + cellPx / 2), (int)h - 1);
                double pr = 0, pg = 0, pb = 0;
                [self sampleColorAtX:sx y:sy
                              pixels:px.data() width:w height:h
                                   r:&pr g:&pg b:&pb];
                double dist = std::sqrt(std::pow(pr - bgR, 2)
                                      + std::pow(pg - bgG, 2)
                                      + std::pow(pb - bgB, 2));
                if (dist > L.colorThreshold)
                    bk.mat[r][c] = 1;
            }
        }
        blocks.push_back(bk);
    }
    return blocks;
}

@end