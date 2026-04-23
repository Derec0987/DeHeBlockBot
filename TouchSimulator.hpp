#pragma once
#import <UIKit/UIKit.h>

@interface TouchSimulator : NSObject
+ (void)dragFrom:(CGPoint)from
              to:(CGPoint)to
          onView:(UIView *)view
        duration:(double)dur
           steps:(int)steps;
@end