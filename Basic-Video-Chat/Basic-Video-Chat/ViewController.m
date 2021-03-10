//
//  ViewController.m
//  Hello-World
//
//  Copyright (c) 2013 TokBox, Inc. All rights reserved.
//

#import "ViewController.h"
#import <OpenTok/OpenTok.h>

// *** Fill the following variables using your own Project info  ***
// ***          https://dashboard.tokbox.com/projects            ***
// Replace with your OpenTok API key
static NSString* const kApiKey = @"";
// Replace with your generated session ID
static NSString* const kSessionId = @"";
// Replace with your generated token
static NSString* const kToken = @"";

// This determines the number subscriptions to make in parallel.
#define SUBSCRIBERS_IN_PARALLEL 1
// This determines the maximum number of participants we will load.
#define MAX_SUBSCRIBERS 40
// This defines how long to wait between checking for new members (in seconds)
#define TIMER2_SECONDS 2

NSMutableArray * streams; // streams to connect to
NSMutableArray * subscribersConnected; // The subscribers already connected
int subConnected = 0;
bool fNextBatch = true;
NSTimer *timer2;
int idleTimerCount = 0; // This keeps track of whether we successfully added new subscribers since the last time the timer fired.

@interface ViewController ()<OTSessionDelegate, OTSubscriberDelegate, OTPublisherDelegate, OTPublisherKitAudioLevelDelegate>
@property (nonatomic) OTSession *session;
@property (nonatomic) OTPublisher *publisher;
@property (nonatomic) OTSubscriber *subscriber;
@end

@implementation ViewController
static double widgetHeight = 12;
static double widgetWidth = 16;

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    streams = [[NSMutableArray alloc] init]; // array of streams to subscribe to
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
        
    
   /* This code uses a timer to periodically check the session for participants and create a queue of streams to subscribe to.
    */
        timer2 = [NSTimer scheduledTimerWithTimeInterval:TIMER2_SECONDS
              target:[NSBlockOperation blockOperationWithBlock:^{
            NSLog(@"in Timer 2...");
            NSLog(@"number of streams %lu", (unsigned long)streams.count);
            NSLog(@"number of connected subscribers ** %lu **", subscribersConnected.count);
           
                @try {
                    for (int i=0; i < SUBSCRIBERS_IN_PARALLEL && fNextBatch; i = i+1) {
                        OTStream * stream = streams[i];
                        if(stream == nil) break;
                        [self doSubscribe:stream]; // subscribe to the stream
                        [streams removeObject:stream]; // remove the stream from our list to subscribe to
                    }
                    
                }
                @catch (NSException *exception) {
                    
                    
                } @finally {
                    fNextBatch = false;
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
   // _subscriber.subscribeToAudio = false; // This is used in testing to prevent feedback.
    OTError *error = nil;
    [_session subscribe:s error:&error];
    if (error)
    {
        [self showAlert:[error localizedDescription]];
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
    /* This code is called whenever a new stream is created within the session */
    NSLog(@"session streamCreated (%@) ", stream.streamId );
    if(streams.count > MAX_SUBSCRIBERS) { // If there are more than x streams already
        //throw an error / inform the user
        return;
       
    } else { // add the stream object to the array
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
    /* This code will wait for the number of SUBSCRIBERS_IN_PARALLEL to connect
     and then go fetch the next batch.
     */
    subConnected += 1;
    [subscribersConnected addObject:subscriber];
    
    NSLog(@"subscriberDidConnectToStream (%@) %lu",
          subscriber.stream.streamId, (unsigned long)subscribersConnected.count);
  
     
    OTSubscriber * s = (OTSubscriber *) subscriber;
    [s.view setFrame:CGRectMake(0, subscribersConnected.count * widgetHeight, widgetWidth,
                                         widgetHeight)];
    [self.view addSubview:s.view];
    
    if(subConnected == SUBSCRIBERS_IN_PARALLEL) { // We successfully connected the subs requested.
        fNextBatch = true;
        [timer2 fire];
        subConnected = 0;
        
    } else { // There are fewer subscribers in the queue than SUBSCRIBERS_IN_PARALLEL
        //todo sole subscriber
        fNextBatch = false;
    }
}

- (void)subscriber:(OTSubscriberKit*)subscriber
  didFailWithError:(OTError*)error
{
    subConnected += 1;
    NSLog(@"subscriber didFailWithError (%@)",
          subscriber.stream.streamId);
    if(subConnected == SUBSCRIBERS_IN_PARALLEL) { // If one or more failed, but we finished the queue, reset subConnected.
        fNextBatch = true;

        subConnected = 0;
        
    } else { // The queue had fewer than the number of subs_in_parallel
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
