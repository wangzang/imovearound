//
//  ViewController.m
//  iMoveAround
//
//  Created by Karl Gallagher on 3/1/14.
//  Copyright (c) 2014 Karl Gallagher. All rights reserved.
//

#import "ViewController.h"
#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CLLocationManager.h>
#import <CoreLocation/CoreLocation.h>

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *stepLabel;
@property (nonatomic, strong) CMStepCounter *stepCounter;
@property (weak, nonatomic) IBOutlet UIDatePicker *countDownTimerPicker;

@end

@implementation ViewController

NSString *STEPS_KEY=@"theStepsKey";
NSString *COUNTDOWN_KEY=@"theCountDownKey";
NSString *MINIMUM_STEPS_KEY=@"theMinimumStepsKey";

UIBackgroundTaskIdentifier bgTask = 0;


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSInteger minimumStepCount = [[NSUserDefaults standardUserDefaults] integerForKey:MINIMUM_STEPS_KEY];
    
    [self.minimumStepCountPicker reloadAllComponents];
    [self.minimumStepCountPicker selectRow:minimumStepCount inComponent:0 animated:YES];
    
    self.countDownTimerPicker.countDownDuration = [[NSUserDefaults standardUserDefaults] floatForKey:COUNTDOWN_KEY];
    
	// Do any additional setup after loading the view, typically from a nib.
    [self initiateCounterQuery:false];
}


// this method updates the label based on the value stored in standardUserDefaults
- (void)updateStepCount:(bool)notification from:(NSDate *)from
{
    NSInteger numberOfSteps = [[NSUserDefaults standardUserDefaults] integerForKey:STEPS_KEY];
    // doing %li and (long) so that we're safe for 64-bit
    if (!notification)
        dispatch_async(dispatch_get_main_queue(),^{
            self.stepLabel.text = [NSString stringWithFormat:@"Steps: %li", (long)numberOfSteps];
        });
    
    NSLog(@"updateStepCount: updated steps to: %li. Notification? %s", (long)numberOfSteps, notification?"true":"false");
    
    if (notification)
    {
        NSInteger numberOfSteps = [[NSUserDefaults standardUserDefaults] integerForKey:STEPS_KEY];
        NSInteger minimumStepCount = [[NSUserDefaults standardUserDefaults] integerForKey:MINIMUM_STEPS_KEY];
        
        if (numberOfSteps < minimumStepCount)
        {
            [self triggerNotification:[NSString stringWithFormat:@"Only %li steps! Need more!", (long)numberOfSteps] ];
        }
        else
        {
            [self triggerNotification:[NSString stringWithFormat:@"%li steps! Doing Well!", (long)numberOfSteps] ];
        }
        
        float countDownDuration = [[NSUserDefaults standardUserDefaults] floatForKey:COUNTDOWN_KEY];

        NSLog(@"updateStepCount: Initiating repeat setTimer for %f seconds. ", countDownDuration);


        NSDate *now = [NSDate date];
        NSDate *then = [NSDate dateWithTimeInterval:countDownDuration sinceDate:now];

        if (![self setTimer:then])
        {
           [self triggerNotification:[NSString stringWithFormat:@"Failed to initiate setTimer!"] ];
        }
    }
}

- (void)initiateCounterQuery:(bool)notification
{
    if (!self.stepCounter)
        self.stepCounter = [[CMStepCounter alloc] init];
    
    float countDownDuration = [[NSUserDefaults standardUserDefaults] floatForKey:COUNTDOWN_KEY];

    NSLog(@"initiateCounterQuery: CountDownDuration = %f", countDownDuration);
    
    NSDate *now = [NSDate date];
    NSDate *from = [NSDate dateWithTimeInterval:-countDownDuration sinceDate:now];
    
    [self.stepCounter queryStepCountStartingFrom:from
                                              to:now
                                         toQueue:[NSOperationQueue mainQueue]
                                     withHandler:^(NSInteger numberOfSteps, NSError *error) {
                                         [[NSUserDefaults standardUserDefaults] setInteger:numberOfSteps forKey:STEPS_KEY];
                                         NSLog(@"initiateCounterQuery: reported steps: %li. notification: %s", (long)numberOfSteps, notification?"true":"false");
                                         NSLog(@"Between %@ and %@", from, now);
                                         [self updateStepCount:notification from:from];
                                     }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)updateCountdown:(id)sender {
    //NSLog(@"datePicker.countDownDuration: %f", self.countDownTimerPicker.countDownDuration);

    [[NSUserDefaults standardUserDefaults] setFloat:self.countDownTimerPicker.countDownDuration forKey:COUNTDOWN_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self initiateCounterQuery:false];
    
    NSLog(@"updateCountdown: initiating new setTimer: %f seconds", self.countDownTimerPicker.countDownDuration);
    
    NSDate *now = [NSDate date];
    NSDate *then = [NSDate dateWithTimeInterval:self.countDownTimerPicker.countDownDuration sinceDate:now];

    if (![self setTimer:then])
    {
        [self triggerNotification:[NSString stringWithFormat:@"Failed to initiate setTimer!"] ];
    }
}

- (void)updateTimer
{
    NSInteger numberOfSteps = [[NSUserDefaults standardUserDefaults] integerForKey:STEPS_KEY];
    // doing %li and (long) so that we're safe for 64-bit
    self.stepLabel.text = [NSString stringWithFormat:@"%li", (long)numberOfSteps];
    NSLog(@"updateTimer: steps updated to: %li", (long)numberOfSteps);
}

- (void)triggerNotification:(NSString *)alertString
{
    UILocalNotification* localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = [NSDate date];
    localNotification.alertBody = alertString;
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    NSLog(@"Notification Text: %@", alertString);
}

// this method updates the label based on the value stored in standardUserDefaults
- (void)updateStepLabel
{
    NSInteger numberOfSteps = [[NSUserDefaults standardUserDefaults] integerForKey:STEPS_KEY];
    // doing %li and (long) so that we're safe for 64-bit
    self.stepLabel.text = [NSString stringWithFormat:@"%li", (long)numberOfSteps];
}

// this method sets up the steps counter
- (void)startCountingSteps
{
    // the if statement checks whether the device supports step counting (ie whether it has an M7 chip)
    //    self.stepLabel.text = [NSString stringWithFormat:@"POO NUTS"];
    if ([CMStepCounter isStepCountingAvailable]) {
        // the step counter needs a queue, so let's make one
        NSOperationQueue *queue = [NSOperationQueue new];
        // call it something appropriate
        queue.name = @"Step Counter Queue";
        // now to create the actual step counter
        CMStepCounter *stepCounter = [CMStepCounter new];
        // this is where the brunt of the action happens
        [stepCounter startStepCountingUpdatesToQueue:queue updateOn:1 withHandler:^(NSInteger numberOfSteps, NSDate *timestamp, NSError *error) {
            // save the numberOfSteps value to standardUserDefaults, and then update the step label
            [[NSUserDefaults standardUserDefaults] setInteger:numberOfSteps forKey:STEPS_KEY];
            dispatch_async(dispatch_get_main_queue(),^{
                [self updateStepLabel];
            });
        }];
    }
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    NSLog(@"Minimum Step Count = %ld", (long)row);
    [[NSUserDefaults standardUserDefaults] setInteger:row forKey:MINIMUM_STEPS_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    //[self writeLog:@"OMG MIN STEP COUNT"];
}

//none of this shit works. i'm trying to make a picker that just shows a bunch of numbers for the "minimumStepCount"
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return 100;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component;
{
    if (component == 0 )
    {
        return [NSString stringWithFormat:@"%ld",(long)(row)];
    }
    
    return @"";//required elements
}

- (BOOL)setTimer:(NSDate*)alarmTime
{
    NSDate *now = [NSDate date];
    NSTimeInterval timeout = [alarmTime timeIntervalSinceDate:now];
    NSLog(@"setTimer: Timeout is %f", timeout);

    //if timeout is longer than 10 minutes, we need to set a keepAlive timer.
    //otherwise, we can use a normal timer.
    if (timeout > 600.0f)
    {
        //make sure the <600 second timer isn't running.
        if (countDownTimer != nil) {
            if([countDownTimer isValid]){
                [countDownTimer invalidate];
            }
            countDownTimer = nil;
        }
        if (![[UIApplication sharedApplication] setKeepAliveTimeout:timeout handler:^{
        [self setTimer:alarmTime];
        }])
        {
            [self triggerNotification:[NSString stringWithFormat:@"Failed to initiate setTimer keepAlive!"] ];
            return false;
        }
        NSLog(@"setTimer: Starting setKeepAliveTimeout for %f seconds", timeout);
        return true;
    }
    
    // Start the long-running task and return immediately.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // Do the work associated with the task.
        [self startTimerAction:timeout];
    });
    return true;
}

NSTimer *countDownTimerChecker;

-(void)startTimerAction:(NSTimeInterval)timeout
{
    NSLog(@"startTimerAction backgroundTask: for %f seconds!", timeout);

    /* this should be getting done when the app goes to shut down and sees that a timer is still active.*/
    UIApplication*    app = [UIApplication sharedApplication];
    bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
        [app endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // Do the work associated with the task.
        countDownTimer = [NSTimer timerWithTimeInterval:timeout
                                           target:self
                                         selector:@selector(timerAlarmHandler)
                                         userInfo:nil
                                          repeats:NO];
        
        [[NSRunLoop mainRunLoop] addTimer:countDownTimer forMode:NSDefaultRunLoopMode];
        
        
        if (countDownTimerChecker != nil) {
            if([countDownTimerChecker isValid]){
                [countDownTimerChecker invalidate];
            }
            countDownTimerChecker = nil;
        }
        
        countDownTimerChecker = [NSTimer timerWithTimeInterval:10
                                                 target:self
                                               selector:@selector(timerAlarmChecker)
                                               userInfo:nil
                                                repeats:YES];
        
        [[NSRunLoop mainRunLoop] addTimer:countDownTimerChecker forMode:NSDefaultRunLoopMode];

        //[countDownTimer fire];
//        NSLog(@"Countdown Timer started, and it's = %p", countDownTimer);
    });
}


-(void)timerAlarmChecker
{
    NSDate *now = [NSDate date];
    NSTimeInterval timeout = -[now timeIntervalSinceDate:countDownTimer.fireDate];
    UIApplication*    app = [UIApplication sharedApplication];
    NSLog(@"Made it into the timerAlarmChecker. Time Until Background: %f, Alarm: %f", [app backgroundTimeRemaining], timeout);
}


-(void)timerAlarmHandler
{
    NSLog(@"Made it into the timerAlarmHandler initiating counter Query with notifications and recreating background task!");
    [self initiateCounterQuery:true];

    UIApplication*    app = [UIApplication sharedApplication];
//    [app endBackgroundTask:bgTask];
//    bgTask = UIBackgroundTaskInvalid;

    bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
        [app endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];

}

//FOUNDATION_EXPORT void NSLog(NSString *format, ...) NS_FORMAT_FUNCTION(1,2);

-(void)writeLog:(NSString*)logString
{
    //NSString *logString = @"This is my log";
    
    //Get the file path
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *fileName = [documentsDirectory stringByAppendingPathComponent:@"myFileName.txt"];
    
    //create file if it doesn't exist
    if(![[NSFileManager defaultManager] fileExistsAtPath:fileName])
        [[NSFileManager defaultManager] createFileAtPath:fileName contents:nil attributes:nil];
    
    //append text to file (you'll probably want to add a newline every write)
    NSFileHandle *file = [NSFileHandle fileHandleForUpdatingAtPath:fileName];
    [file seekToEndOfFile];
    [file writeData:[logString dataUsingEncoding:NSUTF8StringEncoding]];
    [file closeFile];
}

-(void)readLog
{
    //get file path
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *fileName = [documentsDirectory stringByAppendingPathComponent:@"myFileName.txt"];
    
    //read the whole file as a single string
    NSString *content = [NSString stringWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:nil];
    NSLog(@"content is: %@", content);
}

@end
