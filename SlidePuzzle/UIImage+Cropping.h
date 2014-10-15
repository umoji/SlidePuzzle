//
//  UIImage+Cropping.h
//  SlidePuzzle
//
//  Created by Yoshizawa Tomoya on 2014/10/10.
//  Copyright (c) 2014年 Tomoya Yoshizawa. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Cropping)
- (UIImage *)croppedImageInRect:(CGRect)rect;
@end
