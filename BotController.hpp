#pragma once
#import <UIKit/UIKit.h>
#import "Screen.hpp"

@interface DeHeBlockBotController : NSObject
@property (nonatomic, assign) BOOL          running;
@property (nonatomic, weak)   UIView       *targetView;
@property (nonatomic, assign) Screen::Layout layout;
@property (nonatomic, assign) CGFloat        screenW;
@property (nonatomic, assign) CGFloat        screenH;
- (void)startWithView:(UIView *)view;
- (void)stop;
@end