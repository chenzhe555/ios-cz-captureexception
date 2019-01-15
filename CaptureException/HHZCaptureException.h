//
//  HHZCaptureException.h
//  CaptureException
//
//  Created by 陈哲是个好孩子 on 2019/1/11.
//  Copyright © 2019 ChenZhe. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HHZCaptureExceptionDelegate <NSObject>
@required
-(void)dlApplicationError:(NSException *)exception;
@end

@interface HHZCaptureException : NSObject

/**
 获取单例
 */
+(instancetype)shareManager;

/**
 开始监听
 */
-(void)startMonitorWithDelegate:(id<HHZCaptureExceptionDelegate>)delegate;

/**
 获取Exception的堆栈信息
 */
+(NSArray *)getBacktraceWithException:(NSException *)exception;


/**
 处理异常数据
 */
-(void)handleException:(NSException *)exception;


/**
 强制退出
 */
-(void)forceExit;
@end

NS_ASSUME_NONNULL_END
