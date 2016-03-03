//
//  UMComAction.h
//  UMCommunity
//
//  Created by Gavin Ye on 11/11/14.
//  Copyright (c) 2014 Umeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UMComTools.h"


typedef void(^LoginCompletion)(id responseObject, NSError *error);

@class UMComUser;

@interface UMComAction : NSObject



+ (id)action;

- (void)performActionAfterLogin:(id)param
                 viewController:(UIViewController *)viewController
                     completion:(LoginCompletion)loginCompletion;

//显示推荐用户页面
- (void)showRecommendUserWithViewController:(UIViewController *)viewController
                                 completion:(void (^)(UIViewController *recommendUserVC))completion;
// 显示推荐话题页面
- (void)showRecommendTopicWithViewController:(UIViewController *)viewController completion:(void (^)(UIViewController *recommendTopicVC))completion;


@end

