//
//  UMComUserRecommendViewController.h
//  UMCommunity
//
//  Created by umeng on 15-3-31.
//  Copyright (c) 2015年 Umeng. All rights reserved.
//

#import "UMComRequestTableViewController.h"

@class UMComPullRequest;

@interface UMComUsersTableViewController : UMComRequestTableViewController

@property (nonatomic, copy) void (^completion)(UIViewController *viewController);

@property (nonatomic, strong) NSArray *userList;

- (id)initWithCompletion:(void (^)(UIViewController *viewController))completion;


@end
