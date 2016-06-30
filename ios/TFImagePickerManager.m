//
//  TFImagePickerManager.m
//  RNImagePicker
//
//  Created by 左建军 on 16/6/30.
//  Copyright © 2016年 Marc Shilling. All rights reserved.
//

#import "TFImagePickerManager.h"
#import "TFImagePickerViewController.h"


@interface TFImagePickerManager ()


@property (nonatomic, copy) RCTResponseSenderBlock callback;

@end

@implementation TFImagePickerManager


//  默认暴露给js模块使用类名
RCT_EXPORT_MODULE();


//  重写初始化方法
-(instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

//  提供对外的接口，在js中调用
/*
 options: 传入的js中设置的参数
 callback: 当选完照片后往js模块中回调
 */
RCT_EXPORT_METHOD(showImagePicker:(NSDictionary *)options callback:(RCTResponseSenderBlock)callback) {
    self.callback = callback;  // 保存block对象 防止被释放掉
    
    //    NSLog(@"options = %@", options);
    
    // 获取根视图控制器
    UIViewController *controller = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    
    // 创建图片选取器对象
    TFImagePickerViewController *imgPickVC = [[TFImagePickerViewController alloc] init];
    // 赋值最大选取个数
    imgPickVC.maxNumOfSelection = [options[@"maxNumOfSelect"] integerValue];
    imgPickVC.options = options;
    
    // 模态推出选取器
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:imgPickVC];
    [controller presentViewController:nav animated:YES completion:^{
        
    }];
    
    // 选择完成后将数据返回
    imgPickVC.selectFinish = ^(NSDictionary *dic) {
        // 返回对象
        self.callback(@[dic]);
    };
}


@end
