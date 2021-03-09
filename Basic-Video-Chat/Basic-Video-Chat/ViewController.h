//
//  ViewController.h
//  Hello-World
//
//  Copyright (c) 2013 TokBox, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenTok/OpenTok.h>
#import "OTSubscriberOperation.h"
@class OTSubscriberOperation;

@interface ViewController : UIViewController

@end
@protocol myOTSubscriberKitDelegate <OTSubscriberKitDelegate>

- (void)doSubscribe:(OTStream*)stream usingOp:(OTSubscriberOperation *) op;

@end
