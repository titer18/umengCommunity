//
//  UMComLoginManager.h
//  UMCommunity
//
//  Created by Gavin Ye on 8/25/14.
//  Copyright (c) 2014 Umeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UMComUserAccount.h"
#import "UMComLoginDelegate.h"


@protocol UMComLoginFinishHandelerDelegate <NSObject>

/**
 处理自定义登录，在友盟微社区没有登录情况下点击遇到需要登录的按钮，就会触发此方法
 
 @param loginViewController 登录页面
 @param loginUserAccount 登录用户参数
 @param completion 登录结束回调
 
 */
- (void)loginWithLoginViewController:(UIViewController *)loginViewController
                         userAccount:(UMComUserAccount *)loginUserAccount
                          completion:(void (^)(id responseObject, NSError *))completion;

@end


@interface UMComLoginManager : NSObject


/********************UMComFirstTimeHandelerDelegate*******************/
/**
 获取处理登录完后的逻辑的实现代理
 
 */
@property (nonatomic, strong) id<UMComLoginFinishHandelerDelegate> loginFinishHadleDelegate;

+ (UMComLoginManager *)shareInstance;

+ (void)loginWithLoginViewController:(UIViewController *)loginViewController userAccount:(UMComUserAccount *)loginUserAccount;

/**
 设置登录SDK的appkey
 
 */
+ (void)setAppKey:(NSString *)appKey;

/**
 处理SSO跳转回来之后的url
 
 */
+ (BOOL)handleOpenURL:(NSURL *)url;

/**
 得到登录SDK实现对象
 
 */
+ (id<UMComLoginDelegate>)getLoginHandler;

/**
 设置登录SDK实现对象
 
 */
+ (void)setLoginHandler:(id <UMComLoginDelegate>)loginHandler;


/**
 获取当前是否登录
 
 */
+ (BOOL)isLogin;


/**
 提供社区SDK调用，默认使用友盟登录SDK，或者自定义的第三方登录SDK，实现登录功能
 
 */
+ (void)performLogin:(UIViewController *)viewController completion:(void (^)(id responseObject, NSError *error))completion;



//
///**
// 第三方登录SDK登录完成后，调用此方法上传登录的账号信息
// 
// */
//+ (void)finishLoginWithAccount:(UMComUserAccount *)userAccount completion:(LoadDataCompletion)completion;
//
///**
// 第三方登录SDK登录完成并dismiss登录的页面之后，调用此方法进入社区sdk下一步的操作
// 
// */
//+ (void)finishDismissViewController:(UIViewController *)viewController data:(NSArray *)data error:(NSError *)error;

/**
 用户注销方法
 
 @warning 调用这个方法退出登录同时会清空数据库（在没登陆的情况下慎重调用）
 */
+ (void)userLogout;


@end



