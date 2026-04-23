#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#include <vector>
#include <array>
#include <algorithm>
#include <cmath>
#include <cstring>
#include <functional>
#include <queue>
#include <numeric>

// ============================================================
//  Part 1 — C++ Block Puzzle Engine
// ============================================================

namespace Engine {

using Board = std::array<std::array<int8_t, 8>, 8>;

struct Block {
    int id;
    int rows;
    int cols;
    int8_t mat[5][5];
    Block() : id(0), rows(0), cols(0) {
        memset(mat, 0, sizeof(mat));
    }
};

struct Move {
    int blockId;
    int r;
    int c;
    int cleared;
};

struct PlaceResult {
    Board board;
    int cleared;
    bool ok;
    std::vector<int> cRows;
    std::vector<int> cCols;
};

struct Solution {
    double score;
    std::vector<Move> path;
};

static PlaceResult place(const Board &bd, const Block &bk, int pr, int pc) {
    PlaceResult res;
    res.ok = false;
    res.cleared = 0;

    if (pr < 0 || pc < 0 || pr + bk.rows > 8 || pc + bk.cols > 8) {
        return res;
    }

    for (int r = 0; r < bk.rows; r++) {
        for (int c = 0; c < bk.cols; c++) {
            if (bk.mat[r][c] && bd[pr + r][pc + c]) {
                return res;
            }
        }
    }

    res.board = bd;
    for (int r = 0; r < bk.rows; r++) {
        for (int c = 0; c < bk.cols; c++) {
            if (bk.mat[r][c]) {
                res.board[pr + r][pc + c] = 1;
            }
        }
    }

    for (int r = 0; r < 8; r++) {
        bool full = true;
        for (int c = 0; c < 8; c++) {
            if (!res.board[r][c]) {
                full = false;
                break;
            }
        }
        if (full) {
            res.cRows.push_back(r);
        }
    }

    for (int c = 0; c < 8; c++) {
        bool full = true;
        for (int r = 0; r < 8; r++) {
            if (!res.board[r][c]) {
                full = false;
                break;
            }
        }
        if (full) {
            res.cCols.push_back(c);
        }
    }

    for (int cr : res.cRows) {
        for (int c = 0; c < 8; c++) {
            res.board[cr][c] = 0;
        }
    }
    for (int cc : res.cCols) {
        for (int r = 0; r < 8; r++) {
            res.board[r][cc] = 0;
        }
    }

    res.cleared = (int)res.cRows.size() + (int)res.cCols.size();
    res.ok = true;
    return res;
}

static int emptyRegions(const Board &bd) {
    bool vis[8][8] = {};
    int regions = 0;
    int dx[] = {0, 0, 1, -1};
    int dy[] = {1, -1, 0, 0};

    for (int r = 0; r < 8; r++) {
        for (int c = 0; c < 8; c++) {
            if (!bd[r][c] && !vis[r][c]) {
                regions++;
                std::queue<std::pair<int, int>> q;
                q.push({r, c});
                vis[r][c] = true;
                while (!q.empty()) {
                    std::pair<int, int> front = q.front();
                    q.pop();
                    int cr2 = front.first;
                    int cc2 = front.second;
                    for (int d = 0; d < 4; d++) {
                        int nr = cr2 + dx[d];
                        int nc = cc2 + dy[d];
                        if (nr >= 0 && nr < 8 && nc >= 0 && nc < 8 &&
                            !bd[nr][nc] && !vis[nr][nc]) {
                            vis[nr][nc] = true;
                            q.push({nr, nc});
                        }
                    }
                }
            }
        }
    }
    return regions;
}

static double evaluate(const Board &bd, int totalLines,
                       const std::vector<int> &clearsPerStep) {
    double score = 0;

    if (totalLines > 0) {
        score += 10000.0 * pow((double)totalLines, 1.5);
    }

    int combo = 0;
    for (int lc : clearsPerStep) {
        if (lc > 0) {
            combo++;
            score += 3000.0 * combo;
        } else {
            combo = 0;
        }
    }

    int holes = 0;
    double wh = 0;
    int heights[8] = {};

    for (int c = 0; c < 8; c++) {
        int top = -1;
        for (int r = 0; r < 8; r++) {
            if (bd[r][c]) {
                top = r;
                break;
            }
        }
        if (top >= 0) {
            heights[c] = 8 - top;
            for (int r = top; r < 8; r++) {
                if (!bd[r][c]) {
                    holes++;
                }
            }
            wh += heights[c] * heights[c];
        }
    }

    score -= holes * 800.0;
    score -= wh * 15.0;

    int bump = 0;
    for (int i = 0; i < 7; i++) {
        bump += abs(heights[i] - heights[i + 1]);
    }
    score -= bump * 60.0;

    for (int r = 0; r < 8; r++) {
        int f = 0;
        for (int c = 0; c < 8; c++) {
            f += bd[r][c];
        }
        if (f == 7) score += 2000;
        else if (f == 6) score += 800;
        else if (f == 5) score += 200;
    }
    for (int c = 0; c < 8; c++) {
        int f = 0;
        for (int r = 0; r < 8; r++) {
            f += bd[r][c];
        }
        if (f == 7) score += 2000;
        else if (f == 6) score += 800;
        else if (f == 5) score += 200;
    }

    double rowSum = 0;
    int cnt = 0;
    for (int r = 0; r < 8; r++) {
        for (int c = 0; c < 8; c++) {
            if (bd[r][c]) {
                rowSum += r;
                cnt++;
            }
        }
    }
    if (cnt > 0) {
        score += (rowSum / cnt) * 30.0;
    }

    int reg = emptyRegions(bd);
    if (reg > 1) {
        score -= (reg - 1) * 300.0;
    }

    return score;
}

struct Candidate {
    int lc;
    int r;
    int c;
    Board nb;
};

static void dfs(const Board &bd, std::vector<Block> &rem,
                std::vector<Move> &path, std::vector<int> &clears,
                double alpha, Solution &best) {

    if (rem.empty()) {
        int total = 0;
        for (int x : clears) {
            total += x;
        }
        double s = evaluate(bd, total, clears);
        if (s > best.score) {
            best.score = s;
            best.path = path;
        }
        return;
    }

    int n = (int)rem.size();
    for (int i = 0; i < n; i++) {
        Block bk = rem[i];

        std::vector<Block> rest;
        for (int j = 0; j < n; j++) {
            if (j != i) {
                rest.push_back(rem[j]);
            }
        }

        std::vector<Candidate> cands;
        for (int r = 0; r <= 8 - bk.rows; r++) {
            for (int c = 0; c <= 8 - bk.cols; c++) {
                PlaceResult res = place(bd, bk, r, c);
                if (res.ok) {
                    Candidate cd;
                    cd.lc = res.cleared;
                    cd.r = r;
                    cd.c = c;
                    cd.nb = res.board;
                    cands.push_back(cd);
                }
            }
        }

        if (cands.empty()) {
            continue;
        }

        std::sort(cands.begin(), cands.end(),
            [](const Candidate &a, const Candidate &b) {
                if (a.lc != b.lc) return a.lc > b.lc;
                return a.r > b.r;
            });

        for (size_t ci = 0; ci < cands.size(); ci++) {
            Candidate &cd = cands[ci];

            if (!best.path.empty()) {
                int curTotal = 0;
                for (int x : clears) {
                    curTotal += x;
                }
                curTotal += cd.lc;
                int remaining = (int)rest.size();
                double optimistic = 10000.0 * pow(curTotal + remaining * 2.0, 1.5)
                                  + 3000.0 * pow((double)(clears.size() + 1 + remaining), 2.0);
                if (optimistic < best.score * 0.3) {
                    continue;
                }
            }

            Move mv;
            mv.blockId = bk.id;
            mv.r = cd.r;
            mv.c = cd.c;
            mv.cleared = cd.lc;

            path.push_back(mv);
            clears.push_back(cd.lc);

            dfs(cd.nb, rest, path, clears,
                std::max(alpha, best.score), best);

            path.pop_back();
            clears.pop_back();
        }
    }
}

static Solution solve(const Board &bd, std::vector<Block> &blocks) {
    Solution best;
    best.score = -1e18;
    std::vector<Move> path;
    std::vector<int> clears;
    dfs(bd, blocks, path, clears, -1e18, best);
    return best;
}

} // namespace Engine


// ============================================================
//  Part 2 — Screen Layout (iPhone 14 Pro)
// ============================================================

namespace Screen {

struct Layout {
    double boardLeft;
    double boardTop;
    double boardRight;
    double boardBottom;
    double slotLeft;
    double slotTop;
    double slotRight;
    double slotBottom;
    double colorThreshold;
    double dragDuration;
    int    dragSteps;
    double stepDelay;
};

static Layout iPhone14Pro() {
    Layout L;
    L.boardLeft   = 0.040;
    L.boardTop    = 0.190;
    L.boardRight  = 0.960;
    L.boardBottom = 0.640;
    L.slotLeft    = 0.040;
    L.slotTop     = 0.710;
    L.slotRight   = 0.960;
    L.slotBottom  = 0.900;
    L.colorThreshold = 0.15;
    L.dragDuration = 0.35;
    L.dragSteps    = 25;
    L.stepDelay    = 0.014;
    return L;
}

struct CellInfo {
    double cellW;
    double cellH;
    double originX;
    double originY;
};

static CellInfo computeCells(const Layout &L, double screenW, double screenH) {
    CellInfo ci;
    ci.originX = screenW * L.boardLeft;
    ci.originY = screenH * L.boardTop;
    double bw = screenW * (L.boardRight - L.boardLeft);
    double bh = screenH * (L.boardBottom - L.boardTop);
    ci.cellW = bw / 8.0;
    ci.cellH = bh / 8.0;
    return ci;
}

static CGPoint boardCellCenter(const CellInfo &ci, int row, int col) {
    CGFloat cx = ci.originX + (col + 0.5) * ci.cellW;
    CGFloat cy = ci.originY + (row + 0.5) * ci.cellH;
    return CGPointMake(cx, cy);
}

static CGPoint slotCenter(const Layout &L, double screenW, double screenH, int slotId) {
    double slotAreaW = screenW * (L.slotRight - L.slotLeft);
    double perSlot = slotAreaW / 3.0;
    double cx = screenW * L.slotLeft + (slotId - 0.5) * perSlot;
    double cy = screenH * (L.slotTop + L.slotBottom) / 2.0;
    return CGPointMake((CGFloat)cx, (CGFloat)cy);
}

} // namespace Screen


// ============================================================
//  Part 3 — Screen Reader (vision from screenshot)
// ============================================================

@interface ScreenReader : NSObject
+ (Engine::Board)readBoard:(UIImage *)img layout:(Screen::Layout)L;
+ (std::vector<Engine::Block>)readBlocks:(UIImage *)img layout:(Screen::Layout)L;
@end

@implementation ScreenReader

+ (void)getPixels:(UIImage *)image
           buffer:(uint8_t *)buf
            width:(size_t)w
           height:(size_t)h {
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(
        buf, w, h, 8, w * 4, cs,
        kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextDrawImage(ctx, CGRectMake(0, 0, (CGFloat)w, (CGFloat)h), image.CGImage);
    CGContextRelease(ctx);
    CGColorSpaceRelease(cs);
}

+ (void)getColorAtX:(int)x
                  y:(int)y
             pixels:(const uint8_t *)px
              width:(size_t)w
                  r:(double *)outR
                  g:(double *)outG
                  b:(double *)outB {
    double sr = 0, sg = 0, sb = 0;
    int cnt = 0;
    for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
            int nx = x + dx;
            int ny = y + dy;
            if (nx >= 0 && ny >= 0 && nx < (int)w) {
                size_t idx = ((size_t)ny * w + (size_t)nx) * 4;
                sr += px[idx]     / 255.0;
                sg += px[idx + 1] / 255.0;
                sb += px[idx + 2] / 255.0;
                cnt++;
            }
        }
    }
    *outR = sr / cnt;
    *outG = sg / cnt;
    *outB = sb / cnt;
}

+ (Engine::Board)readBoard:(UIImage *)img layout:(Screen::Layout)L {
    Engine::Board board = {};
    if (!img) return board;

    size_t w = (size_t)img.size.width;
    size_t h = (size_t)img.size.height;
    std::vector<uint8_t> pixels(w * h * 4);
    [self getPixels:img buffer:pixels.data() width:w height:h];

    int bx0 = (int)(w * L.boardLeft);
    int by0 = (int)(h * L.boardTop);
    int bx1 = (int)(w * L.boardRight);
    int by1 = (int)(h * L.boardBottom);
    double cellW = (double)(bx1 - bx0) / 8.0;
    double cellH = (double)(by1 - by0) / 8.0;

    int refX = bx0 + (int)(cellW * 0.5);
    int refY = by0 + (int)(cellH * 0.5);
    double bgR = 0, bgG = 0, bgB = 0;
    [self getColorAtX:refX y:refY pixels:pixels.data() width:w
                    r:&bgR g:&bgG b:&bgB];

    for (int r = 0; r < 8; r++) {
        for (int c = 0; c < 8; c++) {
            int cx = bx0 + (int)((c + 0.5) * cellW);
            int cy = by0 + (int)((r + 0.5) * cellH);
            double pr = 0, pg = 0, pb = 0;
            [self getColorAtX:cx y:cy pixels:pixels.data() width:w
                            r:&pr g:&pg b:&pb];
            double dist = sqrt(pow(pr - bgR, 2) + pow(pg - bgG, 2) + pow(pb - bgB, 2));
            if (dist > L.colorThreshold) {
                board[r][c] = 1;
            }
        }
    }
    return board;
}

+ (std::vector<Engine::Block>)readBlocks:(UIImage *)img layout:(Screen::Layout)L {
    std::vector<Engine::Block> blocks;
    if (!img) return blocks;

    size_t w = (size_t)img.size.width;
    size_t h = (size_t)img.size.height;
    std::vector<uint8_t> pixels(w * h * 4);
    [self getPixels:img buffer:pixels.data() width:w height:h];

    int sx0 = (int)(w * L.slotLeft);
    int sy0 = (int)(h * L.slotTop);
    int sx1 = (int)(w * L.slotRight);
    int sy1 = (int)(h * L.slotBottom);
    int slotW = (sx1 - sx0) / 3;

    double bgR = 0, bgG = 0, bgB = 0;
    [self getColorAtX:sx0 + 5 y:sy0 + 5 pixels:pixels.data() width:w
                    r:&bgR g:&bgG b:&bgB];

    for (int i = 0; i < 3; i++) {
        int ax0 = sx0 + i * slotW;
        int ax1 = ax0 + slotW;
        int margin = 8;

        int minX = INT_MAX, minY = INT_MAX;
        int maxX = 0, maxY = 0;
        bool found = false;

        for (int y = sy0 + margin; y < sy1 - margin; y++) {
            for (int x = ax0 + margin; x < ax1 - margin; x++) {
                size_t idx = ((size_t)y * w + (size_t)x) * 4;
                double pr2 = pixels[idx]     / 255.0;
                double pg2 = pixels[idx + 1] / 255.0;
                double pb2 = pixels[idx + 2] / 255.0;
                double dist = sqrt(pow(pr2 - bgR, 2) + pow(pg2 - bgG, 2) + pow(pb2 - bgB, 2));
                if (dist > L.colorThreshold) {
                    if (x < minX) minX = x;
                    if (y < minY) minY = y;
                    if (x > maxX) maxX = x;
                    if (y > maxY) maxY = y;
                    found = true;
                }
            }
        }

        if (!found || (maxX - minX) < 12 || (maxY - minY) < 12) {
            continue;
        }

        double cellPx = (double)(sy1 - sy0) / 5.0;
        int bRows = std::max(1, std::min(5, (int)round((maxY - minY) / cellPx)));
        int bCols = std::max(1, std::min(5, (int)round((maxX - minX) / cellPx)));

        Engine::Block bk;
        bk.id = i + 1;
        bk.rows = bRows;
        bk.cols = bCols;

        for (int r = 0; r < bRows; r++) {
            for (int c = 0; c < bCols; c++) {
                int sampX = minX + (int)(c * cellPx + cellPx / 2);
                int sampY = minY + (int)(r * cellPx + cellPx / 2);
                if (sampX >= (int)w) sampX = (int)w - 1;
                if (sampY >= (int)h) sampY = (int)h - 1;
                double pr3 = 0, pg3 = 0, pb3 = 0;
                [self getColorAtX:sampX y:sampY pixels:pixels.data() width:w
                                r:&pr3 g:&pg3 b:&pb3];
                double dist = sqrt(pow(pr3 - bgR, 2) + pow(pg3 - bgG, 2) + pow(pb3 - bgB, 2));
                if (dist > L.colorThreshold) {
                    bk.mat[r][c] = 1;
                }
            }
        }
        blocks.push_back(bk);
    }
    return blocks;
}

@end


// ============================================================
//  Part 4 — Touch Simulator
// ============================================================

@interface TouchSimulator : NSObject
+ (void)dragFrom:(CGPoint)from
              to:(CGPoint)to
          onView:(UIView *)view
        duration:(double)dur
           steps:(int)steps;
@end

@implementation TouchSimulator

+ (void)dragFrom:(CGPoint)from
              to:(CGPoint)to
          onView:(UIView *)view
        duration:(double)dur
           steps:(int)steps {

    if (!view || !view.window) {
        NSLog(@"[BlockBot] view or window is nil, skip touch");
        return;
    }

    double interval = dur / steps;

    [self sendTouch:from phase:UITouchPhaseBegan view:view];
    [NSThread sleepForTimeInterval:0.02];

    for (int i = 1; i <= steps; i++) {
        double t = (double)i / steps;
        double ease = t * t * (3.0 - 2.0 * t);
        CGPoint pt = CGPointMake(
            from.x + (to.x - from.x) * ease,
            from.y + (to.y - from.y) * ease
        );
        [self sendTouch:pt phase:UITouchPhaseMoved view:view];
        [NSThread sleepForTimeInterval:interval];
    }

    [self sendTouch:to phase:UITouchPhaseEnded view:view];
}

+ (void)sendTouch:(CGPoint)point
            phase:(UITouchPhase)phase
             view:(UIView *)view {
    @try {
        UITouch *touch = [[UITouch alloc] init];

        [touch setValue:@(phase) forKey:@"phase"];
        [touch setValue:view forKey:@"view"];
        [touch setValue:view.window forKey:@"window"];

        CGPoint windowPt = [view convertPoint:point toView:nil];
        [touch setValue:[NSValue valueWithCGPoint:windowPt]
                 forKey:@"_locationInWindow"];
        [touch setValue:[NSValue valueWithCGPoint:windowPt]
                 forKey:@"_previousLocationInWindow"];
        [touch setValue:@([NSProcessInfo processInfo].systemUptime)
                 forKey:@"_timestamp"];

        UIEvent *event = [[UIApplication sharedApplication]
                          performSelector:@selector(_touchesEvent)];
        NSSet *touches = [NSSet setWithObject:touch];

        switch (phase) {
            case UITouchPhaseBegan:
                [view touchesBegan:touches withEvent:event];
                break;
            case UITouchPhaseMoved:
                [view touchesMoved:touches withEvent:event];
                break;
            case UITouchPhaseEnded:
                [view touchesEnded:touches withEvent:event];
                break;
            default:
                break;
        }
    }
    @catch (NSException *e) {
        NSLog(@"[BlockBot] touch exception: %@", e.reason);
    }
}

@end


// ============================================================
//  Part 5 — Main Controller
// ============================================================

@interface DeHeBlockBotController : NSObject
@property (nonatomic, assign) BOOL running;
@property (nonatomic, weak)   UIView *targetView;
@property (nonatomic, assign) Screen::Layout layout;
@property (nonatomic, assign) CGFloat screenW;
@property (nonatomic, assign) CGFloat screenH;
- (void)startWithView:(UIView *)view;
- (void)stop;
@end

@implementation DeHeBlockBotController

- (void)startWithView:(UIView *)view {
    self.targetView = view;
    self.running = YES;
    self.layout = Screen::iPhone14Pro();
    self.screenW = view.bounds.size.width;
    self.screenH = view.bounds.size.height;

    NSLog(@"[BlockBot] ===================================");
    NSLog(@"[BlockBot] Started — iPhone 14 Pro mode");
    NSLog(@"[BlockBot] Screen: %.0f x %.0f pts", self.screenW, self.screenH);
    NSLog(@"[BlockBot] ===================================");

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [self mainLoop];
    });
}

- (void)stop {
    self.running = NO;
    NSLog(@"[BlockBot] Stopped");
}

- (void)mainLoop {
    int cycle = 0;

    while (self.running) {
        @autoreleasepool {
            cycle++;
            NSLog(@"[BlockBot] --- Cycle %d ---", cycle);

            __block UIImage *screenshot = nil;
            dispatch_sync(dispatch_get_main_queue(), ^{
                UIView *v = self.targetView;
                if (!v) return;
                UIGraphicsBeginImageContextWithOptions(v.bounds.size, YES, 1.0);
                [v drawViewHierarchyInRect:v.bounds afterScreenUpdates:NO];
                screenshot = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
            });

            if (!screenshot) {
                NSLog(@"[BlockBot] Screenshot failed");
                [NSThread sleepForTimeInterval:2.0];
                continue;
            }

            Engine::Board board = [ScreenReader readBoard:screenshot layout:self.layout];

            int filled = 0;
            for (int r = 0; r < 8; r++) {
                for (int c = 0; c < 8; c++) {
                    filled += board[r][c];
                }
            }
            NSLog(@"[BlockBot] Board: %d/64 filled", filled);

            std::vector<Engine::Block> blocks =
                [ScreenReader readBlocks:screenshot layout:self.layout];
            NSLog(@"[BlockBot] Detected %d blocks", (int)blocks.size());

            if (blocks.empty()) {
                NSLog(@"[BlockBot] Waiting for blocks...");
                [NSThread sleepForTimeInterval:1.5];
                continue;
            }

            for (size_t bi = 0; bi < blocks.size(); bi++) {
                Engine::Block &bk = blocks[bi];
                NSMutableString *shape = [NSMutableString string];
                for (int r = 0; r < bk.rows; r++) {
                    for (int c = 0; c < bk.cols; c++) {
                        [shape appendString:(bk.mat[r][c] ? @"#" : @".")];
                    }
                    if (r < bk.rows - 1) {
                        [shape appendString:@"|"];
                    }
                }
                NSLog(@"[BlockBot]   #%d (%dx%d): %@",
                      bk.id, bk.rows, bk.cols, shape);
            }

            NSLog(@"[BlockBot] Searching...");
            NSDate *t0 = [NSDate date];
            Engine::Solution result = Engine::solve(board, blocks);
            double elapsed = -[t0 timeIntervalSinceNow];

            NSLog(@"[BlockBot] Done %.2fs | score: %.0f | steps: %d",
                  elapsed, result.score, (int)result.path.size());

            if (result.path.empty()) {
                NSLog(@"[BlockBot] No valid solution");
                [NSThread sleepForTimeInterval:2.0];
                continue;
            }

            Screen::CellInfo ci = Screen::computeCells(
                self.layout, self.screenW, self.screenH);

            for (size_t step = 0; step < result.path.size(); step++) {
                if (!self.running) break;

                const Engine::Move &mv = result.path[step];

                NSLog(@"[BlockBot] Step %d/%d: block #%d -> [%d,%d] cleared=%d",
                      (int)step + 1, (int)result.path.size(),
                      mv.blockId, mv.r, mv.c, mv.cleared);

                int bRows2 = 1, bCols2 = 1;
                for (size_t bi = 0; bi < blocks.size(); bi++) {
                    if (blocks[bi].id == mv.blockId) {
                        bRows2 = blocks[bi].rows;
                        bCols2 = blocks[bi].cols;
                        break;
                    }
                }

                CGPoint from = Screen::slotCenter(
                    self.layout, self.screenW, self.screenH, mv.blockId);

                CGPoint to = Screen::boardCellCenter(ci, mv.r, mv.c);
                to.x += (bCols2 - 1) * ci.cellW * 0.5;
                to.y += (bRows2 - 1) * ci.cellH * 0.5;

                NSLog(@"[BlockBot] Drag (%.0f,%.0f) -> (%.0f,%.0f)",
                      from.x, from.y, to.x, to.y);

                dispatch_sync(dispatch_get_main_queue(), ^{
                    [TouchSimulator dragFrom:from
                                          to:to
                                      onView:self.targetView
                                    duration:self.layout.dragDuration
                                       steps:self.layout.dragSteps];
                });

                [NSThread sleepForTimeInterval:0.8];
            }

            NSLog(@"[BlockBot] Waiting for next round...");
            [NSThread sleepForTimeInterval:1.5];
        }
    }
}

@end


// ============================================================
//  Part 6 — Logos Hook
// ============================================================

static DeHeBlockBotController *gBot = nil;
static BOOL gBotStarted = NO;

%hook UIViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;

    if (gBotStarted) return;

    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)),
        dispatch_get_main_queue(), ^{

        if (gBotStarted) return;
        gBotStarted = YES;

        NSLog(@"[BlockBot] VC: %@", NSStringFromClass([self class]));
        NSLog(@"[BlockBot] View: %.0f x %.0f",
              self.view.bounds.size.width,
              self.view.bounds.size.height);

        CGFloat w = self.view.bounds.size.width;
        CGFloat h = self.view.bounds.size.height;
        if (w < 300 || h < 600) {
            NSLog(@"[BlockBot] Screen too small, skipping");
            gBotStarted = NO;
            return;
        }

        gBot = [[DeHeBlockBotController alloc] init];
        [gBot startWithView:self.view];
    });
}

%end

%ctor {
    NSLog(@"[BlockBot] ===================================");
    NSLog(@"[BlockBot] dylib loaded");
    NSLog(@"[BlockBot] Target: iPhone 14 Pro (393x852)");
    NSLog(@"[BlockBot] ===================================");

    [[NSNotificationCenter defaultCenter]
        addObserverForName:@"com.dehe.blockbot.stop"
                    object:nil
                     queue:[NSOperationQueue mainQueue]
                usingBlock:^(NSNotification *note) {
        if (gBot) {
            [gBot stop];
            gBot = nil;
            gBotStarted = NO;
        }
    }];

    [[NSNotificationCenter defaultCenter]
        addObserverForName:@"com.dehe.blockbot.restart"
                    object:nil
                     queue:[NSOperationQueue mainQueue]
                usingBlock:^(NSNotification *note) {
        if (gBot) {
            [gBot stop];
            gBot = nil;
        }
        gBotStarted = NO;
    }];
}