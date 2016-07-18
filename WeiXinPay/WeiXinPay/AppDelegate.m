//
//  AppDelegate.m
//  WeiXinPay
//
//  Created by ios_kai on 16/7/18.
//  Copyright © 2016年 ios_kai. All rights reserved.
//

#import "AppDelegate.h"

//微信支付
#import "WXApi.h"

@interface AppDelegate ()<WXApiDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    //注册微信支付
    [WXApi registerApp:APP_id withDescription:@"demo"];
    
    return YES;
}

//iOS9 之后使用这个回调方法。
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options
{
    if ([url.host isEqualToString:@"pay"]) {
        
        return [WXApi handleOpenURL:url delegate:self];
    }
    
    return YES;
}


#pragma mark - 微信支付的代理方法
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    return  [WXApi handleOpenURL:url delegate:self];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{

    if ([url.host isEqualToString:@"pay"]) {
        
        return [WXApi handleOpenURL:url delegate:self];
    }
    
    return YES;
    
}

#pragma mark - 微信支付成功的回调函数（这个方法必须写在delegate.m文件中）
-(void)onResp:(BaseResp*)resp
{
    if ([resp isKindOfClass:[PayResp class]]){
        
        PayResp *response = (PayResp*)resp;
        
        switch(response.errCode){
                
            case WXSuccess:
                //服务器端查询支付通知或查询API返回的结果再提示成功
                //NSLog(@"支付成功");
                
                //发送通知给带有微信支付功能的视图控制器，告诉他支付成功了，请求后台订单状态，如果后台返回的订单也是成功的状态，那么可以进行下一步操作
                [[NSNotificationCenter defaultCenter] postNotificationName:WEIXINPAYSUCCESSED object:nil userInfo:nil];
                
                
                break;
                
            default:
                
                /*
                 
                 resp.errCode = 2 用户取消支付
                 resp.errCode = -1 错误
                 */
                NSLog(@"支付失败，retcode=%d ---- %@",resp.errCode,resp.errStr);
                
                break;
        }
    }
}//微信支付成功的回调方法（回调函数）


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
