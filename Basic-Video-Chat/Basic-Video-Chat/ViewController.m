//
//  ViewController.m
//  Hello-World
//
//  Copyright (c) 2013 TokBox, Inc. All rights reserved.
//

#import "ViewController.h"
#import <OpenTok/OpenTok.h>

static NSString* const kApiKey = @"100";
// Replace with your generated session ID
static NSString* const kSessionId = @"2_MX4xMDB-fjE2MTU0MTU0NzQ3OTh-aG1WTUViOW5mVnd0TGh6K3NhekoxWDRYfn4";
// Replace with your generated token
static NSString* const kToken = @"T1==cGFydG5lcl9pZD0xMDAmc2RrX3ZlcnNpb249dGJwaHAtdjAuOTEuMjAxMS0wNy0wNSZzaWc9MGVjOTZiMDhkOGExYzYwZjM3NWYyZDVkNDdjNjE3YmZhNTA5MWQyNjpzZXNzaW9uX2lkPTJfTVg0eE1EQi1makUyTVRVME1UVTBOelEzT1RoLWFHMVdUVVZpT1c1bVZuZDBUR2g2SzNOaGVrb3hXRFJZZm40JmNyZWF0ZV90aW1lPTE2MTU0MTU0NzQmcm9sZT1tb2RlcmF0b3Imbm9uY2U9MTYxNTQxNTQ3NC45MTYzNDc0OTg4MTMzJmV4cGlyZV90aW1lPTE2MTgwMDc0NzQ=";

#define SUBSCRIBERS_IN_PARALLEL 1
#define IDLE_TIME_OUT_COUNT 3
NSMutableArray * streams;
NSMutableArray * subscribersConnected;
int subConnected = 0;
bool fNextBatch = false;
NSTimer *timer2;
int idleTimerCount = 0;

@interface ViewController ()<OTSessionDelegate, OTSubscriberDelegate, OTPublisherDelegate, OTPublisherKitAudioLevelDelegate>
@property (nonatomic) OTSession *session;
@property (nonatomic) OTPublisher *publisher;
@property (nonatomic) OTSubscriber *subscriber;
@end

@implementation ViewController
static double widgetHeight = 12;
static double widgetWidth = 16;

#define INCOMPLETE_BATCH_AFTER_IDLING (idleTimerCount == IDLE_TIME_OUT_COUNT && streams.count > 0 && streams.count < SUBSCRIBERS_IN_PARALLEL)
#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    streams = [[NSMutableArray alloc] init];
    subscribersConnected = [[NSMutableArray alloc] init];

//    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.2
//          target:[NSBlockOperation blockOperationWithBlock:^{
//        for (OTSubscriber* s in subscriberArray) {
//            s.preferredResolution = CGSizeMake(100, 100);
//        }
//        NSLog(@"preferredResolution set for %lu subscribers", (unsigned long)subscriberArray.count);
//    }]
//          selector:@selector(main)
//          userInfo:nil
//          repeats:YES
//    ];
        
        timer2 = [NSTimer scheduledTimerWithTimeInterval:1
              target:[NSBlockOperation blockOperationWithBlock:^{
            
                idleTimerCount +=1;
                NSLog(@"in Timer 2... idleTimeCount = %d", idleTimerCount);
                NSLog(@"number of streams %lu", (unsigned long)streams.count);
                NSLog(@"number of connected subscribers ** %lu **", subscribersConnected.count);
                
                if (INCOMPLETE_BATCH_AFTER_IDLING ||
                    streams.count >= SUBSCRIBERS_IN_PARALLEL) {
                        [self doBatchSubscribe];
                }
                if (idleTimerCount == IDLE_TIME_OUT_COUNT) {
                    idleTimerCount = 0;
                }
              }]
              selector:@selector(main)
              userInfo:nil
              repeats:YES
        ];
    
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

- (void)doSubscribe:(OTStream*)stream
{
    NSLog(@"doSubscribe (%@) ", stream.streamId );
    OTSubscriber *s = [[OTSubscriber alloc] initWithStream:stream delegate:self];
   // _subscriber.subscribeToAudio = false;
    OTError *error = nil;
    [_session subscribe:s error:&error];
    if (error)
    {
        [self showAlert:[error localizedDescription]];
    }
}

- (void)doBatchSubscribe
{
    NSLog(@"doBatchSubscribe");
    @try {
        for (int i=0; i < SUBSCRIBERS_IN_PARALLEL; i = i+1) {
            OTStream * stream = streams[i];
            if(stream == nil) break;
            [self doSubscribe:stream];
            [streams removeObject:stream];
        }
    }  @catch (NSException *exception) {
        
        
    } @finally {
       
    }
}
/**
 * Cleans the subscriber from the view hierarchy, if any.
 * NB: You do *not* have to call unsubscribe in your controller in response to
 * a streamDestroyed event. Any subscribers (or the publisher) for a stream will
 * be automatically removed from the session during cleanup of the stream.
 */
- (void)cleanupSubscriber
{
    [_subscriber.view removeFromSuperview];
    _subscriber = nil;
}

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
    if(streams.count > 40) {
        //throw an error / inform the user
        return;
       
    } else {
        [streams addObject:stream];
    }
}

- (void)session:(OTSession*)session
streamDestroyed:(OTStream *)stream
{
    NSLog(@"session streamDestroyed (%@)", stream.streamId);
    
    if ([_subscriber.stream.streamId isEqualToString:stream.streamId])
    {
        [self cleanupSubscriber];
    }
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
    if ([_subscriber.stream.connection.connectionId
         isEqualToString:connection.connectionId])
    {
        [self cleanupSubscriber];
    }
}

- (void) session:(OTSession*)session
didFailWithError:(OTError*)error
{
    NSLog(@"didFailWithError: (%@)", error);
}

# pragma mark - OTSubscriber delegate callbacks

- (void)subscriberDidConnectToStream:(OTSubscriberKit*)subscriber
{
    subConnected += 1;
    [subscribersConnected addObject:subscriber];
    
    NSLog(@"subscriberDidConnectToStream (%@) %lu",
          subscriber.stream.streamId, (unsigned long)subscribersConnected.count);
  
     
    OTSubscriber * s = (OTSubscriber *) subscriber;
    [s.view setFrame:CGRectMake(0, subscribersConnected.count * widgetHeight, widgetWidth,
                                         widgetHeight)];
    [self.view addSubview:s.view];
    
    if(subConnected == SUBSCRIBERS_IN_PARALLEL) {
        [self doBatchSubscribe];
        subConnected = 0;
    }
}

- (void)subscriber:(OTSubscriberKit*)subscriber
  didFailWithError:(OTError*)error
{
    subConnected += 1;
    NSLog(@"subscriber didFailWithError (%@)",
          subscriber.stream.streamId);
    if(subConnected == SUBSCRIBERS_IN_PARALLEL) {
        fNextBatch = true;

        subConnected = 0;
        
    } else {
        //todo sole subscriber
        fNextBatch = false;
    }

    [streams removeObject:subscriber.stream];
  
}

# pragma mark - OTPublisher delegate callbacks

- (void)publisher:(OTPublisherKit *)publisher
    streamCreated:(OTStream *)stream
{
    NSLog(@"Publishing");
  //  [self session:_session streamCreated:stream];

}

- (void)publisher:(OTPublisherKit*)publisher
  streamDestroyed:(OTStream *)stream
{
    if ([_subscriber.stream.streamId isEqualToString:stream.streamId])
    {
        [self cleanupSubscriber];
    }
    
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
