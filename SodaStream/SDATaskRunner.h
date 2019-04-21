//
//  SDATaskRunner.h
//  Web Console
//
//  Created by Roben Kleene on 1/11/14.
//  Copyright (c) 2014 Roben Kleene. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SDATaskRunner;

NS_ASSUME_NONNULL_BEGIN
@protocol SDATaskRunnerDelegate <NSObject>
@optional
#pragma mark Starting & Finishing Tasks
- (void)taskWillStart:(NSTask *)task;
- (void)taskDidFinish:(NSTask *)task;
- (void)task:(NSTask *)task didFailToRunCommandPath:(NSString *)commandPath error:(NSError *)error;
#pragma mark Events
- (void)task:(NSTask *)task didReadFromStandardError:(NSString *)text;
- (void)task:(NSTask *)task didReadFromStandardOutput:(NSString *)text;
- (void)task:(NSTask *)task
    didRunCommandPath:(NSString *)commandPath
            arguments:(nullable NSArray<NSString *> *)arguments
        directoryPath:(nullable NSString *)directoryPath;
@end
NS_ASSUME_NONNULL_END

NS_ASSUME_NONNULL_BEGIN
@interface SDATaskRunner : NSObject
+ (NSTask *)runTaskWithCommandPath:(NSString *)commandPath
                     withArguments:(nullable NSArray<NSString *> *)arguments
                   inDirectoryPath:(nullable NSString *)directoryPath
                   withEnvironment:(nullable NSDictionary<NSString *, NSString *> *)environmentDictionary
                          delegate:(nullable id<SDATaskRunnerDelegate>)delegate
                 completionHandler:(nullable void (^)(BOOL success))completionHandler;
@end
NS_ASSUME_NONNULL_END
