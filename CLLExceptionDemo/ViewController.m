//
//  ViewController.m
//  CLLExceptionDemo
//
//  Created by leocll on 2018/8/18.
//  Copyright © 2018年 leocll. All rights reserved.
//

#import "ViewController.h"
#import "CLLExceptionHandler.h"

@interface ViewController ()<CLLExceptionHandlerDelegate>
@property (weak, nonatomic) IBOutlet UITextView *logTv;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [CLLExceptionHandler sharedHandler].enabled = YES;
    [[CLLExceptionHandler sharedHandler] addDelegate:self];
}

- (IBAction)touchesIsCrash:(UIButton *)sender {
    sender.selected = !sender.selected;
    [CLLExceptionHandler sharedHandler].crash = sender.selected;
}

- (IBAction)touchesCrashImmediately:(UIButton *)sender {
    [[CLLExceptionHandler sharedHandler] killProcess];
}

- (IBAction)touchesException:(UIButton *)sender {
    [@[] objectAtIndex:2];
}

- (IBAction)touchesSignal:(UIButton *)sender {
    
}

- (void)cll_handleException:(NSException *)exception {
    // 异常处理，比如：保存异常或上传服务器
    self.logTv.text = [NSString stringWithFormat:@"%@\n%@\n%@\n追加\n追加\n追加\n追加\n追加",exception.name,exception.reason,exception.userInfo];
}

- (void)dealloc {
    [[CLLExceptionHandler sharedHandler] removeDelegate:self];
}

@end
