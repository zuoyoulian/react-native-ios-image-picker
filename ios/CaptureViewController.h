//
//  CaptureViewController.h
//  图片裁剪demo
//
//  Created by 左建军 on 16/9/29.
//  Copyright © 2016年 tuofeng. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface CaptureViewController : UIViewController

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSDictionary *cropOptions;

@end
