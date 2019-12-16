//
//  SDATaskRunner.m
//  Web Console
//
//  Created by Roben Kleene on 1/11/14.
//  Copyright (c) 2014 Roben Kleene. All rights reserved.
//

#import "SDATaskRunner.h"
#import <SodaStream/SodaStream-Swift.h>
@import os.log;
#import "SDAConstants.h"

@implementation SDATaskRunner

+ (NSTask *)runTaskWithCommandPath:(NSString *)commandPath
                     withArguments:(nullable NSArray<NSString *> *)arguments
                   inDirectoryPath:(nullable NSString *)directoryPath
                   withEnvironment:(nullable NSDictionary<NSString *, NSString *> *)environmentDictionary
                          delegate:(nullable id<SDATaskRunnerDelegate>)delegate
                 completionHandler:(nullable void (^)(BOOL success, NSTask *task))completionHandler {
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = commandPath;

    if (arguments) {
        task.arguments = arguments;
    }

    if (directoryPath) {
        // TODO: Add test that the directory path is valid, log a message if debug is on and it's not valid
        // Also return and do nothing in this case, remember to fire the completion handler
        task.currentDirectoryPath = directoryPath;
    }

    if (environmentDictionary) {
        [task setEnvironment:environmentDictionary];
    }


    __weak NSTask *weakTask = task;
    __weak id <SDATaskRunnerDelegate> weakDelegate = delegate;
    __block BOOL standardErrorFinished = NO;
    __block BOOL standardOutputFinished = NO;
    
    // Standard Output
    task.standardOutput = [NSPipe pipe];
    [[task.standardOutput fileHandleForReading] setReadabilityHandler:^(NSFileHandle *file) {
        NSTask *strongTask = weakTask;
        if (!strongTask) {
            return;
        }

        NSData *data = [file availableData];
        if (!data.bytes) {
            if (!task.isRunning) {
                if (standardErrorFinished && !standardOutputFinished) {
                    if ([delegate respondsToSelector:@selector(taskDidFinishStandardOutputAndStandardError:)]) {
                        [delegate taskDidFinishStandardOutputAndStandardError:task];
                    }
                }
                standardOutputFinished = YES;
            }
            return;
        }
        NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        os_log_info(logHandle, "Task did print to standard output, %@, %i %@", text, task.processIdentifier,
                task.launchPath);
        [self processStandardOutput:text task:task delegate:delegate];
    }];

    // Standard Error
    task.standardError = [NSPipe pipe];
    [[task.standardError fileHandleForReading] setReadabilityHandler:^(NSFileHandle *file) {
        NSTask *strongTask = weakTask;
        if (!strongTask) {
            return;
        }

        NSData *data = [file availableData];
        if (!data.bytes) {
            if (!task.isRunning) {
                if (standardOutputFinished && !standardErrorFinished) {
                    if ([delegate respondsToSelector:@selector(taskDidFinishStandardOutputAndStandardError:)]) {
                        [delegate taskDidFinishStandardOutputAndStandardError:task];
                    }
                }
                standardErrorFinished = YES;
            }
            return;
        }
        NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        os_log_error(logHandle, "Task did print to standard error, %@, %i %@", text, task.processIdentifier,
                task.launchPath);
        [self processStandardError:text task:task delegate:delegate];
    }];

    // Standard Input
    [task setStandardInput:[NSPipe pipe]];

    // Termination handler
    [task setTerminationHandler:^(NSTask *task) {
        NSTask *strongTask = weakTask;
        if (!strongTask) {
            return;
        }
        
        os_log_info(logHandle, "Task did terminate, %i %@", strongTask.processIdentifier, strongTask.launchPath);

        if ([weakDelegate respondsToSelector:@selector(taskDidFinish:)]) {
            [weakDelegate taskDidFinish:strongTask];
        }

        // As per NSTask.h, NSTaskDidTerminateNotification is not posted if a termination handler is set, so post it
        // here.
        [[NSNotificationCenter defaultCenter] postNotificationName:NSTaskDidTerminateNotification object:strongTask];
    }];

    if ([delegate respondsToSelector:@selector(taskWillStart:)]) {
        // The plugin task delegate must be informed before calculating
        // the environment dictionary in order to assure that the
        // correct window number is returned.
        [delegate taskWillStart:task];
    }

    BOOL success = NO;
    NSError *error;
    NSString *launchPath = [task launchPath];
    if ([[NSFileManager defaultManager] isExecutableFileAtPath:launchPath]) {
        @try {
            [task launch];

            success = YES;
        } @catch (NSException *exception) {
            error = [NSError commandPathExceptionErrorWithLaunchPath:launchPath];
            if (completionHandler) {
                completionHandler(NO, nil);
            }
        }
    } else {
        error = [NSError commandPathUnexecutableErrorWithLaunchPath:launchPath];
    }

    if (success) {
        if ([delegate respondsToSelector:@selector(task:didRunCommandPath:arguments:directoryPath:withEnvironment:)]) {
            [delegate task:task
                didRunCommandPath:commandPath
                        arguments:arguments
                    directoryPath:directoryPath
                  withEnvironment:environmentDictionary];
        }
    } else {
        if (error == nil) {
            error = [NSError commandPathUnkownErrorWithLaunchPath:launchPath];
        }

        if ([delegate respondsToSelector:@selector(task:
                                             didFailToRunCommandPath:arguments:directoryPath:withEnvironment:error:)]) {
            [delegate task:task
                didFailToRunCommandPath:launchPath
                              arguments:arguments
                          directoryPath:directoryPath
                        withEnvironment:environmentDictionary
                                  error:error];
        }
    }

    NSLog(@"%s Run completion for task %i", __PRETTY_FUNCTION__, task.processIdentifier);
    if (completionHandler) {
        completionHandler(success, task);
    }

    return task;
}

+ (void)processStandardOutput:(NSString *)text task:(NSTask *)task delegate:(id<SDATaskRunnerDelegate>)delegate {
    if ([delegate respondsToSelector:@selector(task:didReadFromStandardOutput:)]) {
        [delegate task:task didReadFromStandardOutput:text];
    }
}

+ (void)processStandardError:(NSString *)text task:(NSTask *)task delegate:(id<SDATaskRunnerDelegate>)delegate {
    if ([delegate respondsToSelector:@selector(task:didReadFromStandardError:)]) {
        [delegate task:task didReadFromStandardError:text];
    }
}

@end
