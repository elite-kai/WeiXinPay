//
//  ViewController.m
//  WeiXinPay
//
//  Created by ios_kai on 16/7/18.
//  Copyright © 2016年 ios_kai. All rights reserved.
//

#import "ViewController.h"
//微信支付
#import "WXApi.h"
#import "payRequsestHandler.h"
#import "WXUtil.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(60, 100, 180, 100)];
    button.backgroundColor = [UIColor redColor];
    [button setTitle:@"微信支付" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(test) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    //接受成功的通知
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(succeed) name:WEIXINPAYSUCCESSED object:nil];
}

#pragma mark - ASction Methods
- (void)test
{
    
    payRequsestHandler *handle = [[payRequsestHandler alloc]init];
    
    if ( [handle  init:APP_id mch_id:MCH_id]) {
        
        NSLog(@"初始化成功");
        
    }
    
    //设置商户密钥
    [handle setKey:PARTNER_id];
    
    //提交预支付，获得prepape_id
    NSString *order_name = @"测试";   //订单标题
    NSString *order_price = @"1";//测试价格 分为单位
    NSString *nocify_URL = nocify_url;    //回调借口
    NSString *noncestr  = [NSString stringWithFormat:@"%d", rand()]; //随机串
    NSString *orderno   = [NSString stringWithFormat:@"%ld",time(0)];
    NSMutableDictionary *params = [@{@"appid":APP_id,
                                     @"mch_id":MCH_id,
                                     @"device_info":[[[UIDevice currentDevice] identifierForVendor] UUIDString],
                                     @"nonce_str":noncestr,
                                     @"trade_type":@"APP",
                                     @"body":order_name,
                                     @"notify_url":nocify_URL,
                                     @"out_trade_no":orderno,//商户订单号:这个必须用后台的订单号
                                     @"spbill_create_ip":@"8.8.8.8",
                                     @"total_fee":order_price}mutableCopy];
    
    //提交预支付两次签名得到预支付订单的id（每次的请求得到的预支付订单id都不同）
    NSString *prepate_id = [handle sendPrepay:params];
    
    //提交预订单成功
    if (prepate_id != nil) {
        
        PayReq *request = [[PayReq alloc]init];
        
        //商家id
        request.partnerId = MCH_id;
        
        //订单id
        request.prepayId = prepate_id;
        
        //扩展字段(官方文档:暂时填写固定值)
        request.package = @"Sign=WXPay";
        
        //随机字符串
        request.nonceStr = noncestr;
        
        //时间戳
        request.timeStamp = (UInt32)[[NSDate date] timeIntervalSince1970];
        
        //sign参数(很经常出现的问题:就是调起支付到微信那边只出现一个确定按钮，单击确认按钮直接返回到app，出现这个问题100%是sign参数的问题)
        /*
         参数依次是: appid_key、partnerid_key、prepayid_key、固定值Sign=WXPay、预支付的随机数（跟上面得到预支付订单的随机数要一致）、支付时间(秒)
         
         */
        request.sign = [self createMD5SingForPay:APP_id partnerid:MCH_id prepayid:prepate_id package:@"Sign=WXPay" noncestr:noncestr timestamp:(UInt32)[[NSDate date] timeIntervalSince1970]];
        
        
        
        //带起微信支付
        if ([WXApi sendReq:request]) {
            
            
            // NSLog(@"走这里啊");
            
        }else{
            
            //NSLog(@"走之类");
            //未安装微信客户端
//            [[[UIAlertView alloc]initWithTitle:@"测试demo" message:@"您还未安装微信客户端,请前往Appstore下载或者选择其他支付方式!" delegate:nil cancelButtonTitle:@"知道了" otherButtonTitles:nil, nil]show];
            
        }
        
    }
    
}//点击微信支付


#pragma mark - Private Methods
-(NSString *)createMD5SingForPay:(NSString *)appid_key partnerid:(NSString *)partnerid_key prepayid:(NSString *)prepayid_key package:(NSString *)package_key noncestr:(NSString *)noncestr_key timestamp:(UInt32)timestamp_key
{
    NSMutableDictionary *signParams = [NSMutableDictionary dictionary];
    [signParams setObject:appid_key forKey:@"appid"];
    [signParams setObject:noncestr_key forKey:@"noncestr"];
    [signParams setObject:package_key forKey:@"package"];
    [signParams setObject:partnerid_key forKey:@"partnerid"];
    [signParams setObject:prepayid_key forKey:@"prepayid"];
    [signParams setObject:[NSString stringWithFormat:@"%u",(unsigned int)timestamp_key] forKey:@"timestamp"];
    NSMutableString *contentString  =[NSMutableString string];
    NSArray *keys = [signParams allKeys];
    //按字母顺序排序
    NSArray *sortedArray = [keys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2 options:NSNumericSearch];
    }];
    //拼接字符串
    for (NSString *categoryId in sortedArray) {
        if (   ![[signParams objectForKey:categoryId] isEqualToString:@""]
            && ![[signParams objectForKey:categoryId] isEqualToString:@"sign"]
            && ![[signParams objectForKey:categoryId] isEqualToString:@"key"]
            )
        {
            [contentString appendFormat:@"%@=%@&", categoryId, [signParams objectForKey:categoryId]];
        }
    }
    //添加商户密钥key字段
    [contentString appendFormat:@"key=%@",PARTNER_id];
    NSString *result = [self md5:contentString];
    return result;
    
}//创建发起支付时的sige签名


-(NSString *)md5:(NSString *)str
{
    const char *cStr = [str UTF8String];
    unsigned char result[16]= "0123456789abcdef";
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
    //这里的x是小写则产生的md5也是小写，x是大写则md5是大写，这里只能用大写，微信的大小写验证很逗
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}//MD5 加密


- (void)succeed
{
    
    NSLog(@"支付成功");
    
    
}//支付成功的监听方法


#pragma mark - OverRide Methods
- (void)dealloc
{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:WEIXINPAYSUCCESSED object:nil];
    
    
}//移除通知


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
