//
//  TFBigImageViewController.h
//  choosePhoto
//
//  Created by 左建军 on 16/6/24.
//  Copyright © 2016年 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TFImagePickerViewController;

@interface TFBigImageViewController : UIViewController

@property (nonatomic, assign) NSInteger currentPageIndex; // 当前页数
@property (nonatomic, strong) NSArray *allPhotos; // 所有图片数据
// 回调图片选择
@property (nonatomic, copy) void (^selectImg)(NSInteger);
@property (nonatomic, strong) TFImagePickerViewController *imagePickerVC;

@end
