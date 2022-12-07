//
//  RootTabbarController.m
//  CopySource
//
//  Created by zhengwenming on 2017/4/9.
//  Copyright © 2017年 zhengwenming. All rights reserved.
//

#import "RootTabbarController.h"

@interface RootTabbarController ()

@end

@implementation RootTabbarController

-(void)createTabBar{
    NSURL *plistUrl = [[NSBundle mainBundle] URLForResource:@"MainUI" withExtension:@"plist"];
    NSArray *sourceArray = [NSArray arrayWithContentsOfURL:plistUrl];
    NSMutableArray *viewControllers = [NSMutableArray array];
    for (NSDictionary *dic in sourceArray) {
        BaseViewController  *aVC = (BaseViewController *) [[NSClassFromString(dic[@"vcName"]) alloc]init];
        BaseNavigationController *nav=[[BaseNavigationController alloc]initWithRootViewController:aVC];
        UITabBarItem *tabItem=[[UITabBarItem alloc]initWithTitle:dic[@"title"] image:[[UIImage imageNamed:dic[@"icon"] ] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] selectedImage:[[UIImage imageNamed:dic[@"selectIcon"]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
//        if (@available(iOS 13.0, *)) {
//            UITabBarAppearance *appearance = [UITabBarAppearance new];
//            // 设置未被选中的颜色
//            appearance.stackedLayoutAppearance.normal.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
//            // 设置被选中时的颜色
//            appearance.stackedLayoutAppearance.selected.titleTextAttributes = @{NSForegroundColorAttributeName: kTintColor};
//            tabItem.standardAppearance = appearance;
//            if (@available(iOS 13.0, *)) {
//                UITabBarItemAppearance *inlineLayoutAppearance = [[UITabBarItemAppearance  alloc] init];
//                [inlineLayoutAppearance.normal setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
//                [inlineLayoutAppearance.selected setTitleTextAttributes:@{NSForegroundColorAttributeName: kTintColor}];
//
//                UITabBarAppearance *standardAppearance = [[UITabBarAppearance alloc] init];
//                standardAppearance.stackedLayoutAppearance = inlineLayoutAppearance;
//                standardAppearance.backgroundColor = kTintColor;
//                standardAppearance.shadowImage = [UIImage new];
//                self.tabBar.standardAppearance = standardAppearance;
//                    [[UITabBar appearance] setUnselectedItemTintColor:kTintColor];
//              }
//        }
        aVC.title = dic[@"title"];
        nav.tabBarItem = tabItem;
        [viewControllers addObject:nav];
       
    }
    self.viewControllers = viewControllers;
    self.tabBar.tintColor = kTintColor;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self createTabBar];
    
}

- (BOOL)shouldAutorotate{
    BaseNavigationController *nav = (BaseNavigationController *)self.selectedViewController;
    if ([nav.visibleViewController isKindOfClass:[NSClassFromString(@"MessageViewController") class]]){
        return YES;
    }
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    BaseNavigationController *nav = (BaseNavigationController *)self.selectedViewController;
    //    topViewController = nav.lastObj
    if ([nav.visibleViewController isKindOfClass:[NSClassFromString(@"MessageViewController") class]]){
        return UIInterfaceOrientationMaskAllButUpsideDown;
    }
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    BaseNavigationController *nav = (BaseNavigationController *)self.selectedViewController;
    if ([nav.visibleViewController isKindOfClass:[NSClassFromString(@"MessageViewController") class]]){
        return UIInterfaceOrientationLandscapeLeft;
    }
    return UIInterfaceOrientationPortrait;
}


@end
