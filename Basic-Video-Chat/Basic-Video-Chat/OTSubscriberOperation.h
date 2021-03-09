//
//  OTSubscriberOperation.h
//  Basic-Video-Chat
//
//  Created by Jaideep Shah on 3/8/21.
//  Copyright © 2021 TokBox, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenTok/OpenTok.h>
#import "ViewController.h"

@protocol myOTSubscriberKitDelegate;

@interface OTSubscriberOperation : NSOperation

-(id) initWithSubscriber:(OTStream*) s forSession: (OTSession*) session  atCount:(NSInteger) c;

@property (nonatomic,strong) OTSubscriber *subscriber;
@property(nonatomic,strong)  id <myOTSubscriberKitDelegate> delegate;
@property NSUInteger countedAt;
-(void) tearDown;
@end
