//
//  UMComLoginManager.m
//  UMCommunity
//
//  Created by Gavin Ye on 8/25/14.
//  Copyright (c) 2014 Umeng. All rights reserved.
//

#import "UMComLoginManager.h"
#import "UMComHttpManager.h"
#import "UMComSession.h"
#import "UMComMessageManager.h"
#import "UMComPullRequest.h"
#import "UMComUser+UMComManagedObject.h"
#import "UMComShowToast.h"
#import "UMUtils.h"
#import "UMComPushRequest.h"

@interface UMComLoginManager ()

@property (nonatomic, strong) id<UMComLoginDelegate> loginHandler;

@property (nonatomic, copy) NSString *appKey;

@property (nonatomic, copy) void (^loginCompletion)(id responseObject, NSError *error);//登录回调

@end

@implementation UMComLoginManager

static UMComLoginManager *_instance = nil;
+ (UMComLoginManager *)shareInstance {
    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    }
    
    return _instance;
}

+ (void)setAppKey:(NSString *)appKey
{
    if ([[self shareInstance].loginHandler respondsToSelector:@selector(setAppKey:)]) {
        [self shareInstance].appKey = appKey;
        [[self shareInstance].loginHandler setAppKey:appKey];
    }
}

- (id)init
{
    self = [super init];
    if (self) {
        
        Class delegateClass = NSClassFromString(@"UMComUMengLoginHandler");
        self.loginHandler = [[delegateClass alloc] init];
    }
    return self;
}

+ (void)performLogin:(UIViewController *)viewController completion:(void (^)(id responseObject, NSError *error))completion
{
    if ([self isLogin]) {
        if (completion) {
            completion([UMComSession sharedInstance].loginUser,nil);
        }
    }else if ([self shareInstance].loginHandler) {
        //设置登录登录回调
        [self shareInstance].loginCompletion = completion;
        //弹出登录页面
        [[self shareInstance].loginHandler presentLoginViewController:viewController finishResponse:nil];
    }else{
        UMLog(@"There is no implement login delegate method");
    }
}

+ (id<UMComLoginDelegate>)getLoginHandler
{
    return [self shareInstance].loginHandler;
}

+ (BOOL)isLogin{
    BOOL isLogin = [UMComSession sharedInstance].isLogin;
    return isLogin;
}

+ (void)setLoginHandler:(id <UMComLoginDelegate>)loginHandler
{
    [self shareInstance].loginHandler = loginHandler;
}

+ (BOOL)handleOpenURL:(NSURL *)url
{
    if ([[self shareInstance].loginHandler respondsToSelector:@selector(handleOpenURL:)]) {
        return [[self shareInstance].loginHandler handleOpenURL:url];
    }
    return NO;
}

+ (BOOL)isIncludeSpecialCharact:(NSString *)str {
    
    NSString *regex = @"(^[a-zA-Z0-9_\u4e00-\u9fa5]+$)";
    NSPredicate *   pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    BOOL isRight = ![pred evaluateWithObject:str];
    return isRight;
}

+ (void)loginWithLoginViewController:(UIViewController *)loginViewController userAccount:(UMComUserAccount *)loginUserAccount
{
    UMComLoginManager *loginManager = [UMComLoginManager shareInstance];
    
    if (loginManager.loginFinishHadleDelegate && [loginManager.loginFinishHadleDelegate respondsToSelector:@selector(loginWithLoginViewController:userAccount:completion:)]) {
        //实现自定义登录逻辑，里面实现了登录之后的默认跳转页面
        [loginManager.loginFinishHadleDelegate loginWithLoginViewController:loginViewController userAccount:loginUserAccount completion:^(id responseObject, NSError *error) {
            [UMComLoginManager loginSuccessWithUser:responseObject];
            SafeCompletionDataAndError(loginManager.loginCompletion, responseObject, error);
        }];
    }
    
////    基本登录逻辑（如果不适用demo推荐的登录逻辑可以直接实现这个方法）
//    [UMComPushRequest loginWithUser:loginUserAccount completion:^(id responseObject, NSError *error) {
//        if ([responseObject isKindOfClass:[UMComUser class]]) {
//            [UMComLoginManager loginSuccessWithUser:responseObject];
//            [loginViewController dismissViewControllerAnimated:YES completion:^{
//                SafeCompletionDataAndError(loginManager.loginCompletion, responseObject, nil);
//            }];
//        }else{
//            SafeCompletionDataAndError(loginManager.loginCompletion, responseObject, error);
//        }
//    }];
}

+ (void)loginSuccessWithUser:(UMComUser *)loginUser
{
    if (![loginUser isKindOfClass:[UMComUser class]]) {
        return;
    }
    NSString *uid = loginUser.uid;
    [[NSNotificationCenter defaultCenter] postNotificationName:kUserLoginSucceedNotification object:nil];
    NSString *aliasKey = @"UM_COMMUNITY";
    [UMComMessageManager addAlias:uid type:aliasKey response:^(id responseObject, NSError *error) {
        if (error) {
            //添加alias失败的话在每次启动时候重新添加
            [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"UMComMessageAddAliasFail"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            UMLog(@"add alias is %@ error is %@",responseObject,error);
        }
    }];
}

+ (void)userLogout
{
    [[UMComSession sharedInstance] userLogout];
}

@end
