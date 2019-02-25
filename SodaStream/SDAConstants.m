//
//  SDAConstants.m
//  SodaStream
//
//  Created by Roben Kleene on 11/5/18.
//  Copyright © 2018 Roben Kleene. All rights reserved.
//

#import "SDAConstants.h"
#import "SDATaskRunner.h"

os_log_t logHandle;

@interface SDATaskRunner (Log)
@end

@implementation SDATaskRunner (Log)

+ (void)initialize {
    if (!logHandle) {
        logHandle = os_log_create("com.1percenter.SodaStream", "General");
    }
}

@end
