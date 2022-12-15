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
    
    
    WMDragView *logoView = [[WMDragView alloc] init];
    logoView.imageView.image = [UIImage imageNamed:@"logo1024"];
    [[UIApplication sharedApplication].delegate.window addSubview:logoView];



    [logoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(logoView.superview);
        make.size.mas_equalTo(CGSizeMake(80, 80));
    }];

    logoView.clickDragViewBlock = ^(WMDragView *dragView){


    };

    logoView.duringDragBlock = ^(WMDragView *dragView) {
    };

    logoView.endDragBlock = ^(WMDragView *dragView) {

    };
}
@end
