#import <UIKit/UIKit.h>
#import "BotController.hpp"

static DeHeBlockBotController *gBot     = nil;
static BOOL                    gStarted = NO;

%hook UIViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    if (gStarted) return;

    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)),
        dispatch_get_main_queue(), ^{

        if (gStarted) return;

        CGFloat w = self.view.bounds.size.width;
        CGFloat h = self.view.bounds.size.height;

        NSLog(@"[BlockBot] Hook fired — VC: %@  view: %.0f×%.0f",
              NSStringFromClass([self class]), w, h);

        if (w < 300 || h < 600) {
            NSLog(@"[BlockBot] View too small, skipping");
            return;
        }

        gStarted = YES;
        gBot     = [[DeHeBlockBotController alloc] init];
        [gBot startWithView:self.view];
    });
}

%end

%ctor {
    NSLog(@"[BlockBot] ===================================");
    NSLog(@"[BlockBot] dylib loaded");
    NSLog(@"[BlockBot] Target: iPhone 14 Pro (393x852 pts)");
    NSLog(@"[BlockBot] ===================================");

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    NSOperationQueue     *mq = [NSOperationQueue mainQueue];

    [nc addObserverForName:@"com.dehe.blockbot.stop"
                    object:nil queue:mq
               usingBlock:^(NSNotification *n) {
        [gBot stop];
        gBot     = nil;
        gStarted = NO;
        NSLog(@"[BlockBot] Stopped via notification");
    }];

    [nc addObserverForName:@"com.dehe.blockbot.restart"
                    object:nil queue:mq
               usingBlock:^(NSNotification *n) {
        [gBot stop];
        gBot     = nil;
        gStarted = NO;
        NSLog(@"[BlockBot] Restarted via notification");
    }];
}