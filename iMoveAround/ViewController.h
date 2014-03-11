//
//  ViewController.h
//  iMoveAround
//
//  Created by Karl Gallagher on 3/1/14.
//  Copyright (c) 2014 Karl Gallagher. All rights reserved.
//

#import <UIKit/UIKit.h>

NSTimer *silenceTimer;

@interface ViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource>

@property (weak, nonatomic) IBOutlet UIPickerView *minimumStepCountPicker;

//@property (nonatomic, retain) NSTimer *silenceTimer;

@end
