//
//  UIImage+Cropping.m
//  SlidePuzzle
//
//  Created by Yoshizawa Tomoya on 2014/10/10.
//  Copyright (c) 2014年 Tomoya Yoshizawa. All rights reserved.
//

#import "UIImage+Cropping.h"

@implementation UIImage (Cropping)

- (UIImage *)croppedImageInRect:(CGRect)rect
{
    CGImageRef imageRef = CGImageCreateWithImageInRect(self.CGImage, rect);
    UIImage *croppedImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    return croppedImage;
}
@end
