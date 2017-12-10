//
//  WCLTaskRunner.h
//  Web Console
//
//  Created by Roben Kleene on 1/11/14.
//  Copyright (c) 2014 Roben Kleene. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WCLTaskRunner;

NS_ASSUME_NONNULL_BEGIN
@protocol WCLTaskRunnerDelegate <NSObject>
@optional
#pragma mark Starting & Finishing Tasks
- (void)taskWillStart:(NSTask *)task;
- (void)taskDidFinish:(NSTask *)task;
- (void)task:(NSTask *)task didFailToRunCommandPath:(NSString *)commandPath
             error:(NSError *)error;
#pragma mark Events
- (void)task:(NSTask *)task didReadFromStandardError:(NSString *)text;
- (void)task:(NSTask *)task didReadFromStandardOutput:(NSString *)text;
- (void)task:(NSTask *)task didRunCommandPath:(NSString *)commandPath
         arguments:(nullable NSArray<NSString *> *)arguments
     directoryPath:(nullable NSString *)directoryPath;
#pragma mark Data Source
- (nullable NSDictionary *)environmentDictionaryForPluginTask:(NSTask *)task;
@end
NS_ASSUME_NONNULL_END


NS_ASSUME_NONNULL_BEGIN
@interface WCLTaskRunner : NSObject
+ (NSTask *)runTaskWithCommandPath:(NSString *)commandPath
                     withArguments:(nullable NSArray *)arguments
                   inDirectoryPath:(nullable NSString *)directoryPath
                          delegate:(nullable id<WCLTaskRunnerDelegate>)delegate
                 completionHandler:(nullable void (^)(BOOL success))completionHandler;
@end
NS_ASSUME_NONNULL_END
