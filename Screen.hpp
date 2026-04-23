#pragma once
#import <CoreGraphics/CoreGraphics.h>

namespace Screen {

struct Layout {
    double boardLeft, boardTop, boardRight, boardBottom;
    double slotLeft,  slotTop,  slotRight,  slotBottom;
    double colorThreshold;
    double dragDuration;
    int    dragSteps;
};

struct CellInfo {
    double cellW, cellH;
    double originX, originY;
};

static inline Layout iPhone14Pro() {
    return {
        .boardLeft        = 0.040,
        .boardTop         = 0.190,
        .boardRight       = 0.960,
        .boardBottom      = 0.640,
        .slotLeft         = 0.040,
        .slotTop          = 0.710,
        .slotRight        = 0.960,
        .slotBottom       = 0.900,
        .colorThreshold   = 0.15,
        .dragDuration     = 0.35,
        .dragSteps        = 25,
    };
}

static inline CellInfo computeCells(const Layout &L,
                                    double screenW, double screenH) {
    CellInfo ci;
    ci.originX = screenW * L.boardLeft;
    ci.originY = screenH * L.boardTop;
    double bw  = screenW * (L.boardRight  - L.boardLeft);
    double bh  = screenH * (L.boardBottom - L.boardTop);
    ci.cellW   = bw / 8.0;
    ci.cellH   = bh / 8.0;
    return ci;
}

static inline CGPoint boardCellCenter(const CellInfo &ci, int row, int col) {
    return CGPointMake(
        (CGFloat)(ci.originX + (col + 0.5) * ci.cellW),
        (CGFloat)(ci.originY + (row + 0.5) * ci.cellH)
    );
}

static inline CGPoint slotCenter(const Layout &L,
                                  double screenW, double screenH, int slotId) {
    double perSlot = screenW * (L.slotRight - L.slotLeft) / 3.0;
    double cx = screenW * L.slotLeft + (slotId - 0.5) * perSlot;
    double cy = screenH * (L.slotTop + L.slotBottom) / 2.0;
    return CGPointMake((CGFloat)cx, (CGFloat)cy);
}

} // namespace Screen