#pragma once
#import <UIKit/UIKit.h>
#import "Engine.hpp"
#import "Screen.hpp"

@interface ScreenReader : NSObject
+ (Engine::Board)readBoard:(UIImage *)img layout:(Screen::Layout)L;
+ (std::vector<Engine::Block>)readBlocks:(UIImage *)img layout:(Screen::Layout)L;
@end