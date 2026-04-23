#import "TouchSimulator.hpp"

@implementation TouchSimulator

// ── Single synthetic touch event ─────────────────────────────

+ (void)sendTouchAt:(CGPoint)point
              phase:(UITouchPhase)phase
               view:(UIView *)view {
    @try {
        UITouch *touch = [[UITouch alloc] init];
        CGPoint  winPt = [view convertPoint:point toView:nil];

        [touch setValue:@(phase)            forKey:@"phase"];
        [touch setValue:view                forKey:@"view"];
        [touch setValue:view.window         forKey:@"window"];
        [touch setValue:[NSValue valueWithCGPoint:winPt]
                 forKey:@"_locationInWindow"];
        [touch setValue:[NSValue valueWithCGPoint:winPt]
                 forKey:@"_previousLocationInWindow"];
        [touch setValue:@([NSProcessInfo processInfo].systemUptime)
                 forKey:@"_timestamp"];

        UIEvent  *event   = [[UIApplication sharedApplication]
                              performSelector:@selector(_touchesEvent)];
        NSSet    *touches = [NSSet setWithObject:touch];

        switch (phase) {
            case UITouchPhaseBegan:
                [view touchesBegan:touches withEvent:event];   break;
            case UITouchPhaseMoved:
                [view touchesMoved:touches withEvent:event];   break;
            case UITouchPhaseEnded:
                [view touchesEnded:touches withEvent:event];   break;
            default: break;
        }
    }
    @catch (NSException *e) {
        NSLog(@"[BlockBot] touch exception: %@", e.reason);
    }
}

// ── Smooth drag with ease-in-out interpolation ───────────────

+ (void)dragFrom:(CGPoint)from
              to:(CGPoint)to
          onView:(UIView *)view
        duration:(double)dur
           steps:(int)steps {

    if (!view || !view.window) {
        NSLog(@"[BlockBot] dragFrom:to: — view/window is nil, skipped");
        return;
    }

    double interval = dur / (double)steps;

    [self sendTouchAt:from phase:UITouchPhaseBegan view:view];
    [NSThread sleepForTimeInterval:0.02];

    for (int i = 1; i <= steps; i++) {
        double t    = (double)i / steps;
        double ease = t * t * (3.0 - 2.0 * t);            // smoothstep
        CGPoint pt  = CGPointMake(
            (CGFloat)(from.x + (to.x - from.x) * ease),
            (CGFloat)(from.y + (to.y - from.y) * ease));
        [self sendTouchAt:pt phase:UITouchPhaseMoved view:view];
        [NSThread sleepForTimeInterval:interval];
    }

    [self sendTouchAt:to phase:UITouchPhaseEnded view:view];
}

@end