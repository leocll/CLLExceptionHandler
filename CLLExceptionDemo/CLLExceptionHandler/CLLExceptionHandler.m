//
//  CLLExceptionHandler.m
//  CLLExceptionDemo
//
//  Created by leocll on 2018/8/18.
//  Copyright © 2018年 leocll. All rights reserved.
//

#import "CLLExceptionHandler.h"
#include <libkern/OSAtomic.h>
#include <execinfo.h>

#pragma mark - 异常处理回调
void CLLUncaughtExceptionHandler(NSException *exception);
#pragma mark - 信号处理回调
void CLLSignalHandler(int signal);
#pragma mark - 堆栈回溯
NSArray * CLLBacktrace(void);

@interface CLLExceptionHandler ()
/**代理*/
@property (nonatomic, strong) NSMutableArray <id<CLLExceptionHandlerDelegate>>*delegates;
@end

@implementation CLLExceptionHandler

#pragma mark - 单例
static CLLExceptionHandler *exceptionHandler = nil;
+ (instancetype)sharedHandler {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        exceptionHandler = [[self alloc] init];
    });
    return exceptionHandler;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        exceptionHandler = [super allocWithZone:zone];
        exceptionHandler.delegates = [NSMutableArray array];
        exceptionHandler.crash = YES;
    });
    return exceptionHandler;
}

- (id)copy {
    return exceptionHandler;
}

- (id)mutableCopy {
    return exceptionHandler;
}

#pragma mark - 异常处理
- (void)handleException:(NSException *)exception {
    [self.delegates enumerateObjectsUsingBlock:^(id<CLLExceptionHandlerDelegate>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(cll_handleException:)]) {
            [obj cll_handleException:exception];
        }
    }];
    if (!self.crash) {
        CFRunLoopRef runLoop = CFRunLoopGetCurrent();
        CFArrayRef modes = CFRunLoopCopyAllModes(runLoop);
        while (true) {
            for (NSString *mode in (__bridge NSArray *)modes) {
                CFRunLoopRunInMode((CFRunLoopMode)mode, 0.001, true);
            }
        }
//        CFRelease(modes);
    }
}

#pragma mark - setter
- (void)setEnabled:(BOOL)enabled {
    if (_enabled == enabled) {return;}
    _enabled = enabled;
    if (enabled) {
        [[self class] install];
    } else {
        [[self class] uninstall];
    }
}

#pragma mark - 立即崩溃
- (void)killProcess {
    kill(getpid(), SIGKILL);
}

#pragma mark - 添加代理
- (void)addDelegate:(id<CLLExceptionHandlerDelegate>)delegate {
    [self.delegates addObject:delegate];
}

#pragma mark - 移除代理
- (void)removeDelegate:(id<CLLExceptionHandlerDelegate>)delegate {
    [self.delegates removeObject:delegate];
}

#pragma mark - 启用
+ (void)install {
    NSSetUncaughtExceptionHandler(&CLLUncaughtExceptionHandler);
    signal(SIGABRT, CLLSignalHandler);
    signal(SIGILL, CLLSignalHandler);
    signal(SIGSEGV, CLLSignalHandler);
    signal(SIGFPE, CLLSignalHandler);
    signal(SIGBUS, CLLSignalHandler);
    signal(SIGPIPE, CLLSignalHandler);
}

#pragma mark - 停用
+ (void)uninstall {
    NSSetUncaughtExceptionHandler(NULL);
    signal(SIGABRT, SIG_DFL);
    signal(SIGILL, SIG_DFL);
    signal(SIGSEGV, SIG_DFL);
    signal(SIGFPE, SIG_DFL);
    signal(SIGBUS, SIG_DFL);
    signal(SIGPIPE, SIG_DFL);
}

@end

#pragma mark - 堆栈回溯
NSArray * CLLBacktrace(void) {
    static const NSInteger CLLExceptionHandlerSkipAddressCount = 4;
    static const NSInteger CLLExceptionHandlerReportAddressCount = 5;
    
    void *callstack[128];
    int frames = backtrace(callstack, 128);
    char **strs = backtrace_symbols(callstack, frames);
    int i;
    NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frames];
    for (i = CLLExceptionHandlerSkipAddressCount;i < CLLExceptionHandlerSkipAddressCount+CLLExceptionHandlerReportAddressCount;i++) {
        [backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
    }
    free(strs);
    return backtrace;
}

#pragma mark - 异常处理回调
void CLLUncaughtExceptionHandler(NSException *exception) {
    [[CLLExceptionHandler sharedHandler] performSelectorOnMainThread:@selector(handleException:) withObject:exception waitUntilDone:YES];
}

#pragma mark - 信号处理回调
void CLLSignalHandler(int signal) {
    static NSString * const CLLExceptionHandlerSignalExceptionName = @"UncaughtExceptionHandlerSignalExceptionName";
    static NSString * const CLLExceptionHandlerSignalKey = @"UncaughtExceptionHandlerSignalKey";
    static NSString * const CLLExceptionHandlerAddressesKey = @"UncaughtExceptionHandlerAddressesKey";
    static volatile int32_t CLLUncaughtExceptionCount = 0;
    static const int32_t CLLUncaughtExceptionMaximum = 10;
    
    int32_t exceptionCount = OSAtomicIncrement32(&CLLUncaughtExceptionCount);
    if (exceptionCount > CLLUncaughtExceptionMaximum) {
        return;
    }
    NSArray *callStack = CLLBacktrace();
    NSMutableDictionary *userInfo = @{CLLExceptionHandlerSignalKey:@(signal)}.mutableCopy;
    userInfo[CLLExceptionHandlerAddressesKey] = callStack;
    [[CLLExceptionHandler sharedHandler] performSelectorOnMainThread:@selector(handleException:) withObject:[NSException exceptionWithName:CLLExceptionHandlerSignalExceptionName reason:[NSString stringWithFormat:@"Signal %d was raised.", signal] userInfo:userInfo] waitUntilDone:YES];
}

