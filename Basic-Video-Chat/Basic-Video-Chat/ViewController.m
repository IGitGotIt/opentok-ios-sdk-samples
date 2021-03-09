//
//  ViewController.m
//  Hello-World
//
//  Copyright (c) 2013 TokBox, Inc. All rights reserved.
//

#import "ViewController.h"
#import <OpenTok/OpenTok.h>
#import "OTSubscriberOperation.h"

#define MAX_SUBSCRIBERS_COUNT 40
#define PARALLEL_SUBSCRIBERS 2
// *** Fill the following variables using your own Project info  ***
// ***          https://dashboard.tokbox.com/projects            ***
// Replace with your OpenTok API key
static NSString* const kApiKey = @"100";
// Replace with your generated session ID
static NSString* const kSessionId = @"2_MX4xMDB-fjE2MTQ3MjA4NjU2NjN-REdBazFaOHRJUXI3dUdTa2UwVUdqUm5LflB-";
// Replace with your generated token
static NSString* const kToken = @"T1==cGFydG5lcl9pZD0xMDAmc2RrX3ZlcnNpb249dGJwaHAtdjAuOTEuMjAxMS0wNy0wNSZzaWc9NmRkNjE0OGYzODE1NmIzMGNkZGEwOTM3MzJkZDU1NTE2MTA4YTRmNDpzZXNzaW9uX2lkPTJfTVg0eE1EQi1makUyTVRRM01qQTROalUyTmpOLVJFZEJhekZhT0hSSlVYSTNkVWRUYTJVd1ZVZHFVbTVMZmxCLSZjcmVhdGVfdGltZT0xNjE0NzIwODY1JnJvbGU9bW9kZXJhdG9yJm5vbmNlPTE2MTQ3MjA4NjUuNzE1Njk1MjQ5OTczNiZleHBpcmVfdGltZT0xNjE3MzEyODY1";


@interface ViewController ()<OTSessionDelegate, myOTSubscriberKitDelegate, OTPublisherDelegate, OTPublisherKitAudioLevelDelegate>
@property (nonatomic) OTSession *session;
@property (nonatomic) OTPublisher *publisher;
@property (nonatomic, strong) NSOperationQueue * opQueue;
@property (nonatomic, strong) NSMutableDictionary * operations;
@property (nonatomic, strong) NSMutableArray * connectedSubscribers;

@end

@implementation ViewController
static double widgetHeight = 12;
static double widgetWidth = 16;
int count = 0;
int streamCount = 0;

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.operations = [[NSMutableDictionary alloc] initWithCapacity:MAX_SUBSCRIBERS_COUNT];
    self.connectedSubscribers = [[NSMutableArray alloc] init];
    self.opQueue = NSOperationQueue.mainQueue;
    [self.opQueue setMaxConcurrentOperationCount:PARALLEL_SUBSCRIBERS];
    
//    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.2
//         target:[NSBlockOperation blockOperationWithBlock:^{
//        for (OTSubscriber* s in subscriberArray) {
//            s.preferredResolution = CGSizeMake(100, 100);
//        }
//        NSLog(@"preferredResolution set for %lu subscribers", (unsigned long)subscriberArray.count);
//    }]
//          selector:@selector(main)
//          userInfo:nil
//          repeats:YES
//    ];
    // Step 1: As the view comes into the foreground, initialize a new instance
    // of OTSession and begin the connection process.
    _session = [[OTSession alloc] initWithApiKey:kApiKey
                                       sessionId:kSessionId
                                        delegate:self];
    [self doConnect];
}
- (void)publisher:(nonnull OTPublisherKit*)publisher
audioLevelUpdated:(float)audioLevel {
    NSLog(@"audio level is %f", audioLevel);
}


- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (BOOL)shouldAutorotate {
    return UIUserInterfaceIdiomPhone != [[UIDevice currentDevice] userInterfaceIdiom];
}
#pragma mark - OpenTok methods

/** 
 * Asynchronously begins the session connect process. Some time later, we will
 * expect a delegate method to call us back with the results of this action.
 */
- (void)doConnect
{
    OTError *error = nil;
    
    [_session connectWithToken:kToken error:&error];
    if (error)
    {
        [self showAlert:[error localizedDescription]];
    }
}

/**
 * Sets up an instance of OTPublisher to use with this session. OTPubilsher
 * binds to the device camera and microphone, and will provide A/V streams
 * to the OpenTok session.
 */
- (void)doPublish
{
   // return;
    OTPublisherSettings *settings = [[OTPublisherSettings alloc] init];
    settings.name = [UIDevice currentDevice].name;
    _publisher = [[OTPublisher alloc] initWithDelegate:self settings:settings];
    //_publisher.audioLevelDelegate = self;
    OTError *error = nil;
    [_session publish:_publisher error:&error];
    if (error)
    {
        [self showAlert:[error localizedDescription]];
    }
    
    [self.view addSubview:_publisher.view];
    [_publisher.view setFrame:CGRectMake(0, 0, widgetWidth, widgetHeight)];
}

/**
 * Cleans up the publisher and its view. At this point, the publisher should not
 * be attached to the session any more.
 */
- (void)cleanupPublisher {
    [_publisher.view removeFromSuperview];
    _publisher = nil;
    // this is a good place to notify the end-user that publishing has stopped.
}

/**
 * Instantiates a subscriber for the given stream and asynchronously begins the
 * process to begin receiving A/V content for this stream. Unlike doPublish, 
 * this method does not add the subscriber to the view hierarchy. Instead, we 
 * add the subscriber only after it has connected and begins receiving data.
 */



/**
 * Cleans the subscriber from the view hierarchy, if any.
 * NB: You do *not* have to call unsubscribe in your controller in response to
 * a streamDestroyed event. Any subscribers (or the publisher) for a stream will
 * be automatically removed from the session during cleanup of the stream.
 */


# pragma mark - OTSession delegate callbacks

- (void)sessionDidConnect:(OTSession*)session
{
    NSLog(@"sessionDidConnect (%@)", session.sessionId);
    
    // Step 2: We have successfully connected, now instantiate a publisher and
    // begin pushing A/V streams into OpenTok.
    [self doPublish];
}

- (void)sessionDidDisconnect:(OTSession*)session
{
    NSString* alertMessage =
    [NSString stringWithFormat:@"Session disconnected: (%@)",
     session.sessionId];
    NSLog(@"sessionDidDisconnect (%@)", alertMessage);
}


- (void)session:(OTSession*)mySession
  streamCreated:(OTStream *)stream
{
    NSLog(@"session streamCreated (%@) ", stream.streamId );
    if (self.operations.count > MAX_SUBSCRIBERS_COUNT) {
        NSLog(@"Cannot add any more subscribers, limited to %d", MAX_SUBSCRIBERS_COUNT );
        return;
    }

    
    OTSubscriberOperation * op = [[OTSubscriberOperation alloc] initWithSubscriber:stream forSession:_session atCount:++streamCount];
    op.delegate = self;
    
    [self.operations setValue:op forKey:stream.streamId];

   // [self.opQueue addOperation:op];
    

}

- (void)session:(OTSession*)session
streamDestroyed:(OTStream *)stream
{
    NSLog(@"session streamDestroyed (%@)", stream.streamId);
    

}

- (void)  session:(OTSession *)session
connectionCreated:(OTConnection *)connection
{
    NSLog(@"session connectionCreated (%@)", connection.connectionId);
}

- (void)    session:(OTSession *)session
connectionDestroyed:(OTConnection *)connection
{
    NSLog(@"session connectionDestroyed (%@)", connection.connectionId);
 
}

- (void) session:(OTSession*)session
didFailWithError:(OTError*)error
{
    NSLog(@"didFailWithError: (%@)", error);
}

# pragma mark - OTSubscriber delegate callbacks
- (void)doSubscribe:(OTStream*)stream usingOp:(OTSubscriberOperation *) op
{
    NSLog(@"doSubscribe (%@) %lu",
          stream.streamId, (unsigned long)op.countedAt);
    OTSubscriber *  sub = [[OTSubscriber alloc] initWithStream:stream delegate:op.delegate];
    
    OTError *error = nil;
    [_session subscribe:sub error:&error];
    if (error)
    {
        [self showAlert:[error localizedDescription]];
    }
}
- (void)subscriberDidConnectToStream:(OTSubscriberKit*)subscriber
{
    
    
    OTSubscriberOperation * op = [self.operations objectForKey:subscriber.stream.streamId];
    if (op == nil) {
        return;
    }
    NSLog(@"subscriberDidConnectToStream (%@) %lu",
          subscriber.stream.streamId, (unsigned long)op.countedAt);
    OTSubscriber * sub = (OTSubscriber*) subscriber;
    
    [sub.view setFrame:CGRectMake(0, op.countedAt * widgetHeight, widgetWidth,
                                         widgetHeight)];
    [self.view addSubview:sub.view];
    [op tearDown];

    
}

- (void)subscriber:(OTSubscriberKit*)subscriber
  didFailWithError:(OTError*)error
{
//    NSLog(@"subscriber %@ didFailWithError %@",
//          subscriber.stream.streamId,
//          error);
    count++;
    NSLog(@"subscriber didFailWithError (%@) %d",
          subscriber.stream.connection.connectionId, count);
    
}

# pragma mark - OTPublisher delegate callbacks

- (void)publisher:(OTPublisherKit *)publisher
    streamCreated:(OTStream *)stream
{
    NSLog(@"Publishing");

}

- (void)publisher:(OTPublisherKit*)publisher
  streamDestroyed:(OTStream *)stream
{

    
    [self cleanupPublisher];
}

- (void)publisher:(OTPublisherKit*)publisher
 didFailWithError:(OTError*) error
{
    NSLog(@"publisher didFailWithError %@", error);
    [self cleanupPublisher];
}

- (void)showAlert:(NSString *)string
{
    // show alertview on main UI
	dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"OTError"
                                                                         message:string
                                                                  preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alertVC animated:YES completion:nil];
    });
}

@end
