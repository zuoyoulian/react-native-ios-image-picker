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


@interface TFImagePickerViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

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
    // 创建资源库对象
    self.assetsLibrary = [[ALAssetsLibrary alloc] init];
    [_assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        
        [group setAssetsFilter:[ALAssetsFilter allPhotos]];
        // 枚举器遍历相册
        [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
            if(result){
                // 如果缩略图对象存在证明有图片
                if ([UIImage imageWithCGImage:result.thumbnail]) {
                    // 创建字典对象来保存数据，flag标记是否图片被选中
                    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
                    [dic setObject:@"0" forKey:@"flag"];
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
            }
        }];
    } failureBlock:^(NSError *error) {
        //      NSLog(@"error ==> %@",error.localizedDescription);
        self.selectFinish(@{@"error": error.localizedFailureReason});
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
  self.view.backgroundColor = [UIColor whiteColor];
  // 取消scrollview的自适应
//  self.automaticallyAdjustsScrollViewInsets = NO;
  // 设置导航条颜色
    self.navigationController.navigationBarHidden = YES;
//  [self.navigationController.navigationBar setBarTintColor:[UIColor lightGrayColor]];
//  [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
  
  // 将返回按钮上的title改成汉字
//  self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:nil];
  
  // 创建取消按钮
//  UIBarButtonItem *cancelBar = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancelAction:)];
//  self.navigationItem.rightBarButtonItem = cancelBar;

  // 创建子视图
  [self creatImageListView];
  [self creatNavigationBarView];
  [self creatFinishBarView];

  // 获取数据
    [self getImageFromLibrary];
  // 默认设置当前选中0张照片
    self.currentNumOfSelection = 0;
  
  
  // 注册选择完成的消息
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectFinish:) name:ImagePickerSelectFinishNotification object:nil];
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
    
    // 设置颜色，默认状态
    finishView.backgroundColor = [UIColor lightGrayColor];
    self.numOfSelectLabel.textColor = [UIColor whiteColor];
    self.numOfSelectLabel.backgroundColor = [UIColor greenColor];
    [self.finishButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    
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
    }
    [self.view addSubview:finishView];
}


#pragma mark -NSNotificationCenter-

//  选择完成消息方法，在方法中对当前选择的个数做修改
- (void)selectFinish:(NSNotification *)notification {
    //  NSLog(@"userInfo = %@", notification.userInfo);
    if ([[[notification userInfo] objectForKey:@"flag"] boolValue]) {
        self.currentNumOfSelection++;
        [self.indexArray addObject:[[notification userInfo] objectForKey:@"index"]];
    } else {
        self.currentNumOfSelection--;
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
//    NSLog(@"indexarray = %@", self.indexArray);
    
    // 创建数组对象，用来保存返回给js的数据
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:0];
    
    // 遍历选中的位置数组，找到所有被选中的图片
    for (NSNumber *index in self.indexArray) {
        NSDictionary *content = [self.imagesArray objectAtIndex:index.integerValue];
        NSMutableDictionary *response = [NSMutableDictionary dictionaryWithCapacity:0];
        // NSLog(@"sss = %@", [content objectForKey:@"result"]);
        
        // 获取图片信息
        ALAssetRepresentation *assertRepresentation = [[content objectForKey:@"result"] defaultRepresentation];
//        NSLog(@"url = %@", assertRepresentation.url);
        
        // 获取图片信息
        UIImage *img = [UIImage imageWithCGImage:[assertRepresentation fullScreenImage]];
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
        NSData *data = UIImageJPEGRepresentation(img, [[self.options valueForKey:@"quality"] floatValue]);
        
        // 保存图片
        NSString *path = [self saveImageAtPathWithName:assertRepresentation.filename];
        if (!path) {
            // 如果图片路径不存在，返回错误信息， 错误信息在保存方法中回调
            return;
        }
        
        // 将数据写入沙盒，并获取url路径
        [data writeToFile:path atomically:YES];
        NSURL *fileURL = [NSURL fileURLWithPath:path];
        
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
    if ([self.options objectForKey:@"storageOptions"] && [[self.options objectForKey:@"storageOptions"] isKindOfClass:[NSDictionary class]]) {
        NSDictionary *storageOptions = [self.options objectForKey:@"storageOptions"];
        //获取cache的路径
        NSString *cache = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        path = [cache stringByAppendingPathComponent:fileName];
        if ([storageOptions objectForKey:@"path"]) {
            NSString *newPath = [cache stringByAppendingPathComponent:[storageOptions objectForKey:@"path"]];
            NSError *error;
            [[NSFileManager defaultManager] createDirectoryAtPath:newPath withIntermediateDirectories:YES attributes:nil error:&error];
            if (error) {
                self.selectFinish(@[@{@"error": error.localizedFailureReason}]);
                return nil;
            }
            else {
                path = [newPath stringByAppendingPathComponent:fileName];
            }
        }
    } else {
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
  // 获取缩略图
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
  
  BOOL flag;
  if ([self.contentDic[@"flag"] integerValue] == 0) {
    
    // 如果选择个数大于等于最大选择数，不能在增加
    if (self.imagePickerVC.currentNumOfSelection >= self.imagePickerVC.maxNumOfSelection) {
      return;
    }
    [self.contentDic setValue:@"1" forKey:@"flag"];
    
    flag = YES;
  } else {
    [self.contentDic setValue:@"0" forKey:@"flag"];
    
    flag = NO;
  }
  
  // 选择后修改按钮状态
  [self changeButtonImg:self.contentDic];
  
  // 发通知，通知已经对照片做了选择
    NSIndexPath *index = [self.imagePickerVC.collectionView indexPathForCell:self];
//    NSLog(@"index = %ld", index.row);
  [[NSNotificationCenter defaultCenter] postNotificationName:ImagePickerSelectFinishNotification object:nil userInfo:@{@"flag" : @(flag), @"index" : @(index.row)}];
}

// 修改button状态图标
- (void)changeButtonImg:(NSDictionary *)dic {
//    /Users/zuojianjun/Desktop/tuofeng/react-native-ios-image-picker/ios/RNImage.bundle/images/image_select.png
    
    // 从bundle中读图片资源
    NSBundle *rnBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"RNImage" ofType: @"bundle"]];
    if ([dic[@"flag"] integerValue] == 0) {
        NSString *unselectPath = [rnBundle pathForResource:@"image_unselect" ofType:@"png" inDirectory:@"images"];
        [self.selButton setBackgroundImage:[UIImage imageWithContentsOfFile:unselectPath] forState:UIControlStateNormal];
//        [self.selButton setBackgroundImage:[UIImage imageNamed:@"image_unselect.png"] forState:UIControlStateNormal];
    } else {
        NSString *selectPath = [rnBundle pathForResource:@"image_select" ofType:@"png" inDirectory:@"images"];
        [self.selButton setBackgroundImage:[UIImage imageWithContentsOfFile:selectPath] forState:UIControlStateNormal];
//        [self.selButton setBackgroundImage:[UIImage imageNamed:@"image_select.png"] forState:UIControlStateNormal];
    }
}

@end


