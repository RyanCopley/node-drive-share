//
//  MainViewController.h
//  Drive
//
//  Created by Ryan Copley on 11/27/13.
//  Copyright (c) 2013 Ryan Copley. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface MainViewController : UIViewController <CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>{
     CLLocationManager *locationManager;
    
    __weak IBOutlet UISwitch *onOff;
    NSString* lat;
    NSString* lng;
    NSString* spd;
    NSTimer* t;
    
    
    __weak IBOutlet UITableView *locationTableView;
    
    __weak IBOutlet UITextField *fromField;
    
    __weak IBOutlet UITextField *toField;
    NSArray* locList;
    
    NSString* tmpAddr;
}
- (IBAction)toggled:(id)sender;
- (IBAction)findFromPressed:(id)sender;
- (IBAction)findToPressed:(id)sender;

@end
