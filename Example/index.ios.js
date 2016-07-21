/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 * @flow
 */

import React, { Component } from 'react';
import {
  AppRegistry,
  StyleSheet,
  Text,
  View,
  Image,
  TouchableOpacity,
  ActionSheetIOS,
  NativeModules
} from 'react-native';


// 创建oc对象
var ImagePickerManager = NativeModules.TFImagePickerManager;

class choosePhoto extends Component {

    // 用来保存回调的数据
	state = {
	    avatarSource: null
	 };
	 
	 
	 // 从照片库选图片
	 selectPhotoFromLibrary() {
	   // 设置选取照片需要的参数
	   /*  
         title: '照片选取',   // ActionSheet标题
         takePhotoButtonTitle: '拍照',  // 拍照按钮标题
         chooseFromLibraryButtonTitle: '从手机相册选取',  //相册按钮标题
        */
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
	       backgroundColor:'#FAFAFA', // 完成状态栏背景颜色，默认浅灰色
	       tintColor:'#09bb07',  //状态栏上完成按钮和文本框背景颜色， 默认纯绿色
	       titleColor:'#FFFFFF',  // 显示选择个数的文本颜色，默认纯白色
	       splitLineColor:'#bfbfbf',  // 状态栏上分割线颜色
	       splitLineHeight:1  // 分割线的高度，默认1个像素
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
       
       // 调用oc方法，将设置的参数传入，将选取后的数据回调回来
       ImagePickerManager.showImagePicker(options, (response) => {
	       console.log('Response = ', response);
	       if(response.error) {
		       console.log('图片选取错误：', response.error);	          
	       } else if(response.didCancel) {
		       console.log('用户取消了图片选取');
	       } else if(response.denied) {
		       console.log('没有设置访问照片库权限');
	       } else {  
	          // 将选取的正确信息返回
	          /*
		        用户选择完成照片之后返回的数据格式如下所示:
		        {
		          numOfSelect:照片个数
		          results:[
		            {
		              uri:图片地址,
		              width:图片的宽度,
		              height:图片高度,
		              fileSize:图片的大小
		            },
		            {
		              uri:图片地址,
		              width:图片的宽度,
		              height:图片高度,
		              fileSize:图片的大小
		            },
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
	 }
	 
	 
  // 拍照
  selectPhotoFromCamera() {
    const options = {
      quality: 0.5,  // 照片压缩率，按照像素压缩
      maxWidth: 600,  // 最大尺寸宽度
      maxHeight: 600, // 最大尺寸高度
      allowsEditing: true, // 是否允许编辑 
      saveAlbum: true,  // 是否允许保存到系统相册
      imageFileType: 'png', // 指定图片的保存本地类型
      storageOptions: {  // 存储的设置项
        skipBackup: true,  // 默认true表示跳过备份到iCloud和iTunes,一般应用中不包含用户的数据的文件无须备份
        path:'savePhotoPath' // 创建存储的文件夹路径，图片保存在沙盒caches下的文件夹名称
      }
    };
    ImagePickerManager.phoneFromCamera(options,(response) => {
	  console.log('respone', response)
	  if(response.error) {
	    console.log('图片选取错误：', response.error);	          
	  } else if(response.didCancel) {
	    console.log('用户取消了图片选取');
	  } else if(response.denied) {
	    console.log('没有设置访问照片库权限');
	  } else {
	    console.log('uri:', response.uri);
	    this.setState({
	      avatarSource: response
	    });
	  }
    })
  }
	 
   // 在js端显示选择菜单
	 showActionSheet() {
	     var cp = this; // 在回调函数中不能传this，需要临时变量 
		 ActionSheetIOS.showActionSheetWithOptions({
			 options:['拍照', '从手机相册选取', '取消'],
			 cancelButtonIndex: 3,
/* 			 destructiveButtonIndex: 0, */
		 }, function(index){
		     if(index == 0){
			     cp.selectPhotoFromCamera();
		     }
			 else if(index == 1) {
				 cp.selectPhotoFromLibrary();
			 }
		 });
	 }
	 
	 
    // 渲染视图
    render() {
    
	  return (
	      <View style={styles.container}>
	        <TouchableOpacity onPress={this.showActionSheet.bind(this)}>
	          <View style={[styles.avatar, styles.avatarContainer, {marginBottom: 20}]}>
	          { this.state.avatarSource === null ? <Text>选取照片</Text> :
	            <Image style={styles.avatar} source={this.state.avatarSource} />
	          }
	          </View>
	        </TouchableOpacity>
	      </View>
     );
  }
}


// 视图的样式表
const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
  },
  welcome: {
    fontSize: 20,
    textAlign: 'center',
    margin: 10,
  },
  instructions: {
    textAlign: 'center',
    color: '#333333',
    marginBottom: 5,
  },
  avatarContainer: {
    borderColor: '#9B9B9B',
    borderWidth: 1,
    justifyContent: 'center',
    alignItems: 'center'
  },
  avatar: {
    borderRadius: 75,
    width: 150,
    height: 150
  },
});

AppRegistry.registerComponent('Example', () => choosePhoto);
