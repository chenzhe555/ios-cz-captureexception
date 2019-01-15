//
//  HHZCaptureException.m
//  CaptureException
//
//  Created by 陈哲是个好孩子 on 2019/1/11.
//  Copyright © 2019 ChenZhe. All rights reserved.
//

#import "HHZCaptureException.h"
#include <libkern/OSAtomic.h>
#include <execinfo.h>

//SIGNAL错误的异常Name
NSString * const UncaughtExceptionHandlerSignalExceptionName = @"UncaughtExceptionHandlerSignalExceptionName";
//SIGNAL错误的值对应的Key
NSString * const UncaughtExceptionHandlerSignalKey = @"UncaughtExceptionHandlerSignalKey";

volatile int32_t UncaughtExceptionCount = 0;
//最大错误失败执行次数
const int32_t UncaughtExceptionMaxCount = 12;

/**
 Exception 异常处理
 */
void exceptionHandler(NSException *exception) {
    //递增一个全局计数器，OSAtomicIncrement32 防止高并发情况下递增出现异常
    int32_t exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount);
    if (exceptionCount > UncaughtExceptionMaxCount)
    {
        return;
    }
    NSArray * tracesArr = [HHZCaptureException getBacktraceWithException:exception];
    
    //保存崩溃信息
    NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithDictionary:exception.userInfo];
    [dic setObject:tracesArr forKey:@"traces"];
    
    [[HHZCaptureException shareManager] performSelectorOnMainThread:@selector(handleException:) withObject:[NSException exceptionWithName:exception.name reason:exception.reason userInfo:dic] waitUntilDone:YES];
}

/**
 信号量 异常处理
 */
void signalHandler(int signal) {
    exceptionHandler([NSException exceptionWithName:UncaughtExceptionHandlerSignalExceptionName reason:[NSString stringWithFormat:@"signal(%d) Error!",signal] userInfo:@{UncaughtExceptionHandlerSignalKey: @(signal)}]);
}

@interface HHZCaptureException ()
@property (nonatomic, weak) id<HHZCaptureExceptionDelegate> delegate;
@property (nonatomic, assign) BOOL isExit;
@end

@implementation HHZCaptureException
+(instancetype)shareManager
{
    static HHZCaptureException * exception = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        exception = [[HHZCaptureException alloc] init];
    });
    return exception;
}

-(void)startMonitorWithDelegate:(id<HHZCaptureExceptionDelegate>)delegate
{
    self.delegate = delegate;
    
    //Exception 异常处理
    NSSetUncaughtExceptionHandler(&exceptionHandler);
    
    //SIGNAL 异常处理
    //注册程序由于abort()函数调用发生的程序中止信号
    signal(SIGABRT, &signalHandler);
    //注册程序由于非法指令产生的程序中止信号
    signal(SIGILL, &signalHandler);
    //注册程序由于无效内存的引用导致的程序中止信号
    signal(SIGSEGV, &signalHandler);
    //注册程序由于浮点数异常导致的程序中止信号
    signal(SIGFPE, &signalHandler);
    //注册程序由于内存地址未对齐导致的程序中止信号
    signal(SIGBUS, &signalHandler);
    //程序通过端口发送消息失败导致的程序中止信号
    signal(SIGPIPE, &signalHandler);
}

/**
 获取堆栈信息
 */
+(NSArray *)getBacktraceWithException:(NSException *)exception
{
    //获取所有调用栈地址
    NSArray * addresses = exception.callStackReturnAddresses;
    unsigned count = (int)addresses.count;
    void **stack = malloc(count * sizeof(void *));
    
    for (unsigned i = 0; i < count; ++i)
    {
        stack[i] = (void *)[addresses[i] longValue];
    }
    
    //获取对应栈信息
    char ** strings = (char **)backtrace_symbols(stack, count);
    NSMutableArray * arr = [NSMutableArray arrayWithCapacity:count];
    
    count = count >= 100 ? 100 : count;
    for (int i = 0; i < count; ++i)
    {
        [arr addObject:@(strings[i])];
    }
    
    //释放内存
    free(stack);
    free(strings);
    return arr;
}

-(void)handleException:(NSException *)exception
{
    //启动一个Runloop，保证App不闪退
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFArrayRef allModes = CFRunLoopCopyAllModes(runLoop);
    
    //如果不执行回调函数，默认退出
    if (_delegate && [_delegate respondsToSelector:@selector(dlApplicationError:)]) {
        self.isExit = NO;
        [_delegate dlApplicationError:exception];
    } else {
        self.isExit = YES;
    }
    
    while (!self.isExit) {
        for (NSString *mode in (__bridge NSArray *)allModes) {
            CFRunLoopRunInMode((CFStringRef)mode, 0.001, false);
        }
    }
    
    //正常退出App
    CFRelease(allModes);
    NSSetUncaughtExceptionHandler(NULL);
    signal(SIGABRT, SIG_DFL);
    signal(SIGILL, SIG_DFL);
    signal(SIGSEGV, SIG_DFL);
    signal(SIGFPE, SIG_DFL);
    signal(SIGBUS, SIG_DFL);
    signal(SIGPIPE, SIG_DFL);
    
    if ([[exception name] isEqual:UncaughtExceptionHandlerSignalExceptionName])
    {
        kill(getpid(), [[[exception userInfo] objectForKey:UncaughtExceptionHandlerSignalKey] intValue]);
    }
    else
    {
        [exception raise];
    }
}

-(void)forceExit
{
    self.isExit = YES;
}
@end
