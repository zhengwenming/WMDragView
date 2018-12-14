//
//  CustomerView.m
//  WMDragView
//
//  Created by apple on 2018/9/6.
//  Copyright © 2018年 zhengwenming. All rights reserved.
//

#import "CustomerView.h"

@implementation CustomerView

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.contentViewForDrag = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 30, 40)];
        [self addSubview:self.contentViewForDrag];
        self.contentViewForDrag.backgroundColor = [UIColor yellowColor];
    }
    return self;
}
- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.contentViewForDrag = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 30, 40)];
        [self addSubview:self.contentViewForDrag];
        self.contentViewForDrag.backgroundColor = [UIColor yellowColor];
    }
    return self;
}
@end
