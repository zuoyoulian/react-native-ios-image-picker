//
//  CaptureViewController.m
//  图片裁剪demo
//
//  Created by 左建军 on 16/9/29.
//  Copyright © 2016年 tuofeng. All rights reserved.
//

#import "CaptureViewController.h"
#import "TKImageView.h"
#import "UIColor+hex.h"

#define SCREENWIDTH [UIScreen mainScreen].bounds.size.width
#define SCREENHEIGHT [UIScreen mainScreen].bounds.size.height
#define CROP_PROPORTION_IMAGE_WIDTH 30.0f
#define CROP_PROPORTION_IMAGE_SPACE 48.0f
#define CROP_PROPORTION_IMAGE_PADDING 20.0f

@interface CaptureViewController () {
    
    TKImageView *_tkImageView;
}

@end

@implementation CaptureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor blackColor];
    
    _tkImageView = [[TKImageView alloc] init];
    CGFloat scale = self.image.size.height / self.image.size.width;
    _tkImageView.center = CGPointMake(SCREENWIDTH*0.5, SCREENHEIGHT *0.5);
    _tkImageView.bounds = CGRectMake(0, 0, SCREENWIDTH, SCREENHEIGHT *scale);
    
    _tkImageView.toCropImage = self.image;
    
    if (self.cropOptions[@"showMidLines"]) {
        _tkImageView.showMidLines = [self.cropOptions[@"showMidLines"] boolValue];
    }
    if (self.cropOptions[@"minSpace"]) {
        _tkImageView.minSpace = [self.cropOptions[@"minSpace"] integerValue];  // 设置最小区域
    }
    if (self.cropOptions[@"cropAreaCornerWidth"]) {
        _tkImageView.cropAreaCornerWidth = [self.cropOptions[@"cropAreaCornerWidth"] integerValue];  //  角框的宽
    }
    if (self.cropOptions[@"cropAreaCornerHeight"]) {
        _tkImageView.cropAreaCornerHeight = [self.cropOptions[@"cropAreaCornerHeight"] integerValue];  // 角框的高
    }
    if (self.cropOptions[@"cropAreaCornerLineWidth"]) {
        _tkImageView.cropAreaCornerLineWidth = [self.cropOptions[@"cropAreaCornerLineWidth"] integerValue]; // 角框的宽度
    }
    if (self.cropOptions[@"cropAreaBorderLineWidth"]) {
        _tkImageView.cropAreaBorderLineWidth = [self.cropOptions[@"cropAreaBorderLineWidth"] integerValue]; // 线框的宽度
    }
    if (self.cropOptions[@"cropAreaMidLineWidth"]) {
        _tkImageView.cropAreaMidLineWidth = [self.cropOptions[@"cropAreaMidLineWidth"] integerValue]; // 中间线的宽度
    }
    if (self.cropOptions[@"cropAreaMidLineHeight"]) {
        _tkImageView.cropAreaMidLineHeight = [self.cropOptions[@"cropAreaMidLineHeight"] integerValue]; // 中间线的高度
    }
    if (self.cropOptions[@"cropAreaBorderLineColor"]) {
        _tkImageView.cropAreaBorderLineColor = [UIColor colorWithHexString:self.cropOptions[@"cropAreaBorderLineColor"] andAlpha:1.0];  // 边框颜色
    }
    if (self.cropOptions[@"cropAreaCornerLineColor"]) {
        _tkImageView.cropAreaCornerLineColor = [UIColor colorWithHexString:self.cropOptions[@"cropAreaCornerLineColor"] andAlpha:1.0];  // 角的颜色
    }
    if (self.cropOptions[@"cropAreaMidLineColor"]) {
        _tkImageView.cropAreaMidLineColor = [UIColor colorWithHexString:self.cropOptions[@"cropAreaMidLineColor"] andAlpha:1.0];  // 中线的颜色
    }
    
    [self.view addSubview:_tkImageView];
    
    
    
    // 下导航背景视图
    UIView *finishView = [[UIView alloc] initWithFrame:CGRectMake(0, SCREENHEIGHT - 80, SCREENWIDTH, 80)];
    finishView.backgroundColor = [UIColor blackColor];
    
    [self.view addSubview:finishView];
    
    
    UIButton *finishButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    finishButton.frame = CGRectMake(finishView.bounds.size.width - 60, (80 - 40)/2, 50, 40);
    [finishButton setTitle:@"完成" forState:UIControlStateNormal];
    [finishButton addTarget:self action:@selector(finishAction:) forControlEvents:UIControlEventTouchUpInside];
    finishButton.titleLabel.font = [UIFont systemFontOfSize:18];
    [finishButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [finishView addSubview:finishButton];
    
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    cancelButton.frame = CGRectMake(10, (80 - 40)/2, 50, 40);
    [cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    cancelButton.titleLabel.font = [UIFont systemFontOfSize:18];
    [cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchUpInside];
    [finishView addSubview:cancelButton];
    
    //添加导航栏和完成按钮
//    UINavigationBar *naviBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, SCREENHEIGHT - 49, SCREENWIDTH, 49)];
//    [self.view addSubview:naviBar];
//    UINavigationItem *naviItem = [[UINavigationItem alloc] initWithTitle:@"图片裁剪"];
//    [naviBar pushNavigationItem:naviItem animated:YES];
//
//    //保存按钮
//    UIBarButtonItem *doneItem = [[UIBarButtonItem alloc] initWithTitle:@"保存" style:UIBarButtonItemStylePlain target:self action:@selector(saveButton)];
//    naviItem.rightBarButtonItem = doneItem;
}

- (void)cancelAction:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CropCancel" object: nil];
//    [self dismissViewControllerAnimated:YES completion:^{
//        
// 
//    }];
}

//完成截取
-(void)finishAction:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CropOK" object: [_tkImageView currentCroppedImage]];
//    [self dismissViewControllerAnimated:YES completion:^{
//        
//    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
