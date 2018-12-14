//
//  PRPostArticleVc.m
//  ProCloser
//
//  Created by xzming on 2017/12/22.
//  Copyright © 2017年 HZMC. All rights reserved.
//

#import "PRPostArticleVc.h"
#import "PRCollectHeaderView.h"
#import "PRContentTextView.h"
#import "PRToolBarInputView.h"
#import "PREmojiView.h"
#import "PRImagePickerVc.h"
#import "PRContentMediaView.h"
#import "PRArticlePreviewVc.h"
#import "PRImagePreviewVc.h"
#import "PRArticleEditCell.h"
#import "PreViewSectionHeader.h"
#import "PRAlertView.h"

DefineCellID(PRArticleEditCell_re_id, @"PRArticleEditCell")

@interface PRPostArticleVc ()<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextViewDelegate, YYTextKeyboardObserver>

@property(nonatomic, strong)UITextView *titleView;
@property(nonatomic, strong)UIView *contentView;

@property(nonatomic, strong)UICollectionViewFlowLayout *layout;
@property(nonatomic, strong)UICollectionView *containerView;
@property(nonatomic, strong)PRArticleHeaderView *headerView;

@property (nonatomic, strong)PRContentTextView *editingView;
@property (nonatomic) YYTextKeyboardTransition keyBoardTrans;
@property (nonatomic, strong)PRToolBarInputView *toolInputView;
@property (nonatomic, strong)PREmojiView *emojiView;

@property (nonatomic, assign)BOOL bShowEmoji;

@property (nonatomic, assign)BOOL bEditDeleting;
@property (nonatomic, assign)BOOL bEditAdding;

@property (nonatomic, assign)BOOL bDraftLoaded;
@property (nonatomic, assign)BOOL bDraftEndLoaded;
@property (nonatomic, assign)BOOL bDiscussTextLoad;
@property (nonatomic, strong) UIImageView *bgImgV;
/** 记录标题是否超出30字  */
@property (nonatomic, assign) BOOL beyondLimitWord;
/**  sectionHeader */
@property (nonatomic, strong) PreViewSectionHeader *sectionHeader;
/**  删除模式下 标记是否显示勾选按钮 */
@property (nonatomic, assign) BOOL bSelectMode;
/**  删除模式下 选中的数据源 */
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *pickedMsgs;
/** 长图文模式下 底部下一步按钮  */
@property (nonatomic, strong) UIButton *nextButton;
/**  删除、确定功能按钮 */
@property (nonatomic, strong) UIButton *functionBtn;
/**  取消按钮 */
@property (nonatomic, strong) UIButton *cancelBtn;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *discussMutableMsgs;

/**  排序模式下 标记是否显示排序 */
@property (nonatomic, assign) BOOL bSortSelectMode;
/** 进行删除操作后再调序 保存现场的数据源  */
@property (nonatomic, strong) NSArray *tempArray;
/** 是否是神议论  */
@property (nonatomic, assign) BOOL isGodDiscuss;
/** 底部输入框  */
@property (nonatomic, strong) PRArticleFooterView *footerView;

@property (nonatomic, assign) BOOL needRemoveBottomEditView;

@end

@implementation PRPostArticleVc

- (void)viewDidLoad {
    self.disablePan = YES;
    [super viewDidLoad];
    
    if (!_draftData) {
        
        self.isGodDiscuss = _discussMsgs.count > 0;
        
        [PDCommonUtil showTopCommonTip:[PDCommonUtil getStringWith:@"p_show_eidt_discuss_tip"] At:self.navigationController.view];
    }else{
        _discussMsgs = _draftData.discussMsgs.mutableCopy;
        _postGroupID = _draftData.groupID;
        _postColumnID = _draftData.columnID;
        _releaseFeedID = _draftData.release_subjectid;
        self.isGodDiscuss = _draftData.isGodDiscuss;
    }
    
    if (self.isGodDiscuss) {
        self.naviTitle = [PDCommonUtil getStringWith:@"p_edit_discuss"];
        [self.discussMutableMsgs addObjectsFromArray: self.discussMsgs];
    }else{
        self.naviTitle = [PDCommonUtil getStringWith:@"p_edit_article"];
    }
    
    [self.navibar setRightBtn:[PDCommonUtil getStringWith:@"p_preview"] action:@selector(previewArticle) at:self];
    self.navibar.rightBtn.titleLabel.font = [PDCommonUtil commonRegularFont:16];
    self.needRemoveBottomEditView = NO;
    
    [self configBottomBar];
    
    [self.view addSubview:self.containerView];
    [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.commonBottomBar.mas_top);
        make.top.equalTo(self.navibar.mas_bottom);
    }];
    
    [self setupInputView];
    
    _tempArray = @[];
    _pickedMsgs = [NSMutableArray array];
    
    [[YYTextKeyboardManager defaultManager] addObserver:self];
    
    [self configSectionHeaderActions];
}


/**  设置sectionHeader上功能按钮 */
-(void)configSectionHeaderActions{
    W_S
    /**  删除 */
    self.sectionHeader.deleteBlock = ^{
        weakSelf.bSelectMode = YES;
        weakSelf.pickedMsgs = [NSMutableArray array];
        [weakSelf showBottomToolBar:YES];
        weakSelf.nextButton.hidden = YES;
        [weakSelf reloadSpecialItemAtIndexPaths];
    };
    /**  排序 */
    __block BOOL bSortSelectMode = NO;
    self.sectionHeader.sortBlock = ^{
        if (weakSelf.discussMutableMsgs.count == 1) {
            [PDCommonUtil showCommonTip:[PDCommonUtil getStringWith:@"p_don_not_need_to_resort_tip"] At:weakSelf.view] ;
            [weakSelf.sectionHeader configButtonsEnable];
            return;
        }
        bSortSelectMode = YES;
        weakSelf.bSortSelectMode = bSortSelectMode;
        [weakSelf showBottomToolBar:NO];
        weakSelf.nextButton.hidden = YES;
        [weakSelf reloadSpecialItemAtIndexPaths];
    };
}

/**  显示底部工具条 */
-(void)showBottomToolBar:(BOOL)isDeleteStyle{
    
    [self.commonBottomBar removeFromSuperview];
    
    [self setCommonBottomBar];
    
    [self.commonBottomBar mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.bottom.mas_equalTo(self.mas_bottomLayoutGuideBottom);
        make.top.equalTo(self.mas_bottomLayoutGuideTop).offset(-kBottomBarPureHeight);
    }];
    
    [self.commonBottomBar addSubview:self.cancelBtn];
    [self.commonBottomBar addSubview:self.functionBtn];
    
    [self.cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.commonBottomBar);
        make.left.equalTo(self.commonBottomBar.mas_left).offset(20);
        make.size.mas_equalTo(CGSizeMake(82, 34));
    }];
    
    [self.functionBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.commonBottomBar);
        make.right.equalTo(self.commonBottomBar.mas_right).offset(-20);
        make.size.mas_equalTo(CGSizeMake(82, 34));
    }];
    
    self.cancelBtn.hidden = NO;
    self.functionBtn.hidden = NO;
    
    [_functionBtn removeAllTargets];
    
    if (isDeleteStyle) {
        [_functionBtn setTitle:[PDCommonUtil getStringWith:@"p_delete"] forState:UIControlStateNormal];
        [_functionBtn addTarget:self action:@selector(functionTapAction) forControlEvents:UIControlEventTouchUpInside];
        _functionBtn.enabled = NO;
    }else{
        [_functionBtn setTitle:[PDCommonUtil getStringWith:@"p_confirm"] forState:UIControlStateNormal];
        [_functionBtn addTarget:self action:@selector(showSortFunction) forControlEvents:UIControlEventTouchUpInside];
        _functionBtn.enabled = YES;
    }
    
    [self.containerView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.navibar.mas_bottom);
        make.bottom.equalTo(self.commonBottomBar.mas_top);
    }];
}

- (void)configBottomBar{
    [self setCommonBottomBar];
    
    [self.commonBottomBar addSubview:self.nextButton];
    [self.nextButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.commonBottomBar);
    }];
}

/**  底部删除 */
-(void)functionTapAction{
    
    if (_pickedMsgs.count == _discussMutableMsgs.count) {
        W_S
        /** 全部删除的时候弹框确认  */
        PRAlertView *alertView = [[PRAlertView alloc] initWithMessage:[PDCommonUtil getStringWith:@"p_discuss_no_data_hint"] showSingleBtn:NO cancelButtonTitle:[PDCommonUtil getStringWith:@"p_cancel"] otherButtonTitles:[PDCommonUtil getStringWith:@"p_confirm"]];
        
        alertView.selectConfirmBlock = ^(NSString *resultStr) {
            [weakSelf bottomDeleteAction];
        };
        
        [alertView showAlert];
    }else{
        [self bottomDeleteAction];
    }
}

-(void)bottomDeleteAction{
    [_discussMutableMsgs removeObjectsInArray:_pickedMsgs];
    [_pickedMsgs removeAllObjects];
    self.functionBtn.enabled = _pickedMsgs.count > 0;
    [self reloadSpecialItemAtIndexPaths];
    _tempArray = _discussMutableMsgs.copy;
    if (_discussMutableMsgs.count == 0) {
        /**  数据删除完了  就移除底部工具条 */
        self.sectionHeader.hidden = YES;
        self.needRemoveBottomEditView = [self endContentViewIsEmpty] ? YES : NO;
        [self resetComponents];
    }
}

/**  底部确定 */
-(void)showSortFunction{
    [self resetComponents];
}

/**  底部取消 */
-(void)cancelTapAction{
    if (self.discussMsgs.count > 0 && _bSortSelectMode) {
        if (self.discussMsgs.count == self.discussMutableMsgs.count) {
            /** 没有进行过删除操作  */
            self.discussMutableMsgs = [NSMutableArray arrayWithArray:self.discussMsgs];
        }else{
            /** 进行过删除操作 用最后一次删除操作的数组 */
            self.discussMutableMsgs = [NSMutableArray arrayWithArray:self.tempArray];
        }
    }
    [self resetComponents];
}

-(void)resetComponents{
    /**  重置删除、排序按钮 */
    [self.sectionHeader configButtonsEnable];
    /**  重置删除、排序标记状态 */
    self.bSelectMode = NO;
    self.bSortSelectMode = NO;
    /**  重置取消、功能按钮 */
    self.cancelBtn.hidden = YES;
    self.functionBtn.hidden = YES;
    self.nextButton.hidden = NO;
    [self reloadSpecialItemAtIndexPaths];
}

-(void)reloadSpecialItemAtIndexPaths{
    [self.containerView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathWithIndex:1]]];
    if (_footerView) {
        _footerView.footerEditView.showPlaceHolder = [self endContentViewIsEmpty];
    }
}

/**  删除模式下 处理消息点击 */
-(void)handleChooseMessage:(NSDictionary *)msg{
    
    PRArticleEditCell *cell = (PRArticleEditCell *)[_containerView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:[_discussMutableMsgs indexOfObject:msg] inSection:1]];

    if([_pickedMsgs containsObject:msg]){
        /**  反选 */
        [_pickedMsgs removeObject:msg];
        [cell setMessageChoosed:NO];
    }else{
        [_pickedMsgs addObject:msg];
        [cell setMessageChoosed:YES];
    }
    self.functionBtn.enabled = _pickedMsgs.count > 0;
}


-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if (_draftData) {
//        [self loadDraftData];
    }else{
        if (!_bDiscussTextLoad) {
            _bDiscussTextLoad = YES;
            if (self.isGodDiscuss) {
                [self textViewDidChange:_titleView];
                PRContentTextView *view = [_contentView.subviews firstObject];
                _editingView = view;
                [self textViewDidChange:view];
                [_editingView resignFirstResponder];
            }
        }
    }
}

/** 加载header 的草稿  */
-(void)loadDraftData{
    if (!_draftData) {
        return;
    }
    if(_bDraftLoaded)
        return;
    _bDraftLoaded = YES;
    
    [_headerView updateChangeCoverStyle];
    
    [_bgImgV setContentMode:UIViewContentModeScaleToFill];
    _bgImgV.image = _draftData.articleBannerImg;
    
    if (_draftData.postTitle.length > 0) {
        _titleView.text = _draftData.postTitle;
    }
    [self textViewDidChange:_titleView];
    
    [self refineDraftData:YES];
    
}

/** 加载footer 的草稿  */
-(void)loadEndDraftData{
    
    if (!_draftData) {
        return;
    }
    
    if(_bDraftEndLoaded){
        return;
    }
    _bDraftEndLoaded = YES;

    [self refineDraftData:NO];
    
}

/** 组装草稿数据  */
-(void)refineDraftData:(BOOL)isHeadDraft{
    
    __block UIView *preview = nil;
    W_S
    [isHeadDraft ? _draftData.articleParagraphs : _draftData.articleEndParagraphs  enumerateObjectsUsingBlock:^(PRArticleParagraph * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @autoreleasepool{
            //first must be text or ""
            if (obj.paragraphType == kParagraphText) {
                if (idx == 0) {
                    PRContentTextView *view = [isHeadDraft ? weakSelf.contentView.subviews : weakSelf.footerView.footerContentView.subviews firstObject];
                    view.text = obj.text;
                    preview = view;
                    weakSelf.editingView = view;
                    [weakSelf textViewDidChange:view];
                    
                }else{
                    PRContentTextView *lineView = [PRContentTextView new];
                    lineView.text = obj.text;
                    
                    [weakSelf addNewLineView:lineView from:preview fromHead:isHeadDraft ? YES : NO];
                    preview = lineView;
                    weakSelf.editingView = lineView;
                }
                
            }else if (obj.paragraphType == kParagraphImage){
                PRContentMediaView *mediaView = [[PRContentMediaView alloc] initWithImage:obj.image];
                mediaView.image = obj.image;
                mediaView.localAssetId = obj.localAssetId;
                mediaView.mediaType = obj.mediaType;
                [weakSelf insertMediaView:mediaView];
                
                preview = mediaView;
                
            }else if (obj.paragraphType == kParagraphVideo){
                
                PRContentMediaView *mediaView = [[PRContentMediaView alloc] initWithVideoPath:obj.videoInfo[kVideoPathKey] thumb:obj.videoInfo[kVideoThumbKey]];
                mediaView.videoInfo = obj.videoInfo;
                
                [weakSelf insertMediaView:mediaView];
                
                preview = mediaView;
                
            }
        }
    }];
    
    [_editingView resignFirstResponder];
}

-(void)setupInputView{
    
    UIView *inputContainer = [UIView new];//add this to fix input view animation flash by self.view
    
    inputContainer.backgroundColor = [UIColor clearColor];
    [self.view addSubview:inputContainer];
    CGFloat height = [YYTextKeyboardManager defaultManager].keyboardFrame.size.height + kToolBarInputHeight;
    [inputContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.view.mas_bottom).offset(-height);
        make.height.mas_equalTo(height);
    }];
    inputContainer.hidden = YES;

    _toolInputView = [PRToolBarInputView new];
    _toolInputView.backgroundColor = [PDCommonUtil commonBackgroundColor];
    [inputContainer addSubview:_toolInputView];
    [_toolInputView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(inputContainer);
        make.top.equalTo(inputContainer.mas_bottom);
        make.height.mas_equalTo(kToolBarInputHeight);
    }];
    
    [_toolInputView.emojiBtn setImage:[UIImage imageNamed:@"ic_insert_media"] forState:UIControlStateNormal];
    [_toolInputView.emojiBtn setTitle:PRLocalizedString(p_insert_media_content) forState:UIControlStateNormal];
    [_toolInputView.emojiBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, 8, 0, -8)];
    [_toolInputView.emojiBtn addTarget:self action:@selector(pickMediaView:) forControlEvents:UIControlEventTouchUpInside];
    _toolInputView.imageBtn.hidden = YES;
    _toolInputView.videoBtn.hidden = YES;

}

-(void)pickMediaView:(id)snd{
    [self hideEmojiView];

    
    PRImagePickerVc *pvc = [PRImagePickerVc new];
    pvc.pickMode = kPickType_ImageOrVideo;
    pvc.bEnableShoot = YES;
    
    __weak PRImagePickerVc *weakPvc = pvc;
    __weak PRPostArticleVc *ws = self;
    
    [pvc setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets, BOOL isSelectOriginalPhoto) {
        photos = [photos reverseObjectEnumerator].allObjects;
        [photos enumerateObjectsUsingBlock:^(UIImage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            @autoreleasepool{
                [ws insertImageAttach:obj model:assets.reverseObjectEnumerator.allObjects[idx]];
            }
        }];
        
        [weakPvc dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [pvc setDidFinishPickingVideoHandle:^(id duration, UIImage *thumbImage, NSString *videoPath, PHAsset *asset, BOOL isPrivate, NSError *error) {
        NSDictionary *info = @{
                               kVideoDuration : duration,
                               kPrivateVideo : @(isPrivate),
                               kPrivateVideoAsset : asset?:[NSNull null],
                               kPrivateVideoAssetID : asset ? asset.localIdentifier : [NSNull null],
                               kVideoPathKey : videoPath,
                               kVideoThumbKey :thumbImage,
                               };
        
        [ws insertVideoAttach:info];
        
        [weakPvc dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [self presentViewController:pvc animated:YES completion:nil];
}

/*
 editingView (tap to insert image and one more line)
 >>imageview
 >>newTextView
 
 */
-(void)insertImageAttach:(UIImage *)image model:(PHAsset *)model{
    PRContentMediaView *mediaView = [[PRContentMediaView alloc] initWithImage:image];
    mediaView.image = image;
    mediaView.localAssetId = [model localIdentifier];
    
    if ([[[model valueForKey:@"filename"] uppercaseString] hasSuffix:@"GIF"]) {
        mediaView.mediaType = TZAssetModelMediaTypePhotoGif;
    }else{
        mediaView.mediaType = TZAssetModelMediaTypePhoto;
    }
    
    [self insertMediaView:mediaView];
}


-(void)insertVideoAttach:(NSDictionary *)videoInfo{
    //TODO: optimize vinfo
    [self doInsertVideo:videoInfo];
}

-(void)doInsertVideo:(NSDictionary *)videoInfo{
    
    PRContentMediaView *mediaView = [[PRContentMediaView alloc] initWithVideoPath:videoInfo[kVideoPathKey] thumb:videoInfo[kVideoThumbKey]];
    mediaView.videoInfo = videoInfo;
    
    [self insertMediaView:mediaView];
}

-(void)deleteVideo:(NSDictionary *)vinfo{
    if (!vinfo.isPrivateAsset) {
        NSError *err = nil;
        BOOL ret = [[NSFileManager defaultManager] removeItemAtPath:vinfo.videoPath error:&err];
        NSLog(@"clear ret:%@", @(ret));
        
    }
}

-(void)insertMediaView:(PRContentMediaView *)mediaView{
    __weak PRPostArticleVc *ws = self;
    [mediaView setDeleteBlock:^(PRContentMediaView *__weak mview) {
        if (ws.bShowEmoji) {
            [ws hideEmojiView];
        }
        //删除长图文附件
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:[PDCommonUtil getStringWith:@"p_delete_attach_note"] preferredStyle:UIAlertControllerStyleActionSheet];
        
        [alert addAction:[UIAlertAction actionWithTitle:[PDCommonUtil getStringWith:@"p_delete"] style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            if(mview.mType == kMedia_Video){
                [ws deleteVideo:mview.videoInfo];
            }
            [ws deleteAttachView:mview];

        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:[PDCommonUtil getStringWith:@"p_cancel"] style:UIAlertActionStyleCancel handler:nil]];
        
        [ws presentViewController:alert animated:YES completion:nil];
        
    }];

    
    NSArray *contentSubViews = ![self isFooterEditView] ? self.contentView.subviews : self.footerView.footerContentView.subviews;
    NSUInteger index = [contentSubViews indexOfObject:_editingView];
    BOOL bshouldAddNewTextV = YES;
    UIView *nextView = nil;
    if (contentSubViews.count > index + 1) {
        nextView = contentSubViews[index+1] ;
        if([nextView isKindOfClass:PRContentTextView.class]){
            bshouldAddNewTextV = NO;
        }
    }
    
    [self addNewLineView:mediaView from:_editingView fromHead:![self isFooterEditView]];
    if (bshouldAddNewTextV) {
        PRContentTextView *lineV = [PRContentTextView new];
        lineV.text = @" ";
        [self addNewLineView:lineV from:mediaView fromHead:![self isFooterEditView]];
        [lineV setSelectedRange:NSMakeRange(0, 0)];

    }
}

-(void)dealloc{
    [[YYTextKeyboardManager defaultManager] removeObserver:self];
}

-(void)backAction:(id)sender{
    if (sender) {
        [self showSaveAlert];
    }else{
        [super backAction:sender];
    }
}

/** 是否存在内容  */
-(BOOL)isContentAvailable{
    if (!_bgImgV.image
        ||
        _titleView.text.length == 0
        ||
        [self contentIsEmpty]
        ) {
        return NO;
    }
    
    return YES;
}

-(BOOL)canSaveDraft{
    if (_bgImgV.image && _titleView.text.length > 0) {
        return YES;
    }
    if (![self contentIsEmpty]) {
        return YES;
    }
    return NO;
}

-(BOOL)contentIsEmpty{
    if (_contentView.subviews.count == 1) {
        id obj = _contentView.subviews.firstObject;
        if ([obj isKindOfClass:[PRContentTextView class]]) {
            PRContentTextView *textView = obj;
            if (textView.text.length == 0) {
                return YES;
            }
        }
    }
    return NO;
}

-(BOOL)endContentViewIsEmpty{
    if (_footerView.footerContentView.subviews.count == 1) {
        id obj = _footerView.footerContentView.subviews.firstObject;
        if ([obj isKindOfClass:[PRContentTextView class]]) {
            PRContentTextView *textView = obj;
            if (textView.text.length == 0) {
                return YES;
            }
        }
    }
    return NO;
}

#pragma mark -- 退出时检查 是否有图片、标题、内容
-(void)showSaveAlert{
    if (![self canSaveDraft]) {
        [self backAction:nil];
        
    }
//    else{
//        //auto save
//        [self saveDraft];
//
//    }
//    return;
    
    //**************************** ActionSheet 保存、不保存、取消 ****************************
    W_S
    UIAlertController *alert = [PDCommonUtil alertSheetWith:nil title:nil
                                                    actions:@[
                                                              PRLocalizedString(p_save_draft),
                                                              PRLocalizedString(p_no_save)
                                                              ]
                                                   complete:^(UIAlertAction *action) {
                                                       
                                                       if ([action.title isEqualToString:PRLocalizedString(p_save_draft)]) {
                                                           [weakSelf saveDraft];
                                                           
                                                       }else if ([action.title isEqualToString:PRLocalizedString(p_no_save)]){
                                                           [weakSelf backAction:nil];
                                                       }
                                                   }];
    
    
    [self presentViewController:alert animated:YES completion:nil];
    
}

#pragma mark - YYTextKeyboardObserver
-(void)keyboardChangedWithTransition:(YYTextKeyboardTransition)transition{
    
    _keyBoardTrans = transition;
    
    [self.view layoutIfNeeded];
    
    CGFloat height = [YYTextKeyboardManager defaultManager].keyboardFrame.size.height + kToolBarInputHeight;
    
    if(transition.toVisible){
        _bShowEmoji = NO;
    }
    
    if (_bShowEmoji) {
        height = kEmojiViewHeight + kToolBarInputHeight;
    }
    
    [_toolInputView.superview mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_bottom).offset(-height);
        make.height.mas_equalTo(height);
    }];
    if(transition.toVisible){
        _toolInputView.superview.hidden = NO;
        if (_titleView.isFirstResponder) {
            _toolInputView.superview.hidden = YES;
        }
        [_toolInputView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.toolInputView.superview.mas_bottom).offset(-height);
        }];
        [UIView animateWithDuration:transition.animationDuration animations:^{
            [self.toolInputView.superview layoutIfNeeded];
        }];
    }else{
        if (!_bShowEmoji) {
            _toolInputView.superview.hidden = YES;
            [_toolInputView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.toolInputView.superview.mas_bottom);
            }];
            
        }else{
            [_toolInputView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(self.toolInputView.superview.mas_bottom).offset(-height);
            }];
            [self adjustContainer];
        }
    }
}

#pragma mark - Scrollview
-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
}
-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    [self hideEmojiView];
}

-(void)hideEmojiView{
    [_editingView resignFirstResponder];

    if (_bShowEmoji) {
        [_toolInputView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.toolInputView.superview.mas_bottom);
        }];
        [UIView animateWithDuration:.25 animations:^{
            [self.toolInputView.superview layoutIfNeeded];
        } completion:^(BOOL finished) {
            self.toolInputView.superview.hidden = YES;

        }];
        _bShowEmoji = NO;
    }
}

/** 判断是上方编辑 还是下方编辑  */
-(BOOL)isFooterEditView{
    return [_editingView isDescendantOfView:_footerView.footerContentView];
}

#pragma mark - UITextViewDelegate

-(void)textViewDidBeginEditing:(UITextView *)textView{

    _editingView = (PRContentTextView *)textView;
    
    if (textView == _titleView) {
        _toolInputView.superview.hidden = YES;
    }else{
        _toolInputView.superview.hidden = NO;
    }
    if (!_bEditDeleting && !_bEditAdding) {
        [self adjustContainer];
    }
    
}

-(void)adjustContainer{
    
    if (_keyBoardTrans.toVisible) {
        CGPoint pt = [_editingView convertPoint:CGPointMake(0, 0 ) toView:self.view];
        NSLog(@"pt: %@, oldoffset: %@", @(pt), @(_containerView.contentOffset));
        CGFloat offset = _containerView.contentOffset.y + pt.y + [_editingView  textHeight] - (_keyBoardTrans.toFrame.origin.y - (_toolInputView.superview.hidden?0:kToolBarInputHeight));
        NSLog(@"newoffset: %@", @(offset));
        if (offset > 0) {
            [_containerView setContentOffset:CGPointMake(0, offset) animated:NO];//fix scroll view flash bug, animate to NO.
        }
    }else{
        if (_bShowEmoji) {
            CGPoint pt = [_editingView convertPoint:CGPointMake(0, 0 ) toView:self.view];
            CGFloat offset = _containerView.contentOffset.y + pt.y + [_editingView textHeight] -
            (kScreenHeight - kEmojiViewHeight - kToolBarInputHeight);
            if(offset > 0)
                [_containerView setContentOffset:CGPointMake(0, offset) animated:YES];
        }
    }
}

-(CGFloat)subviewHeight:(UIView *)subview{
    CGFloat height = 0;
    if ([subview isKindOfClass:[PRContentTextView class]]) {
        height = MAX(kTitleSingleH, [(PRContentTextView *)subview textHeight]);
    }else if ([subview isKindOfClass:[PRContentMediaView class]]){
        height = [(PRContentMediaView *)subview mediaViewHeight];
    }
    return height;
}


-(void)addNewLineView:(UIView *)tv from:(UIView *)fromView fromHead:(BOOL)fromHead{
    
    NSArray *cViewSubs = fromHead ? _contentView.subviews : self.footerView.footerContentView.subviews;
    NSUInteger index = [cViewSubs indexOfObject:fromView];
    UIView *nextV;
    
    if (cViewSubs.count > index+1) {
        nextV = [cViewSubs objectAtIndex:index+1];
    }
    
    //locate textView index
    [(fromHead ? _contentView : self.footerView.footerContentView) insertSubview:tv atIndex:index+1];
    if (index == 0) {
        [(PRContentTextView *)fromView setShowPlaceHolder:NO];
    }
    
    CGFloat height = [self subviewHeight:tv];
    
    [tv mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo((fromHead ? self.contentView : self.footerView.footerContentView));
        make.top.equalTo(fromView.mas_bottom);
        make.height.mas_equalTo(height);
    }];
    
    if (nextV) {
        [nextV mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo((fromHead ? self.contentView : self.footerView.footerContentView));
            make.top.equalTo(tv.mas_bottom);
            make.height.mas_equalTo([self subviewHeight:nextV]);
        }];
    }
    
    if ([tv isKindOfClass:[PRContentTextView class]]) {
        _bEditAdding = YES;
        ((PRContentTextView*)tv).delegate = self;
        [self textViewDidChange:(PRContentTextView*)tv];
        height = [(PRContentTextView*)tv textHeight];
        
        if (!tv.isFirstResponder) {
            [tv becomeFirstResponder];
        }
        _bEditAdding = NO;
    }else{
        if (fromView.isFirstResponder) {
            [fromView resignFirstResponder];
        }
    }
    
    if (![self isFooterEditView]) {
        [_headerView updateContentViewH];
    }else{
        [_footerView footerUpdateContentViewH];
    }
    
    [_layout invalidateLayout];
    
    CGFloat fromH = [self subviewHeight:fromView];
    
    CGPoint pt = [fromView convertPoint:CGPointMake(0, 0 ) toView:self.view];
    CGFloat offset = _containerView.contentOffset.y + pt.y + fromH + height - (_keyBoardTrans.toFrame.origin.y - kToolBarInputHeight);
    if (_keyBoardTrans.toVisible && offset > 0) {
        [self.containerView setContentOffset:CGPointMake(0, offset) animated:NO];
    }
    
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range
 replacementText:(NSString *)atext {
    if (textView == _titleView) {
        return YES;
    }
    
    if ([atext isEqualToString:@"\n"]) {//TODO refine startwith "\n"...
        NSString *substr=@"";
        if (range.location + 1 <= textView.text.length) {
            substr = [textView.text substringFromIndex:range.location];
            
            NSString *remain = [textView.text substringToIndex:range.location];
            
            textView.text = remain;
            _bEditAdding = YES;
            [self textViewDidChange:textView];
            _bEditAdding = NO;
        }
        // add new line
        
        PRContentTextView *tv = [PRContentTextView new];
        if ([substr isNotBlank]) {
            tv.text = substr;
        }else{
            tv.text = @" ";
        }
        [self addNewLineView:tv from:textView fromHead:![self isFooterEditView]];
        [tv setSelectedRange:NSMakeRange(0, 0)];
        
        return NO;
        
    } else if (![atext length] && range.location == 0 && range.length == 0) {
        //delete
        NSUInteger index = [(![self isFooterEditView] ? _contentView.subviews : self.footerView.footerContentView.subviews) indexOfObject:textView];
        if (index > 0) {
            UIView *preView = [(![self isFooterEditView] ? _contentView.subviews : self.footerView.footerContentView.subviews) objectAtIndex:index-1];
            if ([preView isKindOfClass:[PRContentTextView class]]) {
                NSUInteger oriLen = [(PRContentTextView *)preView text].length;
                ((PRContentTextView *)preView).text = [[(PRContentTextView *)preView text] stringByAppendingString:[textView.text substringFromIndex:0]];
                [(PRContentTextView *)preView setSelectedRange:NSMakeRange(oriLen, 0)];

            }else{
                return YES;
            }
            UIView *nextView;
            if (index + 1 < (![self isFooterEditView] ? _contentView.subviews : self.footerView.footerContentView.subviews).count) {
                nextView = [(![self isFooterEditView] ? _contentView.subviews : self.footerView.footerContentView.subviews) objectAtIndex:index+1];
            }
            
            [nextView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(preView.mas_bottom);
            }];
            
            _bEditDeleting = YES;
            [preView becomeFirstResponder];

            [textView removeFromSuperview];
            
            if ([preView isKindOfClass:[PRContentTextView class]]) {
                [self textViewDidChange:(PRContentTextView*)preView];
            }
            
            if (![self isFooterEditView]) {
                [_headerView updateContentViewH];
            }else{
                [_footerView footerUpdateContentViewH];
            }
            

            if ((![self isFooterEditView] ? _contentView.subviews : self.footerView.footerContentView.subviews).count == 1) {
                if (((PRContentTextView *)preView).text.length == 0) {
                    ((PRContentTextView *)preView).showPlaceHolder = YES;
                }
            }
            _bEditDeleting = NO;

            [_layout invalidateLayout];
            
            [self adjustContainer];
        }
        
        return NO;
    }
    
    return YES;
       
}

#pragma mark -- deleteAttachView

-(void)deleteAttachView:(UIView *)subView{
    /** 判断view 是否是另外一个view的 subview  */
    BOOL isPartOfContentView = [subView isDescendantOfView:_contentView];
    
    NSUInteger index = [(isPartOfContentView ? _contentView.subviews : _footerView.footerContentView.subviews) indexOfObject:subView];
    
    UIView *nextView;
    if (index + 1 < (isPartOfContentView ? _contentView.subviews : _footerView.footerContentView.subviews).count) {
        nextView = [(isPartOfContentView ? _contentView.subviews : _footerView.footerContentView.subviews) objectAtIndex:index+1];
    }
    
    UIView *preView = [(isPartOfContentView ? _contentView.subviews : _footerView.footerContentView.subviews) objectAtIndex:index-1];
    
    [nextView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(preView.mas_bottom);
    }];
    
    [subView removeFromSuperview];
    
    if (isPartOfContentView) {
        [_headerView updateContentViewH];
    }else{
        [_footerView footerUpdateContentViewH];
    }
    
    [_layout invalidateLayout];
    
}

#pragma mark -- UITextView Delegate
-(void)textViewDidChange:(UITextView *)textView{
    
    /** 标题限制只能输入30字  */
    if (textView == [_headerView titleView]){
        
        BOOL needShow = [PDCommonUtil observeTextInputLength:textView limitNum:30];
        /** 显示超出限制的tip  */
        [_headerView needShowWordLimitTip:needShow];
        
        _beyondLimitWord = needShow;

    }
    
    CGFloat hpadding = 10;
   
    CGSize size = [textView.text sizeForFont:textView.font size:CGSizeMake(kScreenWidth-40-hpadding, HUGE) mode:NSLineBreakByWordWrapping];
    
    CGFloat titleH = size.height;
    titleH += 18;//padding;
    if (titleH < kTitleSingleH) {
        titleH = kTitleSingleH;
    }
    CGFloat oldH = [(PRContentTextView *)textView textHeight];
    if (oldH != titleH) {
        oldH = titleH;
        [(PRContentTextView *)textView setTextHeight:oldH];
        [textView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(titleH);
        }];
    }
    if (_titleView != textView){
        if (textView.text.length == 0) {
            if ([(![self isFooterEditView] ? _contentView.subviews : _footerView.footerContentView.subviews) indexOfObject:textView] == 0) {
                if ((![self isFooterEditView] ? _contentView.subviews : _footerView.footerContentView.subviews).count == 1) {
                    ((PRContentTextView *)textView).showPlaceHolder = YES;
                }else{
                    ((PRContentTextView *)textView).showPlaceHolder = NO;
                }
            }
            
        }else{
           ((PRContentTextView *)textView).showPlaceHolder = NO;
        }
        if (![self isFooterEditView]) {
            [_headerView updateContentViewH];
        }else{
            [_footerView footerUpdateContentViewH];
        }
        
    }

    [_layout invalidateLayout];

    if (!_bEditDeleting && !_bEditAdding) {
        [self adjustContainer];
    }
    
}

#pragma mark - collectionview delagate && datasource

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section{
    if (section == 0) {
        if (_headerView) {
            return CGSizeMake(kScreenWidth, [_headerView viewHeight]);
        }
        return CGSizeMake(kScreenWidth, [PRArticleHeaderView headerHeight]);
    }else{
        return CGSizeZero;
    }
    
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section{
    if (section == 1) {
        
        if (self.needRemoveBottomEditView) {
            return CGSizeZero;
        }
        
        if (_footerView) {
            return CGSizeMake(kScreenWidth, [_footerView footerViewHeight]);
        }
        return CGSizeMake(kScreenWidth, [PRArticleFooterView footerHeight]);
    }
    
    return CGSizeZero;
}


-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath{
    
    if (kind == UICollectionElementKindSectionHeader) {
        if (indexPath.section == 0) {
            if (_headerView) {
                return _headerView;
            }
            PRArticleHeaderView *header = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"PRArticleHeaderView" forIndexPath:indexPath];
            header.backgroundColor = [UIColor clearColor];
            [header isGoldDiscuss:self.discussMsgs.count > 0 groupName:self.groupName.length > 0 ? self.groupName : @""];
            header.titleView.delegate = self;
            _titleView = header.titleView;
            _headerView = header;
            _contentView = header.contentView;
            [(UITextView *)[_contentView.subviews firstObject] setDelegate:self];
            W_S
            [header setChangeCoverBlock:^{
                [weakSelf chooseCover];
            }];
            _bgImgV = [_headerView bgImgV];
            
            if (self.discussMutableMsgs.count > 0) {
                [header addSubview:self.sectionHeader];
                [self.sectionHeader mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.left.right.bottom.equalTo(header);
                    make.height.equalTo(@44);
                }];
            }
            
            [self loadDraftData];
            
            return header;
        }
    }
    
    if (kind == UICollectionElementKindSectionFooter){
        if (indexPath.section == 1) {
            
            if (self.needRemoveBottomEditView) {
                [self.footerView removeFromSuperview];
                return [UICollectionReusableView new];
            }
            
            PRArticleFooterView *footer = (PRArticleFooterView *)[collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"PRArticleFooterView_re_id" forIndexPath:indexPath];
            footer.backgroundColor = [UIColor clearColor];
            if (_footerView) {
                
                CGRect fframe = _footerView.frame;
                fframe.origin = footer.frame.origin;
                _footerView.frame = fframe;
                
                [footer removeFromSuperview];
                return _footerView;
            }
            _footerView = footer;
            [(UITextView *)[_footerView.footerContentView.subviews firstObject] setDelegate:self];
            
            [self loadEndDraftData];
            return footer;
        }
    }
    return [UICollectionReusableView new];
}

-(BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return self.isGodDiscuss ? 2 : 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return section == 0 ? 0 : _discussMutableMsgs.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.section == 0) {
        return [UICollectionViewCell new];
    }
    
    NSDictionary *data = _discussMutableMsgs[indexPath.row];
    
    PRArticleEditCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:PRArticleEditCell_re_id forIndexPath:indexPath];
    /**  是否显示勾选控件 */
    [cell showLeftPickerElement:_bSelectMode];
    /**  是否显示排序控件 */ 
    [cell configAdjustButtonsDispaly:_bSortSelectMode];

    if (_bSelectMode) {
        [cell setMessageChoosed:[_pickedMsgs containsObject:data]];
    }
    /**  配置cell数据源 */
    [cell configWithDiscuss:data displayForHead:indexPath.row != 0 footer:indexPath.row != _discussMutableMsgs.count - 1];
    
    W_S
    cell.upTapBlock = ^(UIButton *sender) {
        if (indexPath.row == 0) {
            return ;
        }
        //sourceIndexPath是被点击cell的IndexPath
        NSIndexPath *sourceIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section];
        NSIndexPath *destinationIndexPath = [NSIndexPath indexPathForRow:indexPath.row - 1 inSection:indexPath.section];
        
        [weakSelf.discussMutableMsgs exchangeObjectAtIndex:sourceIndexPath.row withObjectAtIndex:destinationIndexPath.row];
        //移动cell的位置
        [weakSelf.containerView moveItemAtIndexPath:sourceIndexPath toIndexPath:destinationIndexPath];
        [weakSelf.containerView reloadItemsAtIndexPaths:@[sourceIndexPath,destinationIndexPath]];
    };
    
    
    cell.downTapBlock = ^(UIButton *sender) {
        if (indexPath.row == weakSelf.discussMutableMsgs.count - 1) {
            return ;
        }
        //sourceIndexPath是被点击cell的IndexPath
        NSIndexPath *sourceIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section];
        NSIndexPath *destinationIndexPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
        
        [weakSelf.discussMutableMsgs exchangeObjectAtIndex:sourceIndexPath.row withObjectAtIndex:destinationIndexPath.row];
        //移动cell的位置
        [weakSelf.containerView moveItemAtIndexPath:sourceIndexPath toIndexPath:destinationIndexPath];
        [weakSelf.containerView reloadItemsAtIndexPaths:@[sourceIndexPath,destinationIndexPath]];
    };
    
    cell.chooseBlock = ^(NSDictionary *msg) {
        [weakSelf handleChooseMessage:msg];
    };
    
    return cell;
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0) {
        return CGSizeZero;
    }
    NSDictionary *data = _discussMutableMsgs[indexPath.row];
    CGFloat cellHeight = [PRArticleEditCell cellHeightForType:data];
    return CGSizeMake(kScreenWidth, cellHeight);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section{
    return 0;
}

#pragma mark -- 选择封面图
-(void)chooseCover{
    
    PRImagePickerVc *pvc = [PRImagePickerVc new];
    pvc.bDisallowMulti = YES;
    pvc.bHideOriginIcon = YES;
    pvc.bEnableShoot = YES;
    pvc.pickMode = kPickType_ImageOnly;
    __weak PRImagePickerVc *weakPvc = pvc;
    __weak PRPostArticleVc *ws = self;
    //TODO cut image
    [pvc setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets, BOOL isSelectOriginalPhoto) {
        
        PRImagePreviewVc *vc = [PRImagePreviewVc new];
        vc.models = weakPvc.selectedModels;
        vc.cropSize = CGSizeMake(kScreenWidth, kScreenWidth*9/16.f);// snd.bounds.size;
        vc.bAllowCrop = YES;
        [vc setCropBlock:^(UIImage *image, PRImagePreviewVc *__weak wvc) {
            
            [ws.headerView hideBannerAddIcon];
            
            [ws.bgImgV setContentMode:UIViewContentModeScaleToFill];
            ws.bgImgV.image = image;
            
            if (ws.bgImgV.image) {
                [ws.headerView updateChangeCoverStyle];
            }
                        
            [wvc dismissViewControllerAnimated:YES completion:nil];
        }];
        
        [weakPvc dismissViewControllerAnimated:YES completion:^{
            [ws presentViewController:vc animated:YES completion:nil];
        }];
        
        [weakPvc dismissViewControllerAnimated:YES completion:nil];
    }];
    [self presentViewController:pvc animated:YES completion:nil];

    
}

#pragma mark -- 预览
- (void)previewArticle{
    
    if(_beyondLimitWord){
        [PDCommonUtil showCenterCommonTip:[PDCommonUtil getStringWith:@"p_title_beyond_limit_words"] At:self.view];
        return;
    }
    
    PRArticlePreviewVc *pvc = [PRArticlePreviewVc new];
    
    pvc.articleData = [self composeArticleInfo:NO];
    if (!pvc.articleData) {
        return;
    }
    pvc.postGroupID = _postGroupID;
    pvc.postColumnID = _postColumnID;
    pvc.releaseFeedID = _releaseFeedID;
    
    pvc.discussMsgs = _discussMutableMsgs.copy;
    
    __weak PRPostArticleVc *ws = self;
    [pvc setOnArticlePreviewPostBlock:^(PRPostDataEntity *data) {
        if (ws.onArticlePostBlock) {
            ws.onArticlePostBlock(data);
        }
        if (ws.editPostBlock) {
            ws.editPostBlock(NO, data);
        }
    }];
    [self presentViewController:pvc animated:YES completion:nil];
    
}

#pragma mark -- 组装发布数据
-(PRPostDataEntity *)composeArticleInfo:(BOOL)bSaveDraft{
    PRPostDataEntity *localData = [PRPostDataEntity new];
    localData.postType = kPost_Article;
    
    UIImage *bannerImg = [_headerView bgImgV].image;
    NSString *title = [_headerView titleView].text;
    NSArray *contentSubViews = [_headerView contentView].subviews;
    NSArray *footerContentSubViews = [_footerView footerContentView].subviews;
    
    localData.articleBannerImg = bannerImg;
    localData.postTitle = title;
    
    localData.isGodDiscuss = self.isGodDiscuss;
    if (bSaveDraft) {
        if (![self canSaveDraft]) {
            return nil;
        }
    }else{
        /**  没有封面图 */
        if (!bannerImg) {
            [PDCommonUtil showCenterCommonTip:[PDCommonUtil getStringWith:@"p_set_cover_hint"] At:self.view];
            return nil;
        }
        /**  没有标题 */
        if (title.length == 0) {
            [PDCommonUtil showCenterCommonTip:[PDCommonUtil getStringWith:@"p_input_title_hint"] At:self.view];
            return nil;
        }
        /**  没有正文 */
        if ([self contentIsEmpty]) {
            [PDCommonUtil showCenterCommonTip:[PDCommonUtil getStringWith:@"p_input_text_hint"] At:self.view];
            return nil;
        }
    }
    
    
    NSMutableArray<PRArticleParagraph *> *contents = [NSMutableArray array];
    NSMutableArray<PRArticleParagraph *> *endContents = [NSMutableArray array];
    
    localData.articleParagraphs = contents;
    localData.articleEndParagraphs = endContents;
    
    
    [contentSubViews enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self composeDataTool:obj localData:localData array:contents];
    }];
    
    [footerContentSubViews enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self composeDataTool:obj localData:localData array:endContents];
    }];
    
    return localData;
}

-(void)composeDataTool:(id  _Nonnull)obj  localData:(PRPostDataEntity *)localData array:(NSMutableArray *)contents{
    if ([obj isKindOfClass:[PRContentTextView class]]) {
        NSString *text = [(PRContentTextView*)obj text];
        PRArticleParagraph *paragraph = [PRArticleParagraph new];
        paragraph.localPreview = YES;
        paragraph.paragraphType = kParagraphText;
        paragraph.text = text;
        if(localData.articleSummary.length == 0){
            localData.articleSummary = text;
        }
        [contents addObject:paragraph];
        
    }else if ([obj isKindOfClass:[PRContentMediaView class]]){
        PRArticleParagraph *paragraph = [PRArticleParagraph new];
        paragraph.localPreview = YES;
        PRContentMediaView *info = obj;
        if(kMedia_Image == info.mType){
            paragraph.paragraphType = kParagraphImage;
            paragraph.image = info.image;
            paragraph.localAssetId = info.localAssetId;
            paragraph.mediaType = info.mediaType;
            
        }else if (kMedia_Video == info.mType){
            paragraph.paragraphType = kParagraphVideo;
            NSMutableDictionary *vinfo = [NSMutableDictionary dictionaryWithDictionary:info.videoInfo];
            if (vinfo.isPrivateAsset) {
                [vinfo removeObjectForKey:kPrivateVideoAsset];
            }
            paragraph.videoInfo = vinfo;
        }
        [contents addObject:paragraph];
    }
}

#pragma mark -- 整体保存草稿
-(void)saveDraft{
    PRPostDataEntity *draftPost = [self composeArticleInfo:YES];
    if (!draftPost) {
        return;
    }
    draftPost.discussMsgs = _discussMutableMsgs.copy;// _discussMsgs.copy;
    draftPost.groupID = _postGroupID;
    draftPost.columnID = _postColumnID;
    draftPost.release_subjectid = _releaseFeedID;
    draftPost.isLocal = YES;
    draftPost.authorID = [UMSCloud shareInstance].getLastLoginUser.objectID;
    
    
    draftPost.postTime = [NSDate date];
    if (_draftData) {
        draftPost.feedID = _draftData.feedID;
        
    }else{
        draftPost.feedID = @([UMSCloud getMessageID]).description;
    }
    
    __weak PRPostArticleVc *ws = self;
    [PDCommonUtil showProgressMsg:[PDCommonUtil getStringWith:@"p_handling"] At:self.view withBlock:^(MBProgressHUD *hud) {
        pd_dispatch_async(^{
            NSData *draftData = [NSKeyedArchiver archivedDataWithRootObject:draftPost];
            NSString *path = [PDCommonUtil getLocalFeedDraftPath:draftPost.feedID];
            
            BOOL ret = [draftData writeToFile:path atomically:NO];
            NSLog(@"save ret: %@", @(ret));
            pd_dispatch_main_sync_safe(^{
                [hud hideAnimated:NO];
                if (ws.editPostBlock && ret) {
                    ws.editPostBlock(YES, draftPost);
                }
                [ws backAction:nil];
                
            });
        });
        
    }];
    
}

#pragma mark -- lazyLoad


-(PreViewSectionHeader *)sectionHeader{
    if (!_sectionHeader) {
        _sectionHeader = [[PreViewSectionHeader alloc] initWithFrame:CGRectZero];
    }
    return _sectionHeader;
}

-(NSMutableArray<NSDictionary *> *)discussMutableMsgs{
    if (!_discussMutableMsgs) {
        _discussMutableMsgs = [[NSMutableArray alloc] init];
    }
    return _discussMutableMsgs;
}

-(UIButton *)nextButton{
    if (!_nextButton) {
        _nextButton = [[UIButton alloc] init];
        [_nextButton setTitleColor:[PDCommonUtil commonBlackColor] forState:UIControlStateNormal];
        [_nextButton setTitle:[PDCommonUtil getStringWith:@"p_preview"] forState:UIControlStateNormal];
        _nextButton.titleLabel.font = [PDCommonUtil commonRegularFont:18];
        [_nextButton setBackgroundImage:[PDCommonUtil createImageWithColor:[PDCommonUtil commonYellowColor]] forState:UIControlStateNormal];
        [_nextButton addTarget:self action:@selector(previewArticle) forControlEvents:UIControlEventTouchUpInside];
    }
    return _nextButton;
}

-(UIButton *)functionBtn{
    if (!_functionBtn) {
        _functionBtn = [[UIButton alloc] init];
        [_functionBtn setTitleColor:[PDCommonUtil commonBlackColor] forState:UIControlStateNormal];
        _functionBtn.titleLabel.font = [PDCommonUtil commonRegularFont:16];
        [_functionBtn setBackgroundImage:[PDCommonUtil createImageWithColor:RGB(233, 233, 233)] forState:UIControlStateDisabled];
        [_functionBtn setBackgroundImage:[PDCommonUtil createImageWithColor:[PDCommonUtil commonYellowColor]] forState:UIControlStateNormal];
        _functionBtn.layer.cornerRadius = 5;
        _functionBtn.layer.masksToBounds = YES;
        _functionBtn.enabled = NO;
    }
    return _functionBtn;
}

-(UIButton *)cancelBtn{
    if (!_cancelBtn) {
        _cancelBtn = [[UIButton alloc] init];
        [_cancelBtn setTitleColor:[PDCommonUtil commonBlackColor] forState:UIControlStateNormal];
        _cancelBtn.titleLabel.font = [PDCommonUtil commonRegularFont:16];
        _cancelBtn.backgroundColor = [UIColor whiteColor];
        [_cancelBtn setTitle:[PDCommonUtil getStringWith:@"p_cancel"] forState:UIControlStateNormal];
        [_cancelBtn addTarget:self action:@selector(cancelTapAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelBtn;
}

-(UICollectionView *)containerView{
    if (!_containerView) {
        _layout = [[UICollectionViewFlowLayout alloc] init];
        [_layout setScrollDirection:UICollectionViewScrollDirectionVertical];
        
        _containerView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:_layout];
        _containerView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
        _containerView.alwaysBounceVertical = YES;
        _containerView.delegate = self;
        _containerView.dataSource = self;
        _containerView.showsVerticalScrollIndicator = NO;
        
        [_containerView registerClass:PRArticleHeaderView.class forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"PRArticleHeaderView"];
        
        [_containerView registerClass:PRArticleFooterView.class forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"PRArticleFooterView_re_id"];
        
        CollectionViewNOXIBRegisterCell(_containerView, PRArticleEditCell, PRArticleEditCell_re_id);
        
        _containerView.backgroundColor = [UIColor clearColor];
        
    }
    return _containerView;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
