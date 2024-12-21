//
//  SceneOneViewController.m
//  WMDragView
//
//  Created by zhengwenming on 2017/8/19.
//  Copyright © 2017年 zhengwenming. All rights reserved.
//

#import "SceneOneViewController.h"
#import "Masonry.h"
#import "AppDelegate.h"
@interface SceneOneViewController ()

@end

@implementation SceneOneViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"全局浮窗";
    
    
    WMDragView *logoView = [[WMDragView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
    logoView.imageView.image = [UIImage imageNamed:@"logo1024"];
    [[UIApplication sharedApplication].delegate.window addSubview:logoView];
    logoView.center = logoView.superview.center;




#pragma mark !!!:  注意,添加到window上的全局dragView不建议使用masonry添加约束，否则会在新的其他VC加载的时候，dragView被复位到初始化位置。
    
//    [logoView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.center.equalTo(logoView.superview);
//        make.size.mas_equalTo(CGSizeMake(80, 80));
//    }];

    logoView.clickDragViewBlock = ^(WMDragView *dragView){


    };

    logoView.duringDragBlock = ^(WMDragView *dragView) {
    };

    logoView.endDragBlock = ^(WMDragView *dragView) {

    };
}
@end
