//
//  TFImagePickerManager.m
//  RNImagePicker
//
//  Created by 左建军 on 16/6/30.
//  Copyright © 2016年 Marc Shilling. All rights reserved.
//

#import "TFImagePickerManager.h"
#import "TFImagePickerViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/CGImageSource.h>
#import <ImageIO/CGImageProperties.h>
#import "CaptureViewController.h"

@import MobileCoreServices;

@interface TFImagePickerManager () <UINavigationControllerDelegate, UIImagePickerControllerDelegate> {
    NSString *_path;  // 拍照保存的路径
    NSDictionary *_oldExifDic; // 原始照片的exif信息
    UIImagePickerController *_picker;  // 照相
}


@property (nonatomic, copy) RCTResponseSenderBlock callback;
@property (nonatomic, strong) NSDictionary *options;

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

RCT_EXPORT_METHOD(phoneFromCamera:(NSDictionary *)options callback:(RCTResponseSenderBlock)callback) {
    self.callback = callback;
    self.options = options;
    
    
    if (([[self.options objectForKey:@"cropping"] boolValue])) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cropOKNotificationHandler:) name: @"CropOK" object: nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cropCancelNotificationHandler:) name: @"CropCancel" object: nil];
    }
    
    
    //先设定sourceType为相机，然后判断相机是否可用，不可用将直接跳出，并返回不可用
    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera;
    if (![UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
        // 照相机不能使用
        self.callback(@[@{@"denied": @YES}]);
        return;
    }
    _picker = [[UIImagePickerController alloc] init];//初始化
    _picker.delegate = self;
    if ([[self.options objectForKey:@"allowsEditing"] boolValue]) {
        _picker.allowsEditing = YES;//设置可编辑
    }
    _picker.sourceType = sourceType;
    _picker.mediaTypes = @[(NSString *)kUTTypeImage];  // 设置媒体访问类型
    
    // 获取根视图控制器
    UIViewController *controller = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    [controller presentModalViewController:_picker animated:YES];//进入照相界面
}

// 照相机选取照片
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    NSURL *imageURL = [info valueForKey:UIImagePickerControllerReferenceURL];
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    
    NSString *fileName;
    
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        NSString *tempFileName = [[NSUUID UUID] UUIDString];
        if ([[self.options objectForKey:@"imageFileType"] isEqualToString:@"png"]) {
            fileName = [tempFileName stringByAppendingString:@".png"];
        }
        else {
            fileName = [tempFileName stringByAppendingString:@".jpg"];
        }
    } else {
        NSURL *videoURL = info[UIImagePickerControllerMediaURL];
        fileName = videoURL.lastPathComponent;
    }
    
    
    // 创建图片路径
    _path = [self creatImgPathWithFileName:fileName];
    if (!_path) {
        return;  // 路径出错
    }
    
    
    
    UIImage *image;
    if ([[self.options objectForKey:@"allowsEditing"] boolValue]) {
        image = [info objectForKey:UIImagePickerControllerEditedImage];
    } else {
        image = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    
    // 照片保存到相册
    if ([[self.options objectForKey:@"saveAlbum"] boolValue]) {
        UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
    }
    
    // 获取原始图片信息
    _oldExifDic = [self getExifDataFromMediaInfo:info];
    
    // 处理图片
    image = [self fixOrientation:image]; // 旋转照片
    
    // 是否裁剪照片
    if (([[self.options objectForKey:@"cropping"] boolValue])) {
        CaptureViewController *captureView = [[CaptureViewController alloc] init];
        captureView.image = image;
        
        // 裁剪设置项
        NSDictionary *cropOptions = [self.options objectForKey:@"cropOptions"];
        if (cropOptions && [cropOptions isKindOfClass:[NSDictionary class]]) {
            captureView.cropOptions = cropOptions;
        }
        
        [picker pushViewController:captureView animated:YES];
        return;
    }
    
    // 创建返回对象
    NSMutableDictionary *response = [[NSMutableDictionary alloc] init];
    
    // 创建返回exif信息的对象
    NSMutableDictionary *exifDic = [NSMutableDictionary dictionaryWithDictionary:_oldExifDic];
    
    
    // 压缩图片
    // 按最大宽高比来压缩图片
    float maxWidth = image.size.width;
    float maxHeight = image.size.height;
    if ([self.options valueForKey:@"maxWidth"]) {
        maxWidth = [[self.options valueForKey:@"maxWidth"] floatValue];
    }
    if ([self.options valueForKey:@"maxHeight"]) {
        maxHeight = [[self.options valueForKey:@"maxHeight"] floatValue];
    }
    image = [self downscaleImageIfNecessary:image maxWidth:maxWidth maxHeight:maxHeight];
    // 按像素率来压缩
    NSData *data;
    if ([[self.options objectForKey:@"imageFileType"] isEqualToString:@"png"]) {
        data = UIImagePNGRepresentation(image);
    }
    else {
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
    
    NSString *filePath = [fileURL absoluteString];
    [response setObject:filePath forKey:@"uri"];
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
    // 照相结束 回调数据
    self.callback(@[response]);
    // 退出照相机页面
    [picker dismissViewControllerAnimated:YES completion:nil];
}

//  照相机取消
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    dispatch_async(dispatch_get_main_queue(), ^{
        [picker dismissViewControllerAnimated:YES completion:^{
            self.callback(@[@{@"didCancel": @YES}]);
            [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CropOK" object:nil];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CropCancel" object:nil];
        }];
    });
}

//  图片保存到系统相册的回调方法
-(void)image:(UIImage*)image didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo {
    if(!error){
//        NSLog(@"保存成功");
    }else{
//        NSLog(@"保存失败");
    }
}


#pragma mark-保存图片-
- (NSString *)creatImgPathWithFileName:(NSString *)fileName {
    // 默认保存tmp文件夹
    NSString *path = [[NSTemporaryDirectory()stringByStandardizingPath] stringByAppendingPathComponent:fileName];
    
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
                    NSLog(@"创建cache子目录错误: %@", error);
                    self.callback(@[@{@"error": error.localizedFailureReason}]);
                    return nil;
                }
            }
            // 拼接图片路径
            path = [newPath stringByAppendingPathComponent:fileName];
        } else {
            // 如果path不存在，直接保存到caches文件夹中
            path = [cache stringByAppendingPathComponent:fileName];
        }
    }
    return path;
}


- (void)cropCancelNotificationHandler:(NSNotification *)notification {
//    [_picker takePicture];
    [_picker dismissViewControllerAnimated:YES completion:^{
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CropOK" object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CropCancel" object:nil];
        self.callback(@[@{@"didCancel": @YES}]);
    }];
}

- (void)cropOKNotificationHandler:(NSNotification *)notification {
//    notification.object;
    UIImage *image = (UIImage *)notification.object;
    
    // 创建返回对象
    NSMutableDictionary *response = [[NSMutableDictionary alloc] init];
    
    // 创建返回exif信息的对象
    NSMutableDictionary *exifDic = [NSMutableDictionary dictionaryWithDictionary:_oldExifDic];
    
    // 按像素率来压缩
    NSData *data;
    if ([[self.options objectForKey:@"imageFileType"] isEqualToString:@"png"]) {
        data = UIImagePNGRepresentation(image);
    }
    else {
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
    
    NSString *filePath = [fileURL absoluteString];
    [response setObject:filePath forKey:@"uri"];
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
    // 照相结束 回调数据
    self.callback(@[response]);
    // 退出照相机页面
    [_picker dismissViewControllerAnimated:YES completion:^{
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CropOK" object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CropCancel" object:nil];
    }];
}


#pragma mark-Exif-

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
//  获取相机的Exif
- (NSDictionary *)getExifDataFromMediaInfo:(NSDictionary *)info {
    // 添加exif信息
    NSMutableDictionary *exifInfo = [NSMutableDictionary dictionaryWithCapacity:0];
    NSDictionary *properties = info[@"UIImagePickerControllerMediaMetadata"];
    
    if (properties) {
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

#pragma mark-图片处理-

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

// 旋转图片转成正向
- (UIImage *)fixOrientation:(UIImage *)srcImg {
    if (srcImg.imageOrientation == UIImageOrientationUp) {
        return srcImg;
    }
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    switch (srcImg.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, srcImg.size.width, srcImg.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, srcImg.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, srcImg.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }
    
    switch (srcImg.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, srcImg.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, srcImg.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }
    
    CGContextRef ctx = CGBitmapContextCreate(NULL, srcImg.size.width, srcImg.size.height, CGImageGetBitsPerComponent(srcImg.CGImage), 0, CGImageGetColorSpace(srcImg.CGImage), CGImageGetBitmapInfo(srcImg.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (srcImg.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            CGContextDrawImage(ctx, CGRectMake(0,0,srcImg.size.height,srcImg.size.width), srcImg.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,srcImg.size.width,srcImg.size.height), srcImg.CGImage);
            break;
    }
    
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
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





@end
