//
//  TFImagePickerViewController.h
//  choosePhoto
//
//  Created by 左建军 on 16/6/24.
//  Copyright © 2016年 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>

//  选择完成的消息
#define ImagePickerSelectFinishNotification  @"ImagePickerSelectFinishNotification"
//  选择个数到最大的消息
#define ImagePickerSelectMaxNumNotification  @"ImagePickerSelectMaxNumNotification"

//  尺寸
#define StateBarHeight        20   // 电池状态栏高度
#define NavigationBarHeight   44   // 导航条高度
#define TabBarHeight          49   // 标签栏高度
#define ScreenWidth    [[UIScreen mainScreen] bounds].size.width  // 屏幕宽度
#define ScreenHeight   [[UIScreen mainScreen] bounds].size.height // 屏幕高度


@interface TFImagePickerViewController : UIViewController

@property (nonatomic, assign) NSInteger maxNumOfSelection;  // 照片选择最大个数
@property (nonatomic, assign) NSInteger currentNumOfSelection; // 当前选择的照片个数
@property (nonatomic, strong) NSDictionary *options;  // js传入的参数

@property (nonatomic, strong) UICollectionView *collectionView;  // 展示照片缩略图

// 选择完成后回调
@property (nonatomic, copy) void (^selectFinish)(NSDictionary *);

- (void)finishAction:(UIButton *)button;

@end


@interface TFImagePickerCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) TFImagePickerViewController *imagePickerVC;

//  创建cell上的子视图
/* 
   contentDic 要显示的数据
*/
- (void)creatSubviewsWithDic:(NSDictionary *)contentDic;

@end