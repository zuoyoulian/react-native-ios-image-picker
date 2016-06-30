# react-native-ios-image-picker  
iOS照片选取器，支持多张照片选取，并且可以大图预览照片。在缩略图列表页面和大图预览页面都可以进行照片的选择或取消选择；  
<!--## 结果演示  
![首页](http://git.tuofeng.cn/tuofeng/react-native-ios-image-picker/blob/master/pictures/1.png)  
![缩略图列表](http://git.tuofeng.cn/tuofeng/react-native-ios-image-picker/blob/master/pictures/2.png)  
![选择](http://git.tuofeng.cn/tuofeng/react-native-ios-image-picker/blob/master/pictures/3.png)  
![大图浏览](http://git.tuofeng.cn/tuofeng/react-native-ios-image-picker/blob/master/pictures/4.png)-->

## 文件夹结构
1. ios文件夹，存放的是多张图片选择的oc端代码  
2. Example文件夹，是demo示例
3. pictures文件夹，存放的是示例演示截图

## 文件介绍   

### 1、ios文件夹中文件介绍
1. RNImage.bundle --- iOS中提供的资源包管理，可以将图片、文档等资源放到bundle中  
本例中，将image_select.png、image_unselect.png、image_back.png三张图片放到该资源包中；图片可根据具体的项目需求和产品细节进行替换；  
使用时，需要将RNImage.bundle添加到主工程目录中，资源文件需要从mainBundle中读取；
2. TFImagePickerManager --- 管理对外接口的类文件  
在类中实现了两个方法：  
(1) 将oc类暴露给js使用
```
RCT_EXPORT_MODULE(js_name);
```
参数`js_name`的作用是提供给js的模块名称；  
如果不传入参数，默认将oc的类名作为js模块名使用；   
(2) 提供对外调用的接口，在js中调用
```
RCT_EXPORT_METHOD(showImagePicker:(NSDictionary *)options callback:(RCTResponseSenderBlock)callback) {
}
```
参数说明：  
(1) `options`: 是js传入的对象，用来对oc进行设置控制  
(2) `callback`: 是当选择完成之后，将结果放到dic对象中回调给js
```
// 选择完成后将数据返回
  imgPickVC.selectFinish = ^(NSDictionary *dic) {
      // 返回对象
      self.callback(@[dic]);
  };
```
3. TFImagePickerViewController --- 是用来显示缩略图列表，以及处理用户选择或取消照片的逻辑  
4. TFBigImageViewController --- 用来浏览照片的原始尺寸大图，以及用户选择照片的逻辑  
5. UIColor+hex文件 是UIColor的分类，对UIColor类进行扩展   
在分类中定义了创建color对象的方法：
```
+ (UIColor *)colorWithHexString:(NSString *)color andAlpha:(CGFloat)alpha;
```
参数说明：  
(1) `color`: 16进制RGB颜色值字符串，以`＃`或`0X`开头，截取掉`＃`或`0X`后长度必须是6；  
如果传入传入的字符串不是`＃`或`0X`开头，或截取后长度不是6，会被处理成`clearColor`;   
(2)`alpha`: 是颜色透明度值；
   
### 2、Example文件夹中文件介绍  
1. package.json 系统配置文件，创建React Native工程时默认生成，可根据需求对文件进行修改和配置
2. index.android.js 是android端启动文件
3. index.ios.js 是iOS端启动文件
4. android文件夹 是android工程目录，android开发在该目录中操作
5. ios文件夹 是iOS工程目录，iOS开发在该目录中操作
6. node_modules文件夹 是React Native的源码和依赖包，在创建项目时自动获取

## 使用说明
创建oc对象  
```
var ImagePickerManager = NativeModules.TFImagePickerManager;
```   
定义从照片库选图片的函数  
```
selectPhotoFromLibrary(){
}
```  
在函数中创建设置参数对象，传给oc使用   
```
// 设置选取照片需要的参数
const options = {
   maxNumOfSelect: 3,  // 照片最大选取数
   quality: 0.5,  // 照片压缩率，按照像素压缩
   maxWidth: 600,  // 最大尺寸宽度
   maxHeight: 600, // 最大尺寸高度 
   listNavigationBarOptions:{ // 缩略图页面，上导航条的设置项
     backgroundColor:'#000000',  // 上导航栏的背景颜色，默认为纯黑色
     alpha:0.8,  // 设置上导航视图的透明度，默认为0.8
     titleColor:'#FFFFFF'  // 设置上导航栏上的字体的颜色，默认是纯白色
   },
   listFinishBarOptions:{ // 缩略图页面，完成状态栏设置项
	  backgroundColor:'#D3D3D3', // 完成状态栏背景颜色，默认浅灰色
	  tintColor:'#008000',  //状态栏上完成按钮和文本框背景颜色， 默认纯绿色
	  titleColor:'#FFFFFF'  // 显示选择个数的文本颜色，默认纯白色
   },
   bigNavigationBarOptions:{  // 大图页面，上导航条设置项
	  backgroundColor:'#000000',  // 上导航栏的背景颜色，默认为纯黑色
	  alpha:0.5,  // 设置上导航视图的透明度，默认为0.5
   },
   bigFinishBarOptions:{  // 大图页面，完成状态栏设置项
     backgroundColor:'#000000',  // 完成状态栏背景颜色，默认为纯黑色
	  alpha:0.5,  // 设置状态栏的透明度，默认为0.5
	  tintColor:'#008000',  //状态栏上完成按钮和文本框背景颜色， 默认纯绿色
	  titleColor:'#FFFFFF'  // 显示选择个数的文本颜色，默认纯白色
   },
   storageOptions: {  // 存储的设置项
     skipBackup: true,  // 默认true表示跳过备份到iCloud和iTunes,一般应用中不包含用户的数据的文件无须备份
     path:'savePhotoPath' // 创建存储的文件夹路径，图片保存在沙盒caches下的文件夹名称
   }
};
```  
在方法中调用oc方法  
```
// 调用oc方法，将设置的参数传入，将选取后的数据回调回来
ImagePickerManager.showImagePicker(options, (response) => {
  console.log('Response = ', response);
  if(response.didCancel) {
    console.log('用户取消了图片选取');
  } else if(response.error) {
	   console.log('图片选取器错误：', response.error);
	 } else {  // 将选取的正确信息返回
      /*
      用户选择完成照片之后返回的数据格式如下所示:
      {
        numOfSelect:照片个数
        results:[
          {uri:图片地址,
           width:图片的宽度,
           height:图片高度,
           fileSize:图片的大小},
          {uri:图片地址,
           width:图片的宽度,
           height:图片高度,
           fileSize:图片的大小},
          ...
        ]
      }
      */
	  console.log('选取了：', response.numOfSelect, '图片');
	  var source;
	  for(var i=0;i<response.results.length;i++) {
	      source = response.results[i];
	      console.log('uri:', source.uri);
	  }
	   // 保存回调数据，将选择的第一张图片进行演示
	  this.setState({
	    avatarSource: response.results[0]
	  });
	}
});
```

## 参数说明  
### 传入参数options
|参数                       |类型            |描述                   |
|----------------          |:--------:|:-----------------          |
|maxNumOfSelect            |number    |照片的最大选取个数             |
|quality                   |number    |像素压缩率                    |
|maxWidth                  |number    |返回图片的最大宽度             |
|maxHeight                 |number    |返回图片的最大高度             |
|listNavigationBarOptions  |object    |缩略图列表页面上导航栏设置项     |
|listFinishBarOptions      |object    |缩略图列表页面完成状态栏设置项   |
|bigNavigationBarOptions   |object    |预览大图页面上导航设置项        |
|bigFinishBarOptions       |object    |预览大图页面完成状态栏设置项     |
|storageOptions            |object    |存储设置项                   |
#### listNavigationBarOptions
|参数              |类型       |描述                                  |
|---------------- |:--------:|:-----------------                    |
|backgroundColor  |string    |上导航条的背景颜色，默认'#000000'纯黑色    |
|titleColor       |string    |上导航条上标题和按钮字体颜色，默认'#FFFFFF'白色 |
|alpha            |number    |上导航条的透明度， 默认0.8               |
#### listFinishBarOptions
|参数              |类型       |描述                                  |
|---------------- |:--------:|:-----------------                    |
|backgroundColor  |string    |完成状态栏的背景颜色，默认'#000000'纯黑色   |
|tintColor        |string    |完成按钮文本和显示个数视图的背景颜色，默认纯绿色|
|titleColor       |string    |显示个数文本颜色，默认纯白色                |
#### bigNavigationBarOptions
|参数              |类型       |描述                                  |
|---------------- |:--------:|:-----------------                    |
|backgroundColor  |string    |浏览大图上导航栏背景颜色，默认纯黑色        |
|alpha            |number    |上导航栏的透明度，默认0.5                 |
#### bigFinishBarOptions
|参数              |类型       |描述                                  |
|---------------- |:--------:|:-----------------                    |
|backgroundColor  |string    |浏览大图页完成状态栏背景颜色，默认为纯黑色   |
|alpha            |number    |完成状态栏透明度，默认0.5                 |
|tintColor        |string    |完成按钮文本和显示个数视图的背景颜色，默认纯绿色|
| titleColor      |string    |显示个数文本颜色，默认纯白色                |
#### storageOptions
|参数           |类型       |描述                                  |
|------------|:--------:|:-----------------                    |
|skipBackup  |bool      |跳过备份到iCloud和iTunes，默认true表示跳过备份；在应用中做数据持久话时，如果非用户级数据一般无须备份|
|path        |string    |保存图片的文件夹名称，在应用中保存的照片都会存到该目录下 |

### 返回参数response
|参数              |类型       |描述                |
|---------------- |:--------:|:-----------------  |
|numOfSelect      |number    |返回选择的照片个数     |
|results          |object    |返回的信息集          |
#### results
|参数              |类型       |描述                |
|---------------- |:--------:|:-----------------  |
|uri              |string    |照片存在本地的路径     |
|width            |number    |照片宽度             |
|height           |number    |照片高度             |
|fileSize         |number    |图片大小             |

## 安装说明

1、图片资源在react-native-ios-image-picker -> ios -> RNImage.bundle中，将RNImage.bundle直接拖到主工程目录中；  
RNImage.bundle中的图片根据项目需求进行替换；  
注意：  
图片资源需要编译到mainbundle中才能被找到；  
替换时图片名称需要根bundle中的图片名一致，选中(image_select.png)，未选中(image_unselect.png)，返回(image_back.png);  
使用Images.xcassets管理图片资源是Xcode5之后提供的，但是只能放png格式的图片；  
2、在Libraries文件夹右键，选择`Add Files to ...`；  
选择ios文件夹下的`RNImagePicker.xcodeproj`，添加；  
将`libRNImagePicker.a`添加到`Build Phases`下的`Link Binary With Libraries`中；  
注意：
如果找不到`React`路径，在`RNImagePicker.xcodeproj`的`Build Setting`中找到`Header Seach Paths`，修改路径；

