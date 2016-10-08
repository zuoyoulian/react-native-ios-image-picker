//
//  TFImagePickerViewController.m
//  choosePhoto
//
//  Created by 左建军 on 16/6/24.
//  Copyright © 2016年 Facebook. All rights reserved.
//

#import "TFImagePickerViewController.h"
#import "TFBigImageViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "UIColor+hex.h"
#import <AssetsLibrary/ALAssetRepresentation.h>
#import <ImageIO/CGImageSource.h>
#import <ImageIO/CGImageProperties.h>
#import "CaptureViewController.h"


@interface TFImagePickerViewController () <UICollectionViewDataSource, UICollectionViewDelegate> {
    NSString *_path;  // 单张照片的保存的路径
    NSDictionary *_oldExifDic; // 单张照片的原始的exif信息
    NSString *_fileName;  // 单张照片的文件名
}

@property (nonatomic, strong) ALAssetsLibrary *assetsLibrary; // 设置成属性，防止生命周期提前结束
@property (nonatomic, strong) NSMutableArray *imagesArray;  // 用来保存相册中取出的照片

@property (nonatomic, strong) UILabel *numOfSelectLabel;  // 显示选择个数
@property (nonatomic, strong) UIButton *finishButton;  // 完成按钮

@property (nonatomic, strong) NSMutableArray *indexArray; // 位置数组，用来标记选中的图片的顺序

@end

@implementation TFImagePickerViewController

-(void)dealloc {
  // 移除消息
  [[NSNotificationCenter defaultCenter] removeObserver:self name:ImagePickerSelectFinishNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ImagePickerSelectMaxNumNotification object:nil];
}

// lazyloading创建数据源对象
-(NSMutableArray *)imagesArray {
  if (!_imagesArray) {
    self.imagesArray = [NSMutableArray arrayWithCapacity:0];
  }
  return _imagesArray;
}

- (NSMutableArray *)indexArray {
    if (!_indexArray) {
        self.indexArray = [NSMutableArray arrayWithCapacity:0];
    }
    return _indexArray;
}

- (void)getImageFromLibrary {
    // 获取相册访问权限状态值
    ALAuthorizationStatus authorizationStatus = [ALAssetsLibrary authorizationStatus];
    if(authorizationStatus == ALAuthorizationStatusRestricted || authorizationStatus == ALAuthorizationStatusDenied) {
        [self dismissViewControllerAnimated:YES completion:nil];
        NSLog(@"authorizationStatus = %ld", authorizationStatus);
        // 没有设置照片库权限，将 denied=YES 返回给js
        self.selectFinish(@{@"denied": @YES});
        return;
    }
    
    // 创建资源库对象
    self.assetsLibrary = [[ALAssetsLibrary alloc] init];
    [_assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        // 获取所有相片
        [group setAssetsFilter:[ALAssetsFilter allPhotos]];
        // 枚举器遍历相册
        [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
            if(result){
                // 如果缩略图对象存在证明有图片
                if ([UIImage imageWithCGImage:result.thumbnail]) {
                    // 创建字典对象来保存数据，flag标记是否图片被选中
                    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
                    // 标记为0，表示未被选中
                    [dic setObject:@"0" forKey:@"flag"];
                    // 将ALAsset对象保存，一个ALAsset是一张照片
                    [dic setObject:result forKey:@"result"];
                    [self.imagesArray addObject:dic];
                }
                
                // 获取到最后一张图片后，刷新UI展示照片
                if(index + 1 == group.numberOfAssets) {
                    // 刷新UI
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.collectionView reloadData];
                        // 滚到最下面，最下面是最新的照片
                        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
                    });
                }
            } else {
                // 判断是否获取到照片；有照片就返回
                if (self.imagesArray.count > 0) {
                    return;
                }
                // 照片库没有照片，显示提示框
                [self showAlertViewWithMessage:@"您的照片库中没有照片"];
            }
        }];
    } failureBlock:^(NSError *error) {
        [self dismissViewControllerAnimated:YES completion:nil];
        // 照片库访问出错，将错误信息返回给js
        self.selectFinish(@{@"error": error.localizedFailureReason});
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
  self.view.backgroundColor = [UIColor whiteColor];
  // 取消scrollview的自适应
//  self.automaticallyAdjustsScrollViewInsets = NO;
  // 设置导航条隐藏，使用自定义导航栏
    self.navigationController.navigationBarHidden = YES;

  // 创建子视图
  [self creatImageListView];  // 创建显示缩略图列表视图
  [self creatNavigationBarView];  // 创建自定义导航栏视图
  [self creatFinishBarView];  // 创建完成状态栏视图

  // 获取相册中照片数据
    [self getImageFromLibrary];
  // 默认设置当前选中0张照片
    self.currentNumOfSelection = 0;
  
  
  // 注册选择完成的消息
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectFinish:) name:ImagePickerSelectFinishNotification object:nil];
    // 注册选择到最大个数的消息
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectMaxNum:) name:ImagePickerSelectMaxNumNotification object:nil];
}


#pragma mark-创建视图-

- (void)creatNavigationBarView {
    
    // 导航背景视图
    UIView *navigationBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, NavigationBarHeight + StateBarHeight)];
    
    // 标题栏
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.center = CGPointMake(navigationBarView.center.x, navigationBarView.center.y + StateBarHeight/2);
    titleLabel.bounds = CGRectMake(0, 0, 200, 40);
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont systemFontOfSize:20];
    titleLabel.text = @"相册";
    [navigationBarView addSubview:titleLabel];
    
    // 取消按钮
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    cancelButton.frame = CGRectMake(ScreenWidth - 50, titleLabel.center.y - 15, 40, 30);
    [cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [cancelButton.titleLabel setFont:[UIFont systemFontOfSize:17]];
    [cancelButton addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchUpInside];
    [navigationBarView addSubview:cancelButton];
    
    // 设置默认值
    navigationBarView.backgroundColor = [UIColor blackColor];
    navigationBarView.alpha = 0.8;
    titleLabel.textColor = [UIColor whiteColor];
    [cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    // 通过js参数修改设置
    NSDictionary *listNavigationBarOptions = [self.options objectForKey:@"listNavigationBarOptions"];
    if (listNavigationBarOptions && [listNavigationBarOptions isKindOfClass:[NSDictionary class]]) {
        // 设置背景颜色
        if ([listNavigationBarOptions objectForKey:@"backgroundColor"]) {
            navigationBarView.backgroundColor = [UIColor colorWithHexString:[listNavigationBarOptions objectForKey:@"backgroundColor"] andAlpha:1.0];
        }
        // 设置透明度
        if ([listNavigationBarOptions objectForKey:@"alpha"]) {
            navigationBarView.alpha = [[listNavigationBarOptions objectForKey:@"alpha"] floatValue];
        }
        // 修改button和标题字体颜色
        if ([listNavigationBarOptions objectForKey:@"titleColor"]) {
            titleLabel.textColor = [UIColor colorWithHexString:[listNavigationBarOptions objectForKey:@"titleColor"] andAlpha:1.0];
            [cancelButton setTitleColor:[UIColor colorWithHexString:[listNavigationBarOptions objectForKey:@"titleColor"] andAlpha:1.0]  forState:UIControlStateNormal];
        }
    }
    
    [self.view addSubview:navigationBarView];
}

// 创建照片展示视图
- (void)creatImageListView {
  // 创建flowlayout
  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  layout.minimumLineSpacing = 2;
  layout.minimumInteritemSpacing = 2;
  layout.itemSize = CGSizeMake(ScreenWidth/4-6, ScreenWidth/4);
  layout.scrollDirection = UICollectionViewScrollDirectionVertical;
  layout.sectionInset = UIEdgeInsetsMake(2, 5, 0, 5);
  
  // 创建collectionview对象，设置代理，设置数据源
  self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight - TabBarHeight) collectionViewLayout:layout];
  [self.collectionView setContentInset:UIEdgeInsetsMake(NavigationBarHeight, 0, 0, 0)];
  _collectionView.backgroundColor = [UIColor whiteColor];
  _collectionView.delegate = self;
  _collectionView.dataSource = self;
  
  // 注册cell
  [_collectionView registerClass:[TFImagePickerCollectionViewCell class] forCellWithReuseIdentifier:@"ImagePickerCollectionViewCell"];
  
  [self.view addSubview:_collectionView];
}

//  创建底部完成状态栏
- (void)creatFinishBarView {
    UIView *finishView = [[UIView alloc] initWithFrame:CGRectMake(0, ScreenHeight - TabBarHeight, ScreenWidth, TabBarHeight)];
    
  // 显示选择个数
    self.numOfSelectLabel = [[UILabel alloc] initWithFrame:CGRectMake(finishView.bounds.size.width - 80, (TabBarHeight - 20)/2, 20, 20)];
    // label属性设置
    self.numOfSelectLabel.hidden = YES; // 默认label隐藏，没有选任何图片
    self.numOfSelectLabel.textAlignment = NSTextAlignmentCenter;
    self.numOfSelectLabel.layer.masksToBounds = YES;
    self.numOfSelectLabel.layer.cornerRadius = 10;
    [finishView addSubview:self.numOfSelectLabel];
  
  // 完成按钮
    self.finishButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.finishButton.frame = CGRectMake(finishView.bounds.size.width - 60, (TabBarHeight - 40)/2, 50, 40);
    [self.finishButton setTitle:@"完成" forState:UIControlStateNormal];
    [self.finishButton addTarget:self action:@selector(finishAction:) forControlEvents:UIControlEventTouchUpInside];
  // 完成按钮的初始化状态
    [self.finishButton setEnabled:NO];
    self.finishButton.alpha = 0.5;
    [finishView addSubview:self.finishButton];
    
//  完成状态栏分割线
    UIView *splitLineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 1 / [UIScreen mainScreen].scale)];
    splitLineView.backgroundColor = [UIColor colorWithRed:191 / 255.0 green:191 / 255.0 blue:191 / 255.0 alpha:1];
    [finishView addSubview:splitLineView];
    
    // 设置颜色，默认状态
    finishView.backgroundColor = [UIColor colorWithRed:250 / 255.0 green:250 / 255.0 blue:250 / 255.0 alpha:1];
    self.numOfSelectLabel.textColor = [UIColor whiteColor];
    self.numOfSelectLabel.backgroundColor = [UIColor colorWithRed:9 / 255.0 green:187 / 255.0 blue:7 / 255.0 alpha:1];
    [self.finishButton setTitleColor:[UIColor colorWithRed:9 / 255.0 green:187 / 255.0 blue:7 / 255.0 alpha:1] forState:UIControlStateNormal];
    
    // 通过js参数来修改设置
    NSDictionary *listFinishBarOptions = [self.options objectForKey:@"listFinishBarOptions"];
    if (listFinishBarOptions && [listFinishBarOptions isKindOfClass:[NSDictionary class]]) {
        // 状态栏背景色
        if ([listFinishBarOptions objectForKey:@"backgroundColor"]) {
            finishView.backgroundColor = [UIColor colorWithHexString:[listFinishBarOptions objectForKey:@"backgroundColor"] andAlpha:1.0];
        }
        // button字体色和label背景色
        if ([listFinishBarOptions objectForKey:@"tintColor"]) {
            [self.finishButton setTitleColor:[UIColor colorWithHexString:[listFinishBarOptions objectForKey:@"tintColor"] andAlpha:1.0] forState:UIControlStateNormal];
            self.numOfSelectLabel.backgroundColor = [UIColor colorWithHexString:[listFinishBarOptions objectForKey:@"tintColor"] andAlpha:1.0];
        }
        // label字体色
        if ([listFinishBarOptions objectForKey:@"titleColor"]) {
            self.numOfSelectLabel.textColor = [UIColor colorWithHexString:[listFinishBarOptions objectForKey:@"titleColor"] andAlpha:1.0];
        }
        // 分割线颜色
        if ([listFinishBarOptions objectForKey:@"splitLineColor"]) {
            splitLineView.backgroundColor = [UIColor colorWithHexString:[listFinishBarOptions objectForKey:@"splitLineColor"] andAlpha:1.0];
        }
        if ([listFinishBarOptions objectForKey:@"splitLineHeight"]) {
            splitLineView.frame = CGRectMake(0, 0, ScreenWidth, [[listFinishBarOptions objectForKey:@"splitLineHeight"] floatValue] / [UIScreen mainScreen].scale);
        }
    }
    [self.view addSubview:finishView];
}

//  显示提示框
- (void)showAlertViewWithMessage:(NSString *)message {
    if ([UIAlertController class] && [UIAlertAction class]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"我知道了" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancelAction];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:@"我知道了" otherButtonTitles:nil, nil];
        [alert show];
    }
}

#pragma mark -NSNotificationCenter-

// 选择照片数到最大个数的方法
- (void)selectMaxNum:(NSNotification *)notification {
    [self showAlertViewWithMessage:[NSString stringWithFormat:@"您最多只能选择%ld张照片", self.maxNumOfSelection]];
    /*
    if ([UIAlertController class] && [UIAlertAction class]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:[NSString stringWithFormat:@"您最多只能选择%ld张照片", self.maxNumOfSelection] preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"我知道了" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancelAction];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:@"您最多只能选择%ld张照片", self.maxNumOfSelection] delegate:nil cancelButtonTitle:@"我知道了" otherButtonTitles:nil, nil];
        [alert show];
    }
     */
}

//  选择完成消息方法，在方法中对当前选择的个数做修改
- (void)selectFinish:(NSNotification *)notification {
    // 对返回的flag做判断
    if ([[[notification userInfo] objectForKey:@"flag"] boolValue]) {
        // 为1表示选中，选中个数增1
        self.currentNumOfSelection++;
        // 位置数组中增加相对应的位置数据
        [self.indexArray addObject:[[notification userInfo] objectForKey:@"index"]];
    } else {
        // 为0表示取消选择，选中个数减1
        self.currentNumOfSelection--;
        // 位置数组中移除相对应的位置数据
        [self.indexArray removeObject:[[notification userInfo] objectForKey:@"index"]];
    }
    
    // 修改按钮的状态
    self.finishButton.enabled = self.currentNumOfSelection > 0 ? YES : NO;
    self.finishButton.alpha = self.currentNumOfSelection > 0 ? 1 : 0.5;
    
    // 修改显示选中个数的label的状态
    self.numOfSelectLabel.text = [NSString stringWithFormat:@"%ld", self.currentNumOfSelection];
    self.numOfSelectLabel.hidden = self.currentNumOfSelection > 0 ? NO : YES;
}


#pragma mark -按钮方法-

//  取消按钮方法
- (void)cancelAction:(id)barButton {
    self.selectFinish(@{@"didCancel": @YES});
    [self dismissViewControllerAnimated:YES completion:^{
    
    }];
}
// 完成按钮方法
- (void)finishAction:(UIButton *)button {
    
    // 创建数组对象，用来保存返回给js的数据
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:0];
    
    // 遍历选中的位置数组，找到所有被选中的图片
    for (NSNumber *index in self.indexArray) {
        
        NSDictionary *content = [self.imagesArray objectAtIndex:index.integerValue];
        
        // 获取图片信息
        ALAssetRepresentation *assertRepresentation = [[content objectForKey:@"result"] defaultRepresentation];
        
        // 获取图片信息
        UIImage *img = [UIImage imageWithCGImage:[assertRepresentation fullScreenImage]];
        
        // 获取原始图片信息
        NSDictionary *oDic = [self getExifDataFromALAsset:[content objectForKey:@"result"]];
        
        // 创建返回exif信息的对象
        NSMutableDictionary *exifDic = [NSMutableDictionary dictionaryWithDictionary:oDic];
        
        // 压缩图片
        // 按最大宽高比来压缩图片
        float maxWidth = img.size.width;
        float maxHeight = img.size.height;
        if ([self.options valueForKey:@"maxWidth"]) {
            maxWidth = [[self.options valueForKey:@"maxWidth"] floatValue];
        }
        if ([self.options valueForKey:@"maxHeight"]) {
            maxHeight = [[self.options valueForKey:@"maxHeight"] floatValue];
        }
        img = [self downscaleImageIfNecessary:img maxWidth:maxWidth maxHeight:maxHeight];
        
        // 按像素率来压缩
        NSData *data;
        if ([assertRepresentation.filename hasSuffix:@"png"] || [assertRepresentation.filename hasSuffix:@"PNG"]) {
            data = UIImagePNGRepresentation(img);
        } else {
            data = UIImageJPEGRepresentation(img, [[self.options valueForKey:@"quality"] floatValue]);
        }
        
        
        // 保存图片
        NSString *path = [self saveImageAtPathWithName:assertRepresentation.filename];
        if (!path) {
            // 如果图片路径不存在，返回错误信息， 错误信息在保存方法中回调
            return;
        }
        
        // 将数据写入沙盒，并获取url路径
        [data writeToFile:path atomically:YES];
        NSURL *fileURL = [NSURL fileURLWithPath:path];
        
        // 获取压缩后的图片的exif信息
        NSDictionary *nDic = [self getExifDataFromImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:fileURL]]];
        // 将信息追加到exifDic中
        [exifDic addEntriesFromDictionary:nDic];
        
        
        // 创建返回对象
        NSMutableDictionary *response = [NSMutableDictionary dictionaryWithCapacity:0];
        
        [response setObject:exifDic forKey:@"exif"];
        
        // 封装返回数据
        [response setObject:[fileURL absoluteString] forKey:@"uri"];
        [response setObject:@(img.size.width) forKey:@"width"];
        [response setObject:@(img.size.height) forKey:@"height"];
        NSNumber *fileSizeValue = nil;
        NSError *fileSizeError = nil;
        [fileURL getResourceValue:&fileSizeValue forKey:NSURLFileSizeKey error:&fileSizeError];
        if (fileSizeValue){
            [response setObject:fileSizeValue forKey:@"fileSize"];
        }
        
        // 是否备份到iclod
        if ([self.options objectForKey:@"storageOptions"] && [[self.options objectForKey:@"storageOptions"] isKindOfClass:[NSDictionary class]]) {
            NSDictionary *storageOptions = [self.options objectForKey:@"storageOptions"];
            
            if ([[storageOptions objectForKey:@"skipBackup"] boolValue]) {
                [self addSkipBackupAttributeToItemAtPath:path];  // 跳过iCloud备份
            }
        }
        [results addObject:response];
    }
    // 选择完成后将数据回调给js
    self.selectFinish(@{@"numOfSelect":@(_currentNumOfSelection), @"results":results});
    [self dismissViewControllerAnimated:YES completion:^{ }];
}


#pragma mark-Exif-
/*
//- (void)setExifDataAtDic:(NSMutableDictionary *)exifDic withData:(id)data {
//    if (data) {
//        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:nil];
//        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
//        NSLog(@"jsonString = %@", jsonString);
////        [exifDic setObject:data forKey:nss];
//    }
//}
*/

//  转换时间格式 转成 2016-07-6 18:21:39
- (NSString *)convertDateTimeForment:(NSString *)timeString {
    NSString *DateTime = timeString;
    DateTime = [DateTime stringByReplacingOccurrencesOfString:@":" withString:@""];
    DateTime = [DateTime stringByReplacingOccurrencesOfString:@" " withString:@""];
    DateTime = [DateTime stringByReplacingOccurrencesOfString:@"-" withString:@""];
    NSDateFormatter *dateFormattor = [[NSDateFormatter alloc] init];
    [dateFormattor setDateFormat:@"yyyyMMddHHmmss"];
    NSDate *date = [dateFormattor dateFromString:DateTime];
    
    [dateFormattor setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    DateTime = [dateFormattor stringFromDate: date];
    return DateTime;
}

// 获取原Exif信息
- (NSDictionary *)getExifDataFromALAsset:(ALAsset *)asset {
    ALAssetRepresentation *assertRepresentation = [asset defaultRepresentation];
    uint8_t *buffer = (Byte*)malloc(assertRepresentation.size);
    NSUInteger length = [assertRepresentation getBytes:buffer fromOffset: 0.0  length:assertRepresentation.size error:nil];
    if (length > 0) {
        // 添加exif信息
        NSMutableDictionary *exifInfo = [NSMutableDictionary dictionaryWithCapacity:0];
        
        NSData *photoData = [[NSData alloc] initWithBytesNoCopy:buffer length:assertRepresentation.size freeWhenDone:YES];
        CGImageSourceRef sourceRef = CGImageSourceCreateWithData((__bridge CFDataRef) photoData, NULL);
        CFDictionaryRef imagePropertiesDictionary = CGImageSourceCopyPropertiesAtIndex(sourceRef,0, NULL);
        NSDictionary *properties = (__bridge NSDictionary *)CGImageSourceCopyPropertiesAtIndex(sourceRef,0,NULL);
//        NSLog(@"properties = %@", properties);
        
        // tiff
        NSDictionary *tiffDic = [properties objectForKey:(NSString *)kCGImagePropertyTIFFDictionary];
        // exif
        NSDictionary *exifDic = [properties objectForKey:(NSString *)kCGImagePropertyExifDictionary];
        // gps
        NSMutableDictionary *GPSDic = [properties objectForKey:(NSString *)kCGImagePropertyGPSDictionary];
        
        
        // 颜色模式
        NSString *ColorModel = [properties objectForKey:(NSString *)kCGImagePropertyColorModel];
        if (ColorModel) {
            [exifInfo setObject:ColorModel forKey:@"ColorModel"];
        }
        // 分辨率
        NSString *DPIHeight = [properties objectForKey:(NSString *)kCGImagePropertyDPIHeight];
        
        NSString *DPIWidth = [properties objectForKey:(NSString *)kCGImagePropertyDPIWidth];
        if (DPIHeight) {
            [exifInfo setObject:DPIHeight forKey:@"DPIHeight"];
        }
        if (DPIWidth) {
            [exifInfo setObject:DPIWidth forKey:@"DPIWidth"];
        }
        // 每个像素字节数
        NSString *Depth = [properties objectForKey:(NSString *)kCGImagePropertyDepth];
        if (Depth) {
            [exifInfo setObject:Depth forKey:@"Depth"];
        }
//      方向和像素数使用压缩后的图片信息
        
//      TIFF
        // 生产商
        NSString *Make = [tiffDic objectForKey:(NSString *)kCGImagePropertyTIFFMake];
        if (Make) {
            [exifInfo setObject:Make forKey:@"Make"];
        }
        // 型号
        NSString *Model = [tiffDic objectForKey:(NSString *)kCGImagePropertyTIFFModel];
        if (Model) {
            [exifInfo setObject:Model forKey:@"Model"];
        }
        // 日期时间 创建
        NSString *DateTime = [self convertDateTimeForment:[tiffDic objectForKey:(NSString *)kCGImagePropertyTIFFDateTime]];
        if (DateTime) {
            [exifInfo setObject:DateTime forKey:@"DateTime"];
        }
        
//      Exif
        // 拍摄时间
        NSString *DateTimeOriginal = [self convertDateTimeForment:[exifDic objectForKey:(NSString *)kCGImagePropertyExifDateTimeOriginal]];
        if (DateTimeOriginal) {
            [exifInfo setObject:DateTimeOriginal forKey:@"DateTimeOriginal"];
        }
        // 照片写入内存卡时间
        NSString *DateTimeDigitized = [self convertDateTimeForment:[exifDic objectForKey:(NSString *)kCGImagePropertyExifDateTimeDigitized]];
        if (DateTimeDigitized) {
            [exifInfo setObject:DateTimeDigitized forKey:@"DateTimeDigitized"];
        }
        // 镜头制造商
        NSString *LensMake = [exifDic objectForKey:(NSString *)kCGImagePropertyExifLensMake];
        if (LensMake) {
            [exifInfo setObject:LensMake forKey:@"LensMake"];
        }
        // 镜头型号
        NSString *LensModel = [exifDic objectForKey:(NSString *)kCGImagePropertyExifLensModel];
        if (LensModel) {
            [exifInfo setObject:LensModel forKey:@"LensModel"];
        }
        
//      GPS
        // 海拔高度
        NSString *Altitude = [GPSDic objectForKey:(NSString *)kCGImagePropertyGPSAltitude];
        if (Altitude) {
            [exifInfo setObject:[NSString stringWithFormat:@"%@", Altitude] forKey:@"Altitude"];
        }
        // 纬度
        NSString *Latitude = [GPSDic objectForKey:(NSString *)kCGImagePropertyGPSLatitude];
        if (Latitude) {
            [exifInfo setObject:[NSString stringWithFormat:@"%@", Latitude] forKey:@"Latitude"];
        }
        // 纬度类型  南纬／北纬
        NSString *LatitudeRef = [GPSDic objectForKey:(NSString *)kCGImagePropertyGPSLatitudeRef];
        if (LatitudeRef) {
            [exifInfo setObject:LatitudeRef forKey:@"LatitudeRef"];
        }
        // 经度
        NSString *Longitude = [GPSDic objectForKey:(NSString *)kCGImagePropertyGPSLongitude];
        if (Longitude) {
            [exifInfo setObject:[NSString stringWithFormat:@"%@", Longitude] forKey:@"Longitude"];
        }
        // 经度类型 东经／西经
        NSString *LongitudeRef = [GPSDic objectForKey:(NSString *)kCGImagePropertyGPSLongitudeRef];
        if (LongitudeRef) {
            [exifInfo setObject:LongitudeRef forKey:@"LongitudeRef"];
        }
        
//        NSLog(@"exifInfo = %@", exifInfo);
        return exifInfo;
    } else {
        return nil;
    }
}

//  获取压缩后的Exif信息，主要获取压缩后的方向和宽高
-(NSDictionary *)getExifDataFromImage:(UIImage *)currentImage {
    
    NSData* pngData =  UIImageJPEGRepresentation(currentImage, 1.0);
    CGImageSourceRef mySourceRef = CGImageSourceCreateWithData((CFDataRef)pngData, NULL);
    if (mySourceRef != NULL) {
        NSDictionary *metaDic = (__bridge NSDictionary *)CGImageSourceCopyPropertiesAtIndex(mySourceRef,0,NULL);
        
        NSMutableDictionary *info = [NSMutableDictionary dictionaryWithCapacity:0];
        
        // 方向
        NSString *Orientation = [metaDic objectForKey:(NSString *)kCGImagePropertyOrientation];
        if (Orientation) {
            [info setObject:Orientation forKey:@"Orientation"];
        }
        // 水平方向上的像素点
        NSString *PixelWidth = [metaDic objectForKey:(NSString *)kCGImagePropertyPixelWidth];
        if (PixelWidth) {
            [info setObject:PixelWidth forKey:@"PixelWidth"];
        }
        // 垂直方向上的像素点
        NSString *PixelHeight = [metaDic objectForKey:(NSString *)kCGImagePropertyPixelHeight];
        if (PixelHeight) {
            [info setObject:PixelHeight forKey:@"PixelHeight"];
        }
        return info;
    } else {
        return nil;
    }
}


#pragma mark -保存图片-

//  按照最大宽高来压缩图片
- (UIImage*)downscaleImageIfNecessary:(UIImage*)image maxWidth:(float)maxWidth maxHeight:(float)maxHeight {
    UIImage* newImage = image;
    // 如果图像的宽和高都比最大值小，不需要压缩直接返回
    if (image.size.width <= maxWidth && image.size.height <= maxHeight) {
        return newImage;
    }
    
    // 将image的宽高转成CGSize变量
    CGSize scaledSize = CGSizeMake(image.size.width, image.size.height);
    if (maxWidth < scaledSize.width) {
        scaledSize = CGSizeMake(maxWidth, (maxWidth / scaledSize.width) * scaledSize.height);
    }
    if (maxHeight < scaledSize.height) {
        scaledSize = CGSizeMake((maxHeight / scaledSize.height) * scaledSize.width, maxHeight);
    }
    scaledSize.width = (int)scaledSize.width;
    scaledSize.height = (int)scaledSize.height;
    
    UIGraphicsBeginImageContext(scaledSize);
    [image drawInRect:CGRectMake(0, 0, scaledSize.width, scaledSize.height)];
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if (newImage == nil) {
        NSLog(@"could not scale image");
    }
    UIGraphicsEndImageContext();
    
    return newImage;
}

// 保存图片的方法
- (NSString *)saveImageAtPathWithName:(NSString *)fileName {
    NSString *path;
    // 如果storageOptions有值，表示需要将图片进行本地存储，保存到cache文件夹中
    if ([self.options objectForKey:@"storageOptions"] && [[self.options objectForKey:@"storageOptions"] isKindOfClass:[NSDictionary class]]) {
        NSDictionary *storageOptions = [self.options objectForKey:@"storageOptions"];
        //获取cache的路径
        NSString *cache = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        
        // 对path的值进行判断， path表示在外部规定图片存储的位置
        if ([storageOptions objectForKey:@"path"]) {
            // 如果path存在，在caches中创建文件夹路径
            NSString *newPath = [cache stringByAppendingPathComponent:[storageOptions objectForKey:@"path"]];
            NSError *error;
            // 创建文件夹，如果文件夹存在，不需要创建
            if (![[NSFileManager defaultManager] fileExistsAtPath:newPath]) {
                [[NSFileManager defaultManager] createDirectoryAtPath:newPath withIntermediateDirectories:YES attributes:nil error:&error];
                if (error) {
                    // 创建错误，将错误返回
                    self.selectFinish(@[@{@"error": error.localizedFailureReason}]);
                    return nil;
                }
            }
            // 拼接图片路径
            path = [newPath stringByAppendingPathComponent:fileName];
        } else {
            // 如果path不存在，直接保存到caches文件夹中
            path = [cache stringByAppendingPathComponent:fileName];
        }
    } else {
        // 没有值，创建tmp文件夹路径，将图片保存到tmp中，程序一退出就会被清空
        path = [[NSTemporaryDirectory()stringByStandardizingPath] stringByAppendingPathComponent:fileName];
    }
    
    return path;
}

// 跳过备份到iCloud和iTunes
- (BOOL)addSkipBackupAttributeToItemAtPath:(NSString *)filePathString {
    NSURL* URL= [NSURL fileURLWithPath: filePathString];
    if ([[NSFileManager defaultManager] fileExistsAtPath: [URL path]]) {
        NSError *error = nil;
        BOOL success = [URL setResourceValue: [NSNumber numberWithBool: YES]
                                      forKey: NSURLIsExcludedFromBackupKey error: &error];
        
        if(!success){
            NSLog(@"error: %@", error);
        }
        return success;
    }
    else {
        NSLog(@"找不到文件");
        return @NO;
    }
}


#pragma mark -collectionView回调方法-

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return self.imagesArray.count;
}
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  // 创建cell
  TFImagePickerCollectionViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ImagePickerCollectionViewCell" forIndexPath:indexPath];
  // 创建subview
  [cell creatSubviewsWithDic:self.imagesArray[indexPath.row]];
  
  cell.imagePickerVC = self;
  
  return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  
    if (self.maxNumOfSelection == 1) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cropOKNotificationHandler:) name: @"CropOK" object: nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cropCancelNotificationHandler:) name: @"CropCancel" object: nil];
        
        NSDictionary *content = [self.imagesArray objectAtIndex:indexPath.row];
        
        // 获取图片信息
        ALAssetRepresentation *assertRepresentation = [[content objectForKey:@"result"] defaultRepresentation];
        
        // 获取图片信息
        UIImage *img = [UIImage imageWithCGImage:[assertRepresentation fullScreenImage]];
        
        // 获取原始图片信息
        _oldExifDic = [self getExifDataFromALAsset:[content objectForKey:@"result"]];
        _fileName = assertRepresentation.filename;
        // 保存图片
        _path = [self saveImageAtPathWithName:assertRepresentation.filename];
        if (!_path) {
            // 如果图片路径不存在，返回错误信息， 错误信息在保存方法中回调
            return;
        }
        
        CaptureViewController *captureView = [[CaptureViewController alloc] init];
        captureView.image = img;
        
        // 裁剪设置项
        NSDictionary *cropOptions = [self.options objectForKey:@"cropOptions"];
        if (cropOptions && [cropOptions isKindOfClass:[NSDictionary class]]) {
            captureView.cropOptions = cropOptions;
        }
        
        [self.navigationController pushViewController:captureView animated:YES];
    } else {
        TFBigImageViewController *bigImageVC = [[TFBigImageViewController alloc] init];
        bigImageVC.currentPageIndex = indexPath.row;
        bigImageVC.allPhotos = self.imagesArray;
        bigImageVC.imagePickerVC = self;
        
        // block回调，在大图中选择时刷新对应的cell
        bigImageVC.selectImg = ^(NSInteger currentIndex) {
            [collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:currentIndex inSection:0]]];
        };
        [self.navigationController pushViewController:bigImageVC animated:YES];
    }
}

- (void)cropCancelNotificationHandler:(NSNotification *)notification {
//    self.selectFinish(@{@"didCancel": @YES});
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CropOK" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CropCancel" object:nil];
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)cropOKNotificationHandler:(NSNotification *)notification {
    UIImage *image = (UIImage *)notification.object;
    
    // 创建返回对象
    NSMutableDictionary *response = [NSMutableDictionary dictionaryWithCapacity:0];
    // 创建返回exif信息的对象
    NSMutableDictionary *exifDic = [NSMutableDictionary dictionaryWithDictionary:_oldExifDic];
    
    // 按像素率来压缩
    NSData *data;
    if ([_fileName hasSuffix:@"png"] || [_fileName hasSuffix:@"PNG"]) {
        data = UIImagePNGRepresentation(image);
    } else {
        data = UIImageJPEGRepresentation(image, [[self.options valueForKey:@"quality"] floatValue]);
    }
    
    // 将图片信息写入文件中
    [data writeToFile:_path atomically:YES];
    NSURL *fileURL = [NSURL fileURLWithPath:_path];
    
    // 获取压缩后的图片的exif信息
    NSDictionary *nDic = [self getExifDataFromImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:fileURL]]];
    // 将信息追加到exifDic中
    [exifDic addEntriesFromDictionary:nDic];
    [response setObject:exifDic forKey:@"exif"];
    
    // 封装返回数据
    [response setObject:[fileURL absoluteString] forKey:@"uri"];
    [response setObject:@(image.size.width) forKey:@"width"];
    [response setObject:@(image.size.height) forKey:@"height"];
    NSNumber *fileSizeValue = nil;
    NSError *fileSizeError = nil;
    [fileURL getResourceValue:&fileSizeValue forKey:NSURLFileSizeKey error:&fileSizeError];
    if (fileSizeValue){
        [response setObject:fileSizeValue forKey:@"fileSize"];
    }
    
    // 是否备份到iclod
    if ([self.options objectForKey:@"storageOptions"] && [[self.options objectForKey:@"storageOptions"] isKindOfClass:[NSDictionary class]]) {
        NSDictionary *storageOptions = [self.options objectForKey:@"storageOptions"];
        
        if ([[storageOptions objectForKey:@"skipBackup"] boolValue]) {
            [self addSkipBackupAttributeToItemAtPath:_path];  // 跳过iCloud备份
        }
    }
    
    // 创建数组对象，用来保存返回给js的数据
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:0];
    [results addObject:response];
    
    // 选择完成后将数据回调给js
    [self dismissViewControllerAnimated:YES completion:^{
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CropOK" object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CropCancel" object:nil];
        self.selectFinish(@{@"numOfSelect":@(1), @"results":results});
    }];
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

@interface TFImagePickerCollectionViewCell ()

@property (nonatomic, strong) UIImageView *imgView;
@property (nonatomic, strong) UIButton *selButton;

@property (nonatomic, strong) NSDictionary *contentDic;

@end

@implementation TFImagePickerCollectionViewCell


- (void)creatSubviewsWithDic:(NSDictionary *)contentDic {
  
  self.contentDic = contentDic;
  
  // 创建imageview 显示缩略图
  if (!self.imgView) {
    self.imgView = [[UIImageView alloc] initWithFrame:self.contentView.bounds];
    [self.contentView addSubview:self.imgView];
  }
  // 获取缩略图，实时更新图片信息
  ALAsset *result = [contentDic objectForKey:@"result"];
  self.imgView.image = [UIImage imageWithCGImage:result.thumbnail];

  // 创建button
  if (!self.selButton) {
    self.selButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.selButton.frame = CGRectMake(self.contentView.frame.size.width - 30, 0, 30, 30);
    
    [self.selButton addTarget:self action:@selector(setSelectFlag:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.selButton];
  }
  // cell复用 设置button的图标
  [self changeButtonImg:contentDic];
}

//  button关联的修改flag的方法
- (void)setSelectFlag:(UIButton *)button {
  // flag用来标记照片被选中的状态
  BOOL flag;
    
  if ([self.contentDic[@"flag"] integerValue] == 0) {
    // 如果选择个数大于等于最大选择数，不能再增加
    if (self.imagePickerVC.currentNumOfSelection >= self.imagePickerVC.maxNumOfSelection) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ImagePickerSelectMaxNumNotification object:nil];
        return;
    }
    // 修改标记
    [self.contentDic setValue:@"1" forKey:@"flag"];
    flag = YES;
  } else {
    // 修改标记
    [self.contentDic setValue:@"0" forKey:@"flag"];
    flag = NO;
  }
  
  // 选择后修改选择按钮状态
  [self changeButtonImg:self.contentDic];
  
  // 发通知，通知已经对照片做了选择，将选择的照片的位置和标记都返回给观察者做处理
    NSIndexPath *index = [self.imagePickerVC.collectionView indexPathForCell:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:ImagePickerSelectFinishNotification object:nil userInfo:@{@"flag" : @(flag), @"index" : @(index.row)}];
}

// 修改button状态图标
- (void)changeButtonImg:(NSDictionary *)dic {
    // 从bundle中读图片资源
    NSBundle *rnBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"RNImage" ofType: @"bundle"]];
    
    if ([dic[@"flag"] integerValue] == 0) {
        // 标记为0，表示未选中状态
        NSString *unselectPath = [rnBundle pathForResource:@"image_unselect" ofType:@"png" inDirectory:@"images"];
        // 加载未选中按钮
        [self.selButton setBackgroundImage:[UIImage imageWithContentsOfFile:unselectPath] forState:UIControlStateNormal];
//        [self.selButton setBackgroundImage:[UIImage imageNamed:@"image_unselect.png"] forState:UIControlStateNormal];
    } else {
        // 为0，表示选中状态
        NSString *selectPath = [rnBundle pathForResource:@"image_select" ofType:@"png" inDirectory:@"images"];
        // 加载选中按钮
        [self.selButton setBackgroundImage:[UIImage imageWithContentsOfFile:selectPath] forState:UIControlStateNormal];
//        [self.selButton setBackgroundImage:[UIImage imageNamed:@"image_select.png"] forState:UIControlStateNormal];
    }
}

@end


