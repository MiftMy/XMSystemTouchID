//
//  ViewController.m
//  XMSystemTouchID
//
//  Created by mifit on 15/11/19.
//  Copyright © 2015年 mifit. All rights reserved.
//

#import "ViewController.h"
#import <LocalAuthentication/LocalAuthentication.h>

@interface ViewController ()
@property (nonatomic,strong) LAContext* context;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    //初始化上下文对象
    self.context = [[LAContext alloc] init];
    
    [self checkTouchID];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/// 验证指纹
- (void)checkTouchID{
    //第一次输入错后多加的按钮显示的文字
    self.context.localizedFallbackTitle = @"换种方式";
    self.context.maxBiometryFailures = @2;
    
    /// 第一次验证成功后，30s内再次验证时候，无需用户验证指纹，就回调成功。默认0，最长5*60；
    self.context.touchIDAuthenticationAllowableReuseDuration = 30;
    
    NSLog(@"begin");
    [self authenticateUser];
    
    // 8s后再次验证
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"again");
        [self authenticateUser];
    });
}

// 验证指纹
- (void)authenticateUser {
    //可设context无效
    //[context invalidate];
    
    //错误对象
    NSError* error = nil;
    
    /// 在指纹验证弹出的提示语
    NSString* result = @"Authentication is needed to access your notes.";
    
    //首先使用canEvaluatePolicy 判断设备支持状态
    if ([self.context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
        //支持指纹验证，开始验证,成功即有结果，3次错误也返回结果
        [self.context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics localizedReason:result reply:^(BOOL success, NSError *error) {
            if (success) {
                NSLog(@"success");
                //验证成功，主线程处理UI
            } else {
                /// 一直输入错误会停用iPhone的，退出app都没用哒
                NSLog(@"%ld",error.code);
                NSLog(@"验证失败原因：%@",error.localizedDescription);
                switch (error.code) {
                    case LAErrorSystemCancel:
                        /// 系统取消验证：按home键，锁屏键时候，正在验证有弹出验证
                        NSLog(@"Authentication was cancelled by the system");
                        break;
                    case LAErrorUserCancel:
                        //用户取消验证Touch ID
                        NSLog(@"Authentication was cancelled by the user");
                        break;
                    case LAErrorUserFallback:
                        // 输入错一次后，弹出 输入密码 选择项，用户点击该项
                        NSLog(@"User selected to enter custom password");
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            //用户选择输入密码，切换主线程处理
                        }];
                        break;
                    case LAErrorTouchIDLockout:
                        //多次验证失败，被锁，解锁后，再次验证失败
                        NSLog(@"lock");
                        break;
                    default:
                        NSLog(@"others-----");
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            //其他情况，切换主线程处理
                        }];
                        break;
                }
            }
        }];
    } else {
        //不支持指纹识别，LOG出错误详情
        NSLog(@"error code：%ld",error.code);
        switch (error.code) {
            case LAErrorTouchIDNotEnrolled:
                /// 没有设置指纹---
                NSLog(@"TouchID is not enrolled");
                break;
            case LAErrorPasscodeNotSet:
                /// 没启用密码，这样就没启用TouchID（不支持TouchID的设备，会先进入这里，而不会进入下面那个，开启密码才进入下面那个）
                NSLog(@"A passcode has not been set");
                break;
            case LAErrorTouchIDNotAvailable:
                /// 不支持TouchID
                NSLog(@"TouchID not available");
                break;
            case LAErrorTouchIDLockout:
                /// TouchID被锁定
                NSLog(@"lock out TouchID");
                break;
            case LAErrorInvalidContext:
                /// Context无效 调用[context invalidate];后
                NSLog(@"Context invalid");
                break;
            default:
                /// Context为nil时候,or other
                NSLog(@"other");
                break;
        }
        
        NSLog(@"error:%@",error.localizedDescription);
        
    }
}


@end
