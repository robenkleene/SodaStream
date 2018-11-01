//
//  NSTask+TerminationAdditions.m
//  Web Console
//
//  Created by Roben Kleene on 7/20/13.
//  Copyright (c) 2013 Roben Kleene. All rights reserved.
//

#import "NSTask+Termination.h"

#import "SDAConstants.h"

@implementation NSTask (Termination)

- (void)wcl_terminateWithCompletionHandler:(void (^)(BOOL success))completionHandler {
    [self terminateUseInterrupt:NO completionHandler:completionHandler];
}

- (void)wcl_interruptWithCompletionHandler:(void (^)(BOOL success))completionHandler {
    [self terminateUseInterrupt:YES completionHandler:completionHandler];
}

#pragma mark - Private

- (void)terminateUseInterrupt:(BOOL)useInterrupt completionHandler:(void (^)(BOOL success))completionHandler {

    __block BOOL didTerminate = NO;
    __block id observer;
    observer = [[NSNotificationCenter defaultCenter] addObserverForName:NSTaskDidTerminateNotification
                                                                 object:self
                                                                  queue:nil
                                                             usingBlock:^(NSNotification *notification) {
                                                                 NSAssert(![self isRunning], @"The NSTask should not be running.");
                                                                 [[NSNotificationCenter defaultCenter] removeObserver:observer];
                                                                 if (!didTerminate) {
                                                                     didTerminate = YES;
                                                                     completionHandler(YES);
                                                                 }
                                                             }];
    
    double delayInSeconds = kTaskInterruptTimeout;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        if (!didTerminate) {
            [[NSNotificationCenter defaultCenter] removeObserver:observer];
            NSAssert(useInterrupt, @"Terminate should always succeed.");
            NSAssert([self isRunning], @"The NSTask should be running.");
            // `didTermiante` is technically false, but this will help prevent
            // any completion handlers from running more than once
            didTerminate = YES;
            completionHandler(NO);
        }
    });
    
    if (self.isRunning == NO) {
        didTerminate = YES;
        completionHandler(YES);
        return;
    }

    if (useInterrupt) {
        [self interrupt];
    } else {
        [self terminate];
        pid_t pid = [self processIdentifier];
        kill(pid, SIGKILL);
    }
}

@end
