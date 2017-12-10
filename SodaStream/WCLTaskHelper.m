//
//  TaskHelper.m
//  Web Console
//
//  Created by Roben Kleene on 7/20/13.
//  Copyright (c) 2013 Roben Kleene. All rights reserved.
//

#import "WCLTaskHelper.h"
#import "NSTask+Termination.h"

@implementation WCLTaskHelper

+ (void)terminateTask:(nonnull NSTask *)task
    completionHandler:(nullable void (^)(BOOL success))completionHandler
{
    [self terminateTasks:@[task] completionHandler:completionHandler];
}

+ (void)terminateTasks:(nonnull NSArray<NSTask *> *)tasks
     completionHandler:(nullable void (^)(BOOL success))completionHandler
{
    NSMutableArray *mutableTasks = [NSMutableArray arrayWithArray:tasks];
    __block BOOL tasksTerminated = NO;
    
    void (^completionHandlerBlock)() = ^void () {
        if (![mutableTasks count]) {
            tasksTerminated = YES;
            if (completionHandler) {
                completionHandler(YES);
            }

        }
    };

    for (NSTask *task in tasks) {
        [task wcl_interruptWithCompletionHandler:^(BOOL success) {
            if (!success) {
                DLog(@"[Termination] Failed to interrupt a task, trying terminate");
                [task wcl_terminateWithCompletionHandler:^(BOOL success) {
                    NSAssert(success, @"Terminating NSTasks should always succeed.");
                    [mutableTasks removeObject:task];
                    completionHandlerBlock();
                }];
            } else {
                [mutableTasks removeObject:task];
                completionHandlerBlock();
            }
        }];
    }

    double delayInSeconds = kTaskInterruptTimeout * 2;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        if (!tasksTerminated) {
            if (completionHandler) {
                completionHandler(NO);
            }
        }
    });
}

@end
