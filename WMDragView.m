//
//  WMDragView.m
//  WMDragView
//
//  Created by zhengwenming on 2016/12/16.
//
//

#import "WMDragView.h"

@interface WMDragView ()<UIGestureRecognizerDelegate>
/**
 内容view，命名为contentViewForDrag，因为很多其他开源的第三方的库，里面同样有contentView这个属性
 ，这里特意命名为contentViewForDrag以防止冲突
 */
@property (nonatomic,strong) UIView *contentViewForDrag;
@property (nonatomic,strong) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic,assign) CGRect oriRect;
@end

@implementation WMDragView
-(UIImageView *)imageView{
    if (_imageView==nil) {
        _imageView = [[UIImageView alloc]init];
        _imageView.userInteractionEnabled = YES;
        _imageView.clipsToBounds = YES;
        [self.contentViewForDrag addSubview:_imageView];
    }
    return _imageView;
}
-(UIButton *)button{
    if (_button==nil) {
        _button = [UIButton buttonWithType:UIButtonTypeCustom];
        _button.clipsToBounds = YES;
        _button.userInteractionEnabled = NO;
        [self.contentViewForDrag addSubview:_button];
    }
    return _button;
}
-(UIView *)contentViewForDrag{
    if (_contentViewForDrag==nil) {
        _contentViewForDrag = [[UIView alloc]init];
        _contentViewForDrag.clipsToBounds = YES;
    }
    return _contentViewForDrag;
}
- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.oriRect = frame;
        [self addSubview:self.contentViewForDrag];
        [self setUp];
    }
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)coder{
    self = [super initWithCoder:coder];
    if (self) {
        [self setUp];
    }
    return self;
}

-(void)layoutSubviews{
    [super layoutSubviews];
    if (self.freeRect.origin.x!=0||self.freeRect.origin.y!=0||self.freeRect.size.height!=0||self.freeRect.size.width!=0) {
        //设置了freeRect--活动范围
    }else{
        //没有设置freeRect--活动范围，则设置默认的活动范围为父视图的frame
        self.freeRect = (CGRect){CGPointZero,self.superview.bounds.size};
    }
    _imageView.frame = (CGRect){CGPointZero,self.bounds.size};
    _button.frame = (CGRect){CGPointZero,self.bounds.size};
    self.contentViewForDrag.frame =  (CGRect){CGPointZero,self.bounds.size};
}
-(void)setUp{
    self.dragEnable = YES;//默认可以拖曳
    self.clipsToBounds = YES;
    self.isKeepBounds = NO;
    self.backgroundColor = [UIColor lightGrayColor];
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickDragView)];
    [self addGestureRecognizer:singleTap];
    
    //添加移动手势可以拖动
    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragAction:)];
    self.panGestureRecognizer.minimumNumberOfTouches = 1;
    self.panGestureRecognizer.maximumNumberOfTouches = 1;
    self.panGestureRecognizer.delegate = self;
    [self addGestureRecognizer:self.panGestureRecognizer];
}
- (void)setIsKeepBounds:(BOOL)isKeepBounds{
    _isKeepBounds = isKeepBounds;
    if(isKeepBounds){
        [self keepBounds];
    }
}
-(void)setFreeRect:(CGRect)freeRect{
    _freeRect = freeRect;
    [self keepBounds];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    //只拦截拖动手势，单击手势不受dragEnable影响，否则关闭拖曳后将无法通过点击再打开
    if (gestureRecognizer == self.panGestureRecognizer) {
        return self.dragEnable;
    }
    return YES;
}
/**
 拖动事件
 @param pan 拖动手势
 */
-(void)dragAction:(UIPanGestureRecognizer *)pan{
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:{//开始拖动
            if (self.beginDragBlock) {
                self.beginDragBlock(self);
            }
            //注意完成移动后，将translation重置为0十分重要。否则translation每次都会叠加
            [pan setTranslation:CGPointZero inView:self];
            break;
        }
        case UIGestureRecognizerStateChanged:{//拖动中
            //计算位移 = 当前位置 - 起始位置
            if (self.duringDragBlock) {
                self.duringDragBlock(self);
            }
            CGPoint point = [pan translationInView:self];
            CGFloat dx;
            CGFloat dy;
            switch (self.dragDirection) {
                case WMDragDirectionAny:
                    dx = point.x;
                    dy = point.y;
                    break;
                case WMDragDirectionHorizontal:
                    dx = point.x;
                    dy = 0;
                    break;
                case WMDragDirectionVertical:
                    dx = 0;
                    dy = point.y;
                    break;
                default:
                    dx = point.x;
                    dy = point.y;
                    break;
            }
            
            //计算移动后的view中心点
            CGPoint newCenter = CGPointMake(self.center.x + dx, self.center.y + dy);
            //移动view
            self.center = newCenter;
            //  注意完成上述移动后，将translation重置为0十分重要。否则translation每次都会叠加
            [pan setTranslation:CGPointZero inView:self];
            break;
        }
        case UIGestureRecognizerStateEnded:{//拖动结束
            [self keepBounds];
            if (self.endDragBlock) {
                self.endDragBlock(self);
            }
            break;
        }
        default:
            break;
    }
}
//单击事件
-(void)clickDragView{
    if (self.clickDragViewBlock) {
        self.clickDragViewBlock(self);
    }
}
//黏贴边界效果
- (void)keepBounds{
    //确保布局是最新的，避免setFreeRect在view布局完成前被调用时frame不准确
    [self layoutIfNeeded];
    
    CGRect rect = self.frame;
    if (self.isKeepBounds==NO) {//没有设置黏贴边界的效果，只把超出活动范围的部分拉回边界内
        if (rect.origin.x < self.freeRect.origin.x) {
            rect.origin.x = self.freeRect.origin.x;
        } else if(self.freeRect.origin.x+self.freeRect.size.width < rect.origin.x+rect.size.width){
            rect.origin.x = self.freeRect.origin.x+self.freeRect.size.width-rect.size.width;
        }
    }else{//设置了自动粘边的效果，根据中心点位置贴左边界或右边界
        //中心点判断
        CGFloat centerX = self.freeRect.origin.x+(self.freeRect.size.width - rect.size.width)/2;
        if (rect.origin.x < centerX) {
            rect.origin.x = self.freeRect.origin.x;
        } else {
            rect.origin.x = self.freeRect.origin.x+self.freeRect.size.width-rect.size.width;
        }
    }
    
    //上下方向：两种模式都只把超出活动范围的部分拉回边界内
    if (rect.origin.y < self.freeRect.origin.y) {
        rect.origin.y = self.freeRect.origin.y;
    } else if(self.freeRect.origin.y+self.freeRect.size.height < rect.origin.y+rect.size.height){
        rect.origin.y = self.freeRect.origin.y+self.freeRect.size.height-rect.size.height;
    }
    
    if (!CGRectEqualToRect(rect, self.frame)) {
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.frame = rect;
        } completion:nil];
    }
}
@end
