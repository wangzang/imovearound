//
//  ViewController.m
//  SingleViewApplication
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
    
    NSLog(@"updateStepCount updated steps to: %li. Notification? %s", (long)numberOfSteps, notification?"true":"false");
    
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

        NSLog(@"Initiating repeat setTimer for %f seconds. ", countDownDuration);


        __weak typeof(self) weakSelf = self;
        if (![self setTimer:countDownDuration handler:^{
            [weakSelf initiateCounterQuery:true];
        }])
        {
           [self triggerNotification:[NSString stringWithFormat:@"Failed to initiate setTimer!"] ];
        }

        
//        if (![[UIApplication sharedApplication] setKeepAliveTimeout:countDownDuration handler:^{
//            [self initiateCounterQuery:true];
//        }])
//        {
//            [self triggerNotification:[NSString stringWithFormat:@"Failed to initiate keepAlive!"] ];
//        }
        
        
    }
}

- (void)initiateCounterQuery:(bool)notification
{
    if (!self.stepCounter)
        self.stepCounter = [[CMStepCounter alloc] init];
    
    float countDownDuration = [[NSUserDefaults standardUserDefaults] floatForKey:COUNTDOWN_KEY];

    NSDate *now = [NSDate date];
    NSDate *from = [NSDate dateWithTimeInterval:-countDownDuration sinceDate:now];
    
    __weak typeof(self) weakSelf = self;
    [self.stepCounter queryStepCountStartingFrom:from
                                              to:now
                                         toQueue:[NSOperationQueue mainQueue]
                                     withHandler:^(NSInteger numberOfSteps, NSError *error) {
                                         [[NSUserDefaults standardUserDefaults] setInteger:numberOfSteps forKey:STEPS_KEY];
                                         NSLog(@"initiateCounterQuery reported steps: %li. notification: %s", (long)numberOfSteps, notification?"true":"false");
                                         [self updateStepCount:notification from:from];
                                     }];
    NSLog(@"queryStepCount returned %ld steps", (long)weakSelf.title);
    NSLog(@"Between %@ and %@", from, now);
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resourc    es that can be recreated.
}


- (IBAction)updateCountdown:(id)sender {
    NSLog(@"datePicker.countDownDuration: %f", self.countDownTimerPicker.countDownDuration);
    
    [self initiateCounterQuery:false];
    
    NSLog(@"Initiating new setTimer for %f seconds", self.countDownTimerPicker.countDownDuration);
    

    __weak typeof(self) weakSelf = self;
    if (![self setTimer:self.countDownTimerPicker.countDownDuration handler:^{
        [weakSelf initiateCounterQuery:true];
    }])
    {
        [self triggerNotification:[NSString stringWithFormat:@"Failed to initiate setTimer!"] ];
    }

    
//    if (![[UIApplication sharedApplication] setKeepAliveTimeout:self.countDownTimerPicker.countDownDuration handler:^{
//        [self initiateCounterQuery:true];
//    }])
//    {
//        [self triggerNotification:[NSString stringWithFormat:@"Failed to initiate keepAlive!"] ];
//    }
    
    NSInteger minimumStepCount = [[NSUserDefaults standardUserDefaults] integerForKey:MINIMUM_STEPS_KEY];
    
    NSDate *now = [NSDate date];
    NSDate *then = [NSDate dateWithTimeInterval:self.countDownTimerPicker.countDownDuration sinceDate:now];
    
    NSLog(@"Countdown set for %li steps in %f seconds, so by %@. It is now %@", (long)minimumStepCount, self.countDownTimerPicker.countDownDuration, then, now);
    
    [[NSUserDefaults standardUserDefaults] setFloat:self.countDownTimerPicker.countDownDuration forKey:COUNTDOWN_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)updateTimer
{
    NSInteger numberOfSteps = [[NSUserDefaults standardUserDefaults] integerForKey:STEPS_KEY];
    // doing %li and (long) so that we're safe for 64-bit
    self.stepLabel.text = [NSString stringWithFormat:@"%li", (long)numberOfSteps];
    NSLog(@"steps updated to: %li", (long)numberOfSteps);
}

- (void)triggerNotification:(NSString *)alertString
{
    UILocalNotification* localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = [NSDate date];
    localNotification.alertBody = alertString;
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
//    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
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

- (BOOL)setTimer:(NSTimeInterval)timeout handler:(void(^)(void))timerHandler NS_AVAILABLE_IOS(4_0)
{

    //if timeout is longer than 10 minutes, we need to set a keepAlive timer.
    //otherwise, we can use a normal timer.
    if (timeout > 600.0f)
    {
        if (![[UIApplication sharedApplication] setKeepAliveTimeout:timeout handler:^{
            timerHandler();
        }])
        {
            [self triggerNotification:[NSString stringWithFormat:@"Failed to initiate setTimer keepAlive!"] ];
            return false;
        }
        return true;
    }
    
    // Start the long-running task and return immediately.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // Do the work associated with the task.
        [self startTimerAction:timeout handler:timerHandler];
    });
    return true;
}

-(void)startTimerAction:(NSTimeInterval)timeout handler:(void(^)(void))timerHandler
{
    NSLog(@"Started timerAction for %f seconds!", timeout);

/*    [NSTimer scheduledTimerWithTimeInterval:2.0
                                     target:self
     //i can't figure out how to get the timer to take a callback to the pointer. ugh.
                                    selector:@selector(aMethod:timerHandler:)
                                   userInfo:nil
                                    repeats:NO];
  */
    
    UIApplication*    app = [UIApplication sharedApplication];
    
    bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
        [app endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // Do the work associated with the task.
        countDownTimer = [NSTimer timerWithTimeInterval:timeout
                                           target:self
                                         selector:@selector(aMethod)
                                         userInfo:nil
                                          repeats:NO];
        
        
        //i need to start the timer, but there seems to be an infinite loop somewhere.
        [[NSRunLoop mainRunLoop] addTimer:countDownTimer forMode:NSDefaultRunLoopMode];
        //[countDownTimer fire];
        NSLog(@"Countdown Timer started, and it's = %p", countDownTimer);
    });


}

-(void)aMethod
{
    NSLog(@"Made it into the timerHandler initiating counter Query with notifications!");

//    [_countDownTimer invalidate];
//    _countDownTimer = nil;

    
    if (countDownTimer != nil) {
        if([countDownTimer isValid]){
            [countDownTimer invalidate];
        }
        countDownTimer = nil;
        NSLog(@"Invalidated timer");
    }

    [self initiateCounterQuery:true];

    UIApplication*    app = [UIApplication sharedApplication];
    [app endBackgroundTask:bgTask];
    bgTask = UIBackgroundTaskInvalid;

}

@end
