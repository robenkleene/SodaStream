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
                 completionHandler:(nullable void (^)(BOOL success))completionHandler {
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


    // A dispatch group is used to assure that all output gets read from
    // standard output and error fter the task terminates
    dispatch_group_t group = dispatch_group_create();

    // Standard Output
    dispatch_group_enter(group);
    task.standardOutput = [NSPipe pipe];
    [[task.standardOutput fileHandleForReading] setReadabilityHandler:^(NSFileHandle *file) {
        NSData *data = [file availableData];
        if (!data.bytes) {
            NSLog(@"%s LEAVE", __PRETTY_FUNCTION__);
            dispatch_group_leave(group);
            return;
        }
        NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        os_log_info(logHandle, "Task did print to standard output, %@, %i %@", text, task.processIdentifier,
                    task.launchPath);
        [self processStandardOutput:text task:task delegate:delegate];
    }];

    // Standard Error
    dispatch_group_enter(group);
    task.standardError = [NSPipe pipe];
    [[task.standardError fileHandleForReading] setReadabilityHandler:^(NSFileHandle *file) {
        NSData *data = [file availableData];
        if (!data.bytes) {
            NSLog(@"%s LEAVE", __PRETTY_FUNCTION__);
            dispatch_group_leave(group);
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
        os_log_info(logHandle, "Task did terminate, %i %@", task.processIdentifier, task.launchPath);

        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);

        [[task.standardOutput fileHandleForReading] setReadabilityHandler:nil];
        [[task.standardError fileHandleForReading] setReadabilityHandler:nil];

        if ([delegate respondsToSelector:@selector(taskDidFinish:)]) {
            [delegate taskDidFinish:task];
        }

        // As per NSTask.h, NSTaskDidTerminateNotification is not posted if a termination handler is set, so post it
        // here.
        [[NSNotificationCenter defaultCenter] postNotificationName:NSTaskDidTerminateNotification object:task];
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
                completionHandler(NO);
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

    if (completionHandler) {
        completionHandler(success);
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
