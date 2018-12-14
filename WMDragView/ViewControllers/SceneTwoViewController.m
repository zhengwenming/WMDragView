//
//  SceneTwoViewController.m
//  WMDragView
//
//  Created by zhengwenming on 2017/8/19.
//  Copyright © 2017年 zhengwenming. All rights reserved.
//

#import "SceneTwoViewController.h"
#import "WMPlayer.h"
#import "TestViewController.h"

@interface SceneTwoViewController ()
@property(nonatomic,strong)WMPlayer *dragPlayerView;
@end

@implementation SceneTwoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.dragPlayerView = [[WMPlayer alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth/1.5, (kScreenWidth/1.5)*(3.0/4.0))];
    self.dragPlayerView.URLString = @"http://static.tripbe.com/videofiles/20121214/9533522808.f4v.mp4";
    [self.view addSubview:self.dragPlayerView];
    self.dragPlayerView.closeBtn.hidden = YES;
    [self.dragPlayerView play];
    self.dragPlayerView.center = self.view.center;



    CGRect originalFrame = (CGRect){CGPointMake(self.view.center.x-80/2, self.view.center.y-80/2),CGSizeMake(80, 80)};
    
    WMDragView *orangeView = [[WMDragView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth/1.5, (kScreenWidth/1.5)*(3.0/4.0))];
    orangeView.imageView.image = [UIImage imageNamed:@"header"];
    orangeView.backgroundColor = [UIColor clearColor];
    orangeView.isKeepBounds = YES;
    [self.view addSubview:orangeView];
    
    __weak __typeof(&*self) weakSelf = self;
    orangeView.clickDragViewBlock = ^(WMDragView *dragView){

    };
    
}

@end
