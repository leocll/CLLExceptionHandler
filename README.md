# CLLExceptionHandler


#### 主类```CLLExceptionHandler```，接口
```
/**是否启用，默认NO*/
@property (nonatomic, assign, getter=isEnabled) BOOL enabled;
/**出现异常后是否crash，默认YES，当出现异常后，若让程序继续运行，程序性能会大不如异常之前*/
@property (nonatomic, assign, getter=isCrash) BOOL crash;
/**
单例
*/
+ (instancetype)sharedHandler;
/**
杀进程
*/
- (void)killProcess;
/**
添加代理
*/
- (void)addDelegate:(id<CLLExceptionHandlerDelegate>)delegate;
/**
移除代理
*/
- (void)removeDelegate:(id<CLLExceptionHandlerDelegate>)delegate;
```

#### 协议```CLLExceptionHandlerDelegate```
```
/**
异常的处理
*/
- (void)cll_handleException:(NSException *)exception;
```
