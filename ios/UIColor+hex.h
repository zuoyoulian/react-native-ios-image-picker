//
//  UIColor+hex.h
//  RNImagePicker
//
//  Created by 左建军 on 16/6/28.
//  Copyright © 2016年 Marc Shilling. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (hex)

//  将16进制的颜色字符串转成UIColor对象
/* 
   参数：
   color 颜色的16进制字符串
   alpha 颜色透明度
 */
+ (UIColor *)colorWithHexString:(NSString *)color andAlpha:(CGFloat)alpha;

@end
