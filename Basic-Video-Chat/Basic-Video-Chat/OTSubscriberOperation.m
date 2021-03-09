//
//  OTSubscriberOperation.m
//  Basic-Video-Chat
//
//  Created by Jaideep Shah on 3/8/21.
//  Copyright © 2021 TokBox, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenTok/OpenTok.h>
#import "OTSubscriberOperation.h"
#import "ViewController.h"
@interface OTSubscriberOperation ()

@property (nonatomic) OTStream *stream;
@property(nonatomic,strong) OTSession * session;
@property BOOL finished;
@property BOOL executing;
@end

@implementation OTSubscriberOperation
@synthesize finished;
@synthesize executing;

-(id) init
{
    [NSException exceptionWithName:@"Invalid init call" reason:@"Use initWithSubscriber:countedAt" userInfo:nil];
    return  nil;
}
-(id) initWithSubscriber:(OTStream*) s forSession: (OTSession*) session  atCount:(NSInteger) c

{
    self = [super init];
    if(self != nil && s != nil && c > 0)
    {
        self.countedAt = c;
        self.stream = s;
        self.finished = NO;
        self.executing = NO;
     
        
    }
    return self;
}

- (void) start {
    self.executing = YES;
    NSLog(@"NSOP started %@", self.stream.streamId);
    [self.delegate doSubscribe:self.stream usingOp:self];
   
}
- (BOOL) isConcurrent{
    return YES;
}
- (BOOL) isFinished{
   /* Simply return the value */
    return(self.finished);
}
- (BOOL) isExecuting{
    /* Simply return the value */
    return(self.executing);
}

- (void) tearDown
{

    self.finished = YES;
    self.executing = NO;
}

@end
