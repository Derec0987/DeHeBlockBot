#import "BotController.hpp"
#import "Engine.hpp"
#import "ScreenReader.hpp"
#import "TouchSimulator.hpp"
#import "Screen.hpp"

@implementation DeHeBlockBotController

// ── Start ─────────────────────────────────────────────────────

- (void)startWithView:(UIView *)view {
    self.targetView = view;
    self.running    = YES;
    self.layout     = Screen::iPhone14Pro();
    self.screenW    = view.bounds.size.width;
    self.screenH    = view.bounds.size.height;

    NSLog(@"[BlockBot] ===================================");
    NSLog(@"[BlockBot] Started — iPhone 14 Pro mode");
    NSLog(@"[BlockBot] Screen: %.0f × %.0f pts", self.screenW, self.screenH);
    NSLog(@"[BlockBot] ===================================");

    dispatch_async(
        dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [self mainLoop];
    });
}

// ── Stop ──────────────────────────────────────────────────────

- (void)stop {
    self.running = NO;
    NSLog(@"[BlockBot] Stopped");
}

// ── Screenshot helper ─────────────────────────────────────────

- (UIImage *)takeScreenshot {
    __block UIImage *img = nil;
    dispatch_sync(dispatch_get_main_queue(), ^{
        UIView *v = self.targetView;
        if (!v) return;
        UIGraphicsBeginImageContextWithOptions(v.bounds.size, YES, 1.0);
        [v drawViewHierarchyInRect:v.bounds afterScreenUpdates:NO];
        img = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    });
    return img;
}

// ── Main bot loop ─────────────────────────────────────────────

- (void)mainLoop {
    int cycle = 0;

    while (self.running) {
        @autoreleasepool {
            cycle++;
            NSLog(@"[BlockBot] ─── Cycle %d ───", cycle);

            // 1. Screenshot
            UIImage *screenshot = [self takeScreenshot];
            if (!screenshot) {
                NSLog(@"[BlockBot] Screenshot failed, retrying…");
                [NSThread sleepForTimeInterval:2.0];
                continue;
            }

            // 2. Read board
            Engine::Board board =
                [ScreenReader readBoard:screenshot layout:self.layout];

            int filled = 0;
            for (int r = 0; r < 8; r++)
                for (int c = 0; c < 8; c++)
                    filled += board[r][c];
            NSLog(@"[BlockBot] Board: %d/64 filled", filled);

            // 3. Read blocks
            std::vector<Engine::Block> blocks =
                [ScreenReader readBlocks:screenshot layout:self.layout];
            NSLog(@"[BlockBot] Detected %d block(s)", (int)blocks.size());

            if (blocks.empty()) {
                NSLog(@"[BlockBot] No blocks detected, waiting…");
                [NSThread sleepForTimeInterval:1.5];
                continue;
            }

            // Log block shapes
            for (auto &bk : blocks) {
                NSMutableString *shape = [NSMutableString string];
                for (int r = 0; r < bk.rows; r++) {
                    for (int c = 0; c < bk.cols; c++)
                        [shape appendString:(bk.mat[r][c] ? @"#" : @".")];
                    if (r < bk.rows - 1) [shape appendString:@"|"];
                }
                NSLog(@"[BlockBot]   Block #%d (%dx%d): %@",
                      bk.id, bk.rows, bk.cols, shape);
            }

            // 4. Solve
            NSLog(@"[BlockBot] Searching for best solution…");
            NSDate *t0 = [NSDate date];
            Engine::Solution result = Engine::solve(board, blocks);
            double elapsed = -[t0 timeIntervalSinceNow];

            NSLog(@"[BlockBot] Solved in %.2fs | score=%.0f | steps=%d",
                  elapsed, result.score, (int)result.path.size());

            if (result.path.empty()) {
                NSLog(@"[BlockBot] No valid placement found");
                [NSThread sleepForTimeInterval:2.0];
                continue;
            }

            // 5. Execute moves
            Screen::CellInfo ci =
                Screen::computeCells(self.layout, self.screenW, self.screenH);

            int totalSteps = (int)result.path.size();
            for (int step = 0; step < totalSteps && self.running; step++) {
                const Engine::Move &mv = result.path[step];

                // Find block dimensions
                int bRows = 1, bCols = 1;
                for (auto &bk : blocks) {
                    if (bk.id == mv.blockId) {
                        bRows = bk.rows;
                        bCols = bk.cols;
                        break;
                    }
                }

                CGPoint from = Screen::slotCenter(
                    self.layout, self.screenW, self.screenH, mv.blockId);

                // Target = top-left anchor + centre offset of block footprint
                CGPoint to = Screen::boardCellCenter(ci, mv.r, mv.c);
                to.x += (bCols - 1) * ci.cellW * 0.5;
                to.y += (bRows - 1) * ci.cellH * 0.5;

                NSLog(@"[BlockBot] Step %d/%d — block#%d → [%d,%d]  "
                      @"drag (%.0f,%.0f)→(%.0f,%.0f)  cleared=%d",
                      step + 1, totalSteps,
                      mv.blockId, mv.r, mv.c,
                      from.x, from.y, to.x, to.y,
                      mv.cleared);

                dispatch_sync(dispatch_get_main_queue(), ^{
                    [TouchSimulator dragFrom:from
                                          to:to
                                      onView:self.targetView
                                    duration:self.layout.dragDuration
                                       steps:self.layout.dragSteps];
                });

                [NSThread sleepForTimeInterval:0.8];
            }

            NSLog(@"[BlockBot] Round complete — waiting for next…");
            [NSThread sleepForTimeInterval:1.5];
        }
    }
}

@end