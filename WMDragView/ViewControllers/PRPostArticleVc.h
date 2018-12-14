//
//  PRPostArticleVc.h
//  ProCloser
//
//  Created by xzming on 2017/12/22.
//  Copyright © 2017年 HZMC. All rights reserved.
//

#import "PRSuperVc.h"
#import "PRPostDataEntity.h"
#import "PRGroupCellEntity.h"

typedef void(^OnArticlePost)(PRPostDataEntity *data);
typedef void(^editComplete)(BOOL bSave, PRPostDataEntity *draft);

@interface PRPostArticleVc : PRSuperVc

@property (nonatomic, strong) NSString *postGroupID;
@property (nonatomic, copy) OnArticlePost onArticlePostBlock;

@property (nonatomic, strong) NSArray<NSDictionary *> *discussMsgs;

@property (nonatomic, strong) PRPostDataEntity *draftData;
@property (nonatomic, copy) editComplete editPostBlock;

@property (nonatomic, strong) NSString *releaseFeedID;

@property (nonatomic, strong) NSString *postColumnID;

/** 群名称  */
@property (nonatomic, copy) NSString *groupName;

@end
