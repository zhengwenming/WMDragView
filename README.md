# WMDragView
WMDragView致力于让任意View都可以自由移动、悬浮、拖动、拖曳。WMDragView是可以自由拖曳的view，可以悬浮移动，也可以设置内部的图片，轻量级的控件。

## 功能
- [x] 可设置拖动的范围rect
- [x] 可获得拖曳回调和点击回调
- [x] 可选择是否有黏贴边缘的动画效果
- [x] 可设置网络图片
- [x] 支持自定义view

## 注意,添加到window上的全局dragView不建议使用masonry添加约束，否则会在新的其他VC加载的时候，dragView被复位到初始化位置

demo效果图：
---
![image](https://github.com/zhengwenming/WMDragView/blob/master/WMDragView/WMDragView.gif)  应用场景1：![image](https://github.com/zhengwenming/WMDragView/blob/master/WMDragView/WMPlayer.gif) 应用场景2：![image](https://github.com/zhengwenming/WMDragView/blob/master/WMDragView/douyu.gif) 



#WMDragView：用法和API

1、把需要拖曳view的父类从原本继承UIView，改成继承WMDragView就OK了。

2、dragEnable=YES，可拖曳

   dragEnable=NO，不可拖曳
   
3、freeRect可以任意设置活动范围，默认为活动范围为父视图大小frame，

4、回调block

	点击的回调		clickDragViewBlock
	
	开始拖动的回调		beginDragBlock
	
	拖动中回调		duringDragBlock
	
	结束拖动的回调 	endDragBlock
	
5、isKeepBounds是不是又自动黏贴边界效果

 isKeepBounds = YES，自动黏贴边界，而且是最近的边界
 isKeepBounds = NO， 不会黏贴在边界，它是free(自由)状态，跟随手指到任意位置，但是也不可以拖出规定的范围

6、可以设置网络图片

7、可以自定义view加到dragView中，比如一个视频，一个自定义按钮等等。



欢迎加入微信开发技术支持群，18824905363，备注：iOS或者前端

