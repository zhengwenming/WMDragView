//
//  SceneOneViewController.m
//  WMDragView
//
//  Created by zhengwenming on 2017/8/19.
//  Copyright © 2017年 zhengwenming. All rights reserved.
//

#import "SceneOneViewController.h"
#import "Masonry.h"
#import "CustomerView.h"

@interface SceneOneViewController ()

@end

@implementation SceneOneViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = @"又回到最初的起点";
    
    
//    WMDragView *orangeView = [[WMDragView alloc] init];
//    orangeView.imageView.image = [UIImage imageNamed:@"logo1024"];
//    orangeView.backgroundColor = [UIColor orangeColor];
//    [self.view addSubview:orangeView];
//
//
//
//    [orangeView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.center.equalTo(self.view);
//        make.size.mas_equalTo(CGSizeMake(80, 80));
//    }];
//
//    orangeView.clickDragViewBlock = ^(WMDragView *dragView){
//
//
//    };
//
//
//    orangeView.endDragBlock = ^(WMDragView *dragView) {
//
//
//
//        };

    
    
    
    
    CustomerView *cv = [[CustomerView alloc] initWithFrame:CGRectMake(0, 0, 180, 80)];
    [self.view addSubview:cv];

    cv.center = self.view.center;
    
    
}



@end
