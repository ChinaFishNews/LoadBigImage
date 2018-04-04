//
//  ViewController.m
//  LoadBigImage
//
//  Created by 新闻 on 2018/4/3.
//  Copyright © 2018年 Lvmama. All rights reserved.
//

#import "ViewController.h"

static NSString *IDENTIFIER = @"IDENTIFIER";

typedef BOOL(^RunloopBlock)(void);

@interface ViewController ()

/** 存放任务的数组 */
@property(nonatomic,strong)NSMutableArray * tasks;
/** 任务标记 */
@property(nonatomic,strong)NSMutableArray * tasksKeys;
/** 最大任务数 */
@property(assign,nonatomic)NSUInteger max;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tasks = @[].mutableCopy;
    self.tasksKeys = @[].mutableCopy;
    // 要超出至少一屏显示的数量
    self.max = 100;
    // 用来唤醒runLoop
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerMethod) userInfo:nil repeats:YES];
    
    [self addRunLoopObserver];
}

- (void)timerMethod {}

#pragma mark - UITableViewDelegate, UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 100;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:IDENTIFIER];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:IDENTIFIER];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    for (NSInteger i = 0; i < 3; i++) {
        [[cell.contentView viewWithTag:100 + i] removeFromSuperview];
    }
    for (NSInteger i = 0; i < 3; i++) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(100 * i, 7, 85, 85)];
        imageView.tag = 100 + i;
        imageView.contentMode = UIViewContentModeScaleToFill;
        [self addTask:^BOOL{
            NSString *path = [[NSBundle mainBundle] pathForResource:@"spaceship" ofType:@"png"];
            UIImage *image = [UIImage imageWithContentsOfFile:path];
            imageView.image = image;
            [UIView transitionWithView:cell.contentView duration:0.3 options:(UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionCrossDissolve) animations:^{
                [cell.contentView addSubview:imageView];
            } completion:nil];
            return YES;
        } key:indexPath];
    }
    
    return cell;
}

#pragma mark - RunLoop
// 添加监听者
- (void)addRunLoopObserver {
    // 获取当前runloop
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    // 定义context
    CFRunLoopObserverContext context = {
        0,
        (__bridge void *)(self),
        &CFRetain,
        &CFRelease,
        NULL
    };
    // 定义一个观察者
    static CFRunLoopObserverRef defaultModeObserver;
    defaultModeObserver = CFRunLoopObserverCreate(NULL,
                                                  kCFRunLoopBeforeWaiting,
                                                  YES,
                                                  NSIntegerMax - 999,
                                                  &callback,
                                                  &context);
    CFRunLoopAddObserver(runLoop, defaultModeObserver, kCFRunLoopDefaultMode);
    CFRelease(defaultModeObserver);
}

// 回调函数
static void callback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info){
    ViewController *vc = (__bridge ViewController *)(info);
    if (vc.tasks.count == 0) {
        return;
    }
    BOOL result = NO;
    if (!result && vc.tasks.count > 0) {
        RunloopBlock block = vc.tasks[0];
        result = block();
        [vc.tasks removeObjectAtIndex:0];
        [vc.tasksKeys removeObjectAtIndex:0];
    }
}

// 添加任务
- (void)addTask:(RunloopBlock)block key:(id)key {
    [self.tasks addObject:block];
    [self.tasksKeys addObject:key];
    // 超出最大处理数则从数组中移移除
    if (self.tasks.count > self.max) {
        [self.tasks removeObjectAtIndex:0];
        [self.tasksKeys removeObjectAtIndex:0];
    }
}

@end
