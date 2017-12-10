//
//  NSTask+TerminationAdditions.h
//  Web Console
//
//  Created by Roben Kleene on 7/20/13.
//  Copyright (c) 2013 Roben Kleene. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface NSTask (Termination)
/*! Sends an interrupt signal to the receiver and all of its subtasks and executes a handler block when it terminates or after a timeout.
 * \param completionHandler A handler block execute.
 */
- (void)wcl_interruptWithCompletionHandler:(nullable void (^)(BOOL success))completionHandler;
/*! Sends an terminate signal to the receiver and all of its subtasks and executes a handler block when it terminates or after a timeout.
 * \param completionHandler A handler block execute.
 */
- (void)wcl_terminateWithCompletionHandler:(nullable void (^)(BOOL success))completionHandler;
@end
NS_ASSUME_NONNULL_END
