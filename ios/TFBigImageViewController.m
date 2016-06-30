//
//  TFBigImageViewController.m
//  choosePhoto
//
//  Created by 左建军 on 16/6/24.
//  Copyright © 2016年 Facebook. All rights reserved.
//

#import "TFBigImageViewController.h"
#import "TFImagePickerViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "UIColor+hex.h"

@interface TFBigImageViewController ()<UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray *contentViews; // 内容显示数据
@property (nonatomic, strong) UIButton *selButton;  // 选择按钮

@property (nonatomic, strong) UILabel *numOfSelectLabel;  // 显示选择个数
@property (nonatomic, strong) UIButton *finishButton;  // 完成按钮

@property (nonatomic, strong) NSDictionary *options; // js传入的参数数


@end

@implementation TFBigImageViewController


-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // 隐藏状态栏
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}
-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // 显示状态栏
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
  
    
    self.view.backgroundColor = [UIColor blackColor];
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.navigationController.navigationBarHidden = YES;
    
    self.options = self.imagePickerVC.options;
  
    
    // 创建UIScrollView对象，最底层的滚动图
    self.scrollView = [[UIScrollView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.scrollView.contentSize = CGSizeMake(3 * ScreenWidth, ScreenHeight);
    self.scrollView.delegate = self;
    self.scrollView.contentOffset = CGPointMake(ScreenWidth, 0);
    self.scrollView.pagingEnabled = YES;
    _scrollView.bounces = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    [self.view addSubview:self.scrollView];
    
    // 创建上导航和下导航视图
    [self creatNavigationBarView];
    [self creatFinishBarView];
  
    // 设置滚动视图数据
    [self setScrollViewContentDataSource];
    [self configContentViews];
}


#pragma mark-创建视图-

//  创建上导航条
- (void)creatNavigationBarView {
    // 导航背景视图
    UIView *navigationBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, NavigationBarHeight + StateBarHeight)];
    navigationBarView.tag = 4001;
    
    // 设置默认值
    navigationBarView.backgroundColor = [UIColor blackColor];
    navigationBarView.alpha = 0.5;
    // 通过js参数修改设置
    NSDictionary *bigNavigationBarOptions = [self.options objectForKey:@"bigNavigationBarOptions"];
    if (bigNavigationBarOptions && [bigNavigationBarOptions isKindOfClass:[NSDictionary class]]) {
        // 修改背景颜色
        if ([bigNavigationBarOptions objectForKey:@"backgroundColor"]) {
            navigationBarView.backgroundColor = [UIColor colorWithHexString:[bigNavigationBarOptions objectForKey:@"backgroundColor"] andAlpha:1.0];
        }
        // 修改透明度
        if ([bigNavigationBarOptions objectForKey:@"alpha"]) {
            navigationBarView.alpha = [[bigNavigationBarOptions objectForKey:@"alpha"] floatValue];
        }
    }
    
    // 返回按钮
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    backButton.bounds = CGRectMake(0, 0, 40, 40);
    backButton.center = CGPointMake(30, navigationBarView.center.y);
    NSBundle *rnBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"RNImage" ofType: @"bundle"]];
    NSString *backPath = [rnBundle pathForResource:@"image_back" ofType:@"png" inDirectory:@"images"];
    [backButton setBackgroundImage:[UIImage imageWithContentsOfFile:backPath] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(backAction:) forControlEvents:UIControlEventTouchUpInside];
    [navigationBarView addSubview:backButton];
    
    // 选择按钮
    self.selButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    _selButton.bounds = CGRectMake(0, 0, 40, 40);
    _selButton.center = CGPointMake(ScreenWidth - _selButton.bounds.size.width/2 - 10, navigationBarView.center.y);
    [self.selButton addTarget:self action:@selector(setSelectFlag:) forControlEvents:UIControlEventTouchUpInside];
    [navigationBarView addSubview:_selButton];
    
    [self.view addSubview:navigationBarView];
}

//  创建底部完成完成状态栏
- (void)creatFinishBarView {
    // 下导航背景视图
    UIView *finishView = [[UIView alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 49, [UIScreen mainScreen].bounds.size.width, 49)];
    finishView.tag = 4002;
    
    // 显示选择个数的label
    self.numOfSelectLabel = [[UILabel alloc] initWithFrame:CGRectMake(finishView.bounds.size.width - 80, (49 - 20)/2, 20, 20)];
    self.numOfSelectLabel.text = [NSString stringWithFormat:@"%ld", self.imagePickerVC.currentNumOfSelection];
    // 初始值，当有选择个数时显示，没有选择时隐藏
    self.numOfSelectLabel.hidden = self.imagePickerVC.currentNumOfSelection > 0 ? NO : YES;
    // 属性设置
    self.numOfSelectLabel.textAlignment = NSTextAlignmentCenter;
    self.numOfSelectLabel.layer.masksToBounds = YES;
    self.numOfSelectLabel.layer.cornerRadius = 10;
    [finishView addSubview:self.numOfSelectLabel];
    
    // 完成按钮
    self.finishButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.finishButton.frame = CGRectMake(finishView.bounds.size.width - 60, (49 - 40)/2, 50, 40);
    [self.finishButton setTitle:@"完成" forState:UIControlStateNormal];
    [self.finishButton addTarget:self action:@selector(finishAction:) forControlEvents:UIControlEventTouchUpInside];
    // 完成按钮的初始状态赋值
    if (self.imagePickerVC.currentNumOfSelection == 0) {
        [self.finishButton setEnabled:NO];
        self.finishButton.alpha = 0.5;
    }
    [finishView addSubview:self.finishButton];
    
    // 设置默认状态参数值
    finishView.backgroundColor = [UIColor blackColor];
    finishView.alpha = 0.5;
    self.numOfSelectLabel.textColor = [UIColor whiteColor];
    self.numOfSelectLabel.backgroundColor = [UIColor greenColor];
    [self.finishButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    // 通过js参数修改设置
    NSDictionary *bigFinishBarOptions = [self.options objectForKey:@"bigFinishBarOptions"];
    if (bigFinishBarOptions && [bigFinishBarOptions isKindOfClass:[NSDictionary class]]) {
        // 修改背景色
        if ([bigFinishBarOptions objectForKey:@"backgroundColor"]) {
            finishView.backgroundColor = [UIColor colorWithHexString:[bigFinishBarOptions objectForKey:@"backgroundColor"] andAlpha:1.0];
        }
        // 修改透明度
        if ([bigFinishBarOptions objectForKey:@"alpha"]) {
            finishView.alpha = [[bigFinishBarOptions objectForKey:@"alpha"] floatValue];
        }
        
        // 修改label字体颜色
        if ([bigFinishBarOptions objectForKey:@"titleColor"]) {
            self.numOfSelectLabel.textColor = [UIColor colorWithHexString:[bigFinishBarOptions objectForKey:@"titleColor"] andAlpha:1.0];
        }
        
        // 修改按钮title颜色 和 label背景颜色
        if ([bigFinishBarOptions objectForKey:@"tintColor"]) {
            [self.finishButton setTitleColor:[UIColor colorWithHexString:[bigFinishBarOptions objectForKey:@"tintColor"] andAlpha:1.0] forState:UIControlStateNormal];
            self.numOfSelectLabel.backgroundColor = [UIColor colorWithHexString:[bigFinishBarOptions objectForKey:@"tintColor"] andAlpha:1.0];
        }
    }
    [self.view addSubview:finishView];
}


#pragma mark-按钮方法-
//  返回按钮
- (void)backAction:(UIButton *)button {
    [self.navigationController popViewControllerAnimated:YES];
}
//  完成按钮
- (void)finishAction:(UIButton *)button {
    [self.imagePickerVC finishAction:nil];
}
//  选择按钮
- (void)setSelectFlag:(UIButton *)button {
    BOOL flag;
    // 修改当前对应的dic对象的flag值
    NSDictionary *photoDic = self.allPhotos[self.currentPageIndex];
    if ([photoDic[@"flag"] integerValue] == 0) {
        if (self.imagePickerVC.currentNumOfSelection >= self.imagePickerVC.maxNumOfSelection) {
            return;
        }
        [photoDic setValue:@"1" forKey:@"flag"];
        flag = YES;
    } else {
        [photoDic setValue:@"0" forKey:@"flag"];
        flag = NO;
    }
    
    // 回调让当前选择的位置对应的cell刷新
    self.selectImg(self.currentPageIndex);
    
    // 发通知，通知其他对象照片已经做了选择
    [[NSNotificationCenter defaultCenter] postNotificationName:ImagePickerSelectFinishNotification object:nil userInfo:@{@"flag" : @(flag), @"index" : @(self.currentPageIndex)}];
    
    // 修改选择按钮的图标
    [self changeButtonImg];
}

// 修改按钮的图标
- (void)changeButtonImg {
    
    NSDictionary *photoDic = self.allPhotos[self.currentPageIndex];
    
    // 从bundle中读图片资源
    NSBundle *rnBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"RNImage" ofType: @"bundle"]];
    if ([photoDic[@"flag"] integerValue] == 0) {
        NSString *unselectPath = [rnBundle pathForResource:@"image_unselect" ofType:@"png" inDirectory:@"images"];
        [self.selButton setBackgroundImage:[UIImage imageWithContentsOfFile:unselectPath] forState:UIControlStateNormal];
//        [self.selButton setBackgroundImage:[UIImage imageNamed:@"image_unselect.png"] forState:UIControlStateNormal];
    } else {
        NSString *selectPath = [rnBundle pathForResource:@"image_select" ofType:@"png" inDirectory:@"images"];
        [self.selButton setBackgroundImage:[UIImage imageWithContentsOfFile:selectPath] forState:UIControlStateNormal];
//        [self.selButton setBackgroundImage:[UIImage imageNamed:@"image_select.png"] forState:UIControlStateNormal];
    }
    
    // 修改完成按钮的状态
    self.finishButton.enabled = self.imagePickerVC.currentNumOfSelection > 0 ? YES : NO;
    self.finishButton.alpha = self.imagePickerVC.currentNumOfSelection > 0 ? 1 : 0.5;
    
    // 修改显示选中个数的label的状态
    self.numOfSelectLabel.text = self.imagePickerVC.currentNumOfSelection > 0 ? [NSString stringWithFormat:@"%ld", self.imagePickerVC.currentNumOfSelection] : @"";
    
    // 显示选择个数的label背景颜色，从js传入
    self.numOfSelectLabel.hidden = self.imagePickerVC.currentNumOfSelection > 0 ? NO : YES;
}


#pragma mark-配置滚动视图-

// 根据index获取数组中的位置
- (NSInteger)getNextPageIndex:(NSInteger)currentPageIndex {
  if(currentPageIndex == -1) {
    return self.allPhotos.count - 1;
  } else if (currentPageIndex == self.allPhotos.count) {
    return 0;
  } else {
    return currentPageIndex;
  }
}

// 设置滚动视图数据
- (void)setScrollViewContentDataSource {
  if (self.contentViews == nil) {
    self.contentViews = [@[] mutableCopy];
  }
  [self.contentViews removeAllObjects];
  
  // 获取前一个位置和后一个位置
  NSInteger beforePageIndex = [self getNextPageIndex:self.currentPageIndex - 1];
  NSInteger afterPageIndex = [self getNextPageIndex:self.currentPageIndex + 1];
  [self.contentViews addObject:self.allPhotos[beforePageIndex]];
  [self.contentViews addObject:self.allPhotos[_currentPageIndex]];
  [self.contentViews addObject:self.allPhotos[afterPageIndex]];
}

// 页面赋值
- (void)configContentViews {
  // 获取数据
  [self setScrollViewContentDataSource];
  
  __block NSInteger counter = 0;
  for (NSDictionary *content in self.contentViews) {
      // 获取图片
      UIImage *img = [UIImage imageWithCGImage:[[content objectForKey:@"result"] aspectRatioThumbnail]];
      
      // 创建滚动视图对象，目的是放大缩小
      UIScrollView *imgScrollView = (UIScrollView *)[_scrollView viewWithTag:1000 + counter];
      if (!imgScrollView) {
          imgScrollView = [[UIScrollView alloc] init];
      }
      imgScrollView.tag = 1000 + counter;
      imgScrollView.maximumZoomScale = 2;
      imgScrollView.minimumZoomScale = 1;
      imgScrollView.showsHorizontalScrollIndicator = NO;
      imgScrollView.showsVerticalScrollIndicator = NO;
      imgScrollView.delegate = self;
      
      // 创建图片视图对象，显示照片
      UIImageView *contentView = (UIImageView *)[imgScrollView viewWithTag:2000 + counter];
      if (!contentView) {
          contentView = [[UIImageView alloc] init];
      }
      contentView.tag = 2000 + counter;
      contentView.image = img;
      
      // 加轻拍手势，用来对导航条进行隐藏
      contentView.userInteractionEnabled = YES;
      UITapGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doTap:)];
      [contentView addGestureRecognizer:tapGR];
    
      // 设置视图大小
      imgScrollView.frame = CGRectMake(ScreenWidth * counter, 0, ScreenWidth, ScreenHeight);
      CGFloat scale = img.size.height / img.size.width;
      contentView.center = CGPointMake(ScreenWidth*0.5, ScreenHeight *0.5);
      contentView.bounds = CGRectMake(0, 0, ScreenWidth, ScreenWidth *scale);
    
      [imgScrollView addSubview:contentView];
      [self.scrollView addSubview:imgScrollView];
      counter++;
  }
    // 每次当前显示页是第二页，也就是tag为1001和2001的视图
    [_scrollView setContentOffset:CGPointMake(ScreenWidth, 0)];
    
    // 修改视图显示状态
    [self changeButtonImg];
}


#pragma mark-轻拍手势的方法-
- (void)doTap:(id)sender {
    // 获取上下两个导航条
    UIView *navigationView = [self.view viewWithTag:4001];
    UIView *finishView = [self.view viewWithTag:4002];
    if (navigationView.hidden) {
        navigationView.hidden = NO;
        finishView.hidden = NO;
    } else {
        navigationView.hidden = YES;
        finishView.hidden = YES;
    }
}


#pragma mark -加载高清图-
//  第一次视图加载完成时加载高清图
-(void)viewDidAppear:(BOOL)animated {
    UIImageView *contentView = (UIImageView *)[self.view viewWithTag:2001];
    UIImage *fullImg = [UIImage imageWithCGImage:[[[[self.contentViews objectAtIndex:1] objectForKey:@"result"] defaultRepresentation] fullScreenImage]];
//    NSData *data = UIImageJPEGRepresentation(fullImg, 0.8);
//    UIImage *fimg = [UIImage imageWithData:data];
    contentView.image = fullImg;
}
//  减速结束时加载高清图
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    UIImageView *contentView = (UIImageView *)[self.view viewWithTag:2001];
    UIImage *fullImg = [UIImage imageWithCGImage:[[[[self.contentViews objectAtIndex:1] objectForKey:@"result"] defaultRepresentation] fullScreenImage]];
//    NSData *data = UIImageJPEGRepresentation(fullImg, 0.8);
//    UIImage *fimg = [UIImage imageWithData:data];
    contentView.image = fullImg;
}

#pragma mark-scrollView的回调-

// 返回缩放对象
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
  if (!(scrollView == _scrollView)) {
     return [scrollView viewWithTag:2001];
  } else {
    return nil;
  }
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(nullable UIView *)view atScale:(CGFloat)scale {
//    NSLog(@"scrollView.tag = %@, view.tag = %@, contentSize = %@", scrollView, view, NSStringFromCGSize(scrollView.contentSize));
    if (!(scrollView == _scrollView)) {
        [UIView animateWithDuration:0.1 animations:^{
            if (scale > 1) {
                if ([UIScreen mainScreen].bounds.size.height < scrollView.contentSize.height) {
                    view.frame = CGRectMake(view.frame.origin.x, 0, view.frame.size.width, view.frame.size.height);
                } else {
                    view.center = CGPointMake(scrollView.frame.size.width*0.5, scrollView.frame.size.height *0.5);
                }
            } else {
                view.center = CGPointMake(scrollView.frame.size.width*0.5, scrollView.frame.size.height *0.5);
            }
        }];
    }
}

//  滚动翻页
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  if (scrollView == _scrollView) {
    int contentOffsetX = scrollView.contentOffset.x;
    if(contentOffsetX >= (2 * CGRectGetWidth(scrollView.frame))) {
      self.currentPageIndex = [self getNextPageIndex:self.currentPageIndex + 1];
        for (UIScrollView *view in scrollView.subviews) {
            if ([view isKindOfClass:[UIScrollView class]]) {
                view.zoomScale = 1;
            }
        }
      [self configContentViews];
    }
    if(contentOffsetX <= 0) {
      self.currentPageIndex = [self getNextPageIndex:self.currentPageIndex - 1];
        for (UIScrollView *view in scrollView.subviews) {
            if ([view isKindOfClass:[UIScrollView class]]) {
                view.zoomScale = 1;
            }
        }
      [self configContentViews];
    }
  }
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
