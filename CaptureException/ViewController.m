//
//  ViewController.m
//  CaptureException
//
//  Created by yunshan on 2019/1/11.
//  Copyright © 2019 ChenZhe. All rights reserved.
//

#import "ViewController.h"
#import "HHZCaptureException.h"

@interface ViewController ()<HHZCaptureExceptionDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [[HHZCaptureException shareManager] startMonitorWithDelegate:self];
    
    HHZCaptureException * ccc = [[HHZCaptureException alloc] init];
    [ccc startMonitorWithDelegate:self];
    
    UIButton * btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:@"测试" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(test) forControlEvents:UIControlEventTouchUpInside];
    btn.frame = CGRectMake(50, 100, 100, 30);
    [self.view addSubview:btn];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSArray * arr = @[];
        NSString * str = arr[2];
        NSLog(@"%@",str);
    });
    [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
        NSLog(@"........");
    }];
}

-(void)test
{
    NSLog(@"cccccc");
    NSArray * arr = @[];
    NSString * str = arr[2];
    NSLog(@"%@",str);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
    });
}

@end
