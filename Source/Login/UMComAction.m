//
//  UMComAction.m
//  UMCommunity
//
//  Created by Gavin Ye on 11/11/14.
//  Copyright (c) 2014 Umeng. All rights reserved.
//

#import "UMComAction.h"
#import "UMComSession.h"
#import "UMComPushRequest.h"
#import "UMComErrorCode.h"
#import "UMComMessageManager.h"
#import "UMComShowToast.h"
#import "UMUtils.h"
#import "UMComProfileSettingController.h"
#import "UMComSession.h"
#import "UMComUsersTableViewController.h"
#import "UMComTopicsTableViewController.h"
#import "UMComNavigationController.h"
#import "UMComPullRequest.h"

@interface UMComAction () <UMComLoginFinishHandelerDelegate>

@property (nonatomic, strong) NSError *error;

@property (nonatomic, strong) UMComUserAccount *loginUserAccount;

@property (nonatomic, assign) BOOL didUpdateFinish;

@property (nonatomic, strong) UIViewController *currentViewController;

@property (nonatomic, strong) UIViewController *loginViewController;


@end

@implementation UMComAction

+ (id)action
{
    UMComAction *action = [[self alloc] init];
    [UMComLoginManager shareInstance].loginFinishHadleDelegate = action;
    return action;
}

- (void)performActionAfterLogin:(id)param
                 viewController:(UIViewController *)viewController
                     completion:(LoginCompletion)loadDataCompletion
{
    self.currentViewController = viewController;
    [UMComLoginManager performLogin:viewController completion:^(id responseObject, NSError *error) {
        if (loadDataCompletion) {
            loadDataCompletion(responseObject,error);
        }
    }];
}

- (void)loginWithLoginViewController:(UIViewController *)loginViewController
                         userAccount:(UMComUserAccount *)loginUserAccount
                          completion:(void (^)(id responseObject, NSError *))completion
{
    self.loginViewController = loginViewController;
    self.loginUserAccount = loginUserAccount;
    __weak typeof(self) weakSelf = self;
    [UMComPushRequest loginWithUser:loginUserAccount completion:^(id responseObject, NSError *error) {
        [weakSelf handleLoginDataWhenLoginSecceed:responseObject error:error completion:completion];
    }];
}


- (void)handleLoginDataWhenLoginSecceed:(id)responseObject
                                  error:(NSError *)error
                             completion:(LoginCompletion)completion
{
    __weak typeof (self) weakSelf = self;
    if ([responseObject isKindOfClass:[UMComUser class]]) {//
        UMComUser *loginUser = responseObject;
        
        [self.loginViewController dismissViewControllerAnimated:NO completion:^{
            if ([loginUser.registered integerValue] == 0) {//如果是第一次登陆//
                if (_didUpdateFinish) {
                    // 注册后因为用户名有错误，已经修改过用户名，直接显示推荐话题和推荐用户页面
                    [weakSelf showRecommendViewControllerWithLoginViewController:weakSelf.currentViewController loginComletion:^{
                        SafeCompletionDataAndError(completion, responseObject, nil);
                    }];
                }else{
                    // 注册后用户名正确，没有修改过用户名，则显示用户信息修改页面
                    [weakSelf showUserAccountSettingViewController:weakSelf.currentViewController userAccont:weakSelf.loginUserAccount error:nil completion:^(UIViewController *viewController, UMComUserAccount *userAccount) {
                        //显示推荐话题和推荐用户页面
                        [weakSelf showRecommendViewControllerWithLoginViewController:weakSelf.currentViewController loginComletion:^{
                           SafeCompletionDataAndError(completion, responseObject, nil);
                        }];
                    }];
                }
            }else{//如果不是第一次登录
                [self.loginViewController dismissViewControllerAnimated:YES completion:nil];
                SafeCompletionDataAndError(completion, responseObject, nil);
            }
        }];
        
    }else{
        if (error.code == ERR_CODE_USER_NAME_LENGTH_ERROR || error.code == ERR_CODE_USER_NAME_SENSITIVE || error.code == ERR_CODE_USER_NAME_DUPLICATE || error.code == ERR_CODE_USER_NAME_CONTAINS_ILLEGAL_CHARS) {
            //如果登录的是后用户名不服和要求则会调到用户设置页面
            [UMComShowToast showFetchResultTipWithError:error];
            [weakSelf showUserAccountSettingViewController:weakSelf.loginViewController userAccont:weakSelf.loginUserAccount error:error completion:^(UIViewController *viewController, UMComUserAccount *userAcount) {
                //用户名修改完成后重新登录
                weakSelf.didUpdateFinish = YES;
                [UMComPushRequest loginWithUser:userAcount completion:^(id responseObject, NSError *error) {
                    if (!error) {
                        [viewController dismissViewControllerAnimated:YES completion:^{
                            [weakSelf handleLoginDataWhenLoginSecceed:responseObject error:error completion:completion];
                        }];
                    }else{
                        [weakSelf handleLoginDataWhenLoginSecceed:responseObject error:error completion:completion];
                    }
                }];
            }];
        } else{
            SafeCompletionDataAndError(completion, responseObject, error);
            [UMComShowToast showFetchResultTipWithError:error];
        }
    }
}

- (void)showUserAccountSettingViewController:(UIViewController *)viewController
                                  userAccont:(UMComUserAccount *)userAccount
                                       error:(NSError *)error
                                  completion:(void (^)(UIViewController *viewController, UMComUserAccount *loginUserAccount))completion
{
    UMComProfileSettingController *profileController = [[UMComProfileSettingController alloc] init];
    if (error) {
        profileController.settingCompletion = ^(UIViewController *viewController, UMComUserAccount *loginUserAccount){
            SafeCompletionDataAndError(completion, viewController, loginUserAccount);
        };
        profileController.registerError  = error;
    }else{
        profileController.updateCompletion = ^(id data, NSError *error){
            SafeCompletionDataAndError(completion, nil, nil);
        };
    }
    profileController.userAccount = userAccount;
    UMComNavigationController *profileNaviController = [[UMComNavigationController alloc] initWithRootViewController:profileController];
    [viewController presentViewController:profileNaviController animated:YES completion:nil];
}

- (void)showRecommendViewControllerWithLoginViewController:(UIViewController *)viewController loginComletion:(void (^)())loginCompletion
{
    [self showRecommendTopicWithViewController:viewController completion:^(UIViewController *recommendTopicVC) {
        [self showRecommendUserWithViewController:recommendTopicVC completion:^(UIViewController *recommendUserVC) {
            [recommendUserVC dismissViewControllerAnimated:YES completion:nil];
            if (loginCompletion) {
                loginCompletion();
            }
        }];
    }];
}



- (void)showRecommendUserWithViewController:(UIViewController *)viewController
                                 completion:(void (^)(UIViewController *recommendUserVC))completion
{
    UMComUsersTableViewController *userRecommendViewController = [[UMComUsersTableViewController alloc] initWithCompletion:completion];
    userRecommendViewController.isAutoStartLoadData = YES;
    userRecommendViewController.title = UMComLocalizedString(@"user_recommend", @"用户推荐");
    userRecommendViewController.fetchRequest = [[UMComRecommendUsersRequest alloc]initWithCount:BatchSize];
    [viewController.navigationController pushViewController:userRecommendViewController animated:YES];
}

- (void)showRecommendTopicWithViewController:(UIViewController *)viewController completion:(void (^)(UIViewController *recommendTopicVC))completion
{
    UMComTopicsTableViewController *topicsRecommendViewController = [[UMComTopicsTableViewController alloc] initWithCompletion:completion];
    topicsRecommendViewController.completion = completion;
    topicsRecommendViewController.isAutoStartLoadData = YES;
    topicsRecommendViewController.isShowNextButton = YES;
    topicsRecommendViewController.title = UMComLocalizedString(@"user_topic_recommend", @"话题推荐");
    topicsRecommendViewController.fetchRequest = [[UMComRecommendTopicsRequest alloc]initWithCount:BatchSize];
    UMComNavigationController *topicsNav = [[UMComNavigationController alloc] initWithRootViewController:topicsRecommendViewController];
    [viewController presentViewController:topicsNav animated:YES completion:nil];
}

@end
