//
//  MainViewController.m
//  Drive
//
//  Created by Ryan Copley on 11/27/13.
//  Copyright (c) 2013 Ryan Copley. All rights reserved.
//

#import "MainViewController.h"
#import "AFNetworking.h"
// Adjust this to your servers settings...
#define baseurl @"http://drive.ryancopely.com"
@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        locList = @[
                    @"1600 Pennsylvania Avenue, Washington DC",
                    @"11 Wall Street New York, NY",
                    @"350 Fifth Avenue New York, NY 10118",
                    @"4059 Mt Lee Dr. Hollywood, CA 90068"
                    ];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    locationManager = [[CLLocationManager alloc] init];
    
}


- (IBAction)toggled:(id)sender {
    if (onOff.on){
        if ([toField.text isEqualToString:@""] || [fromField.text isEqualToString:@""]){
            onOff.on = NO;
            return;
        }
    }
    [self setDirections:nil];
    
    if (onOff.on){
        
        
        t = [NSTimer scheduledTimerWithTimeInterval: 5.0 target: self selector: @selector(updateWeb) userInfo: nil repeats: YES];
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        [locationManager startUpdatingLocation];
        
        AFSecurityPolicy *securityPolicy = [[AFSecurityPolicy alloc] init];
        [securityPolicy setAllowInvalidCertificates:YES];
        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        manager.securityPolicy = securityPolicy;
        
        NSDictionary *parameters = @{ @"rnd":@(arc4random()%1000000)};
        
        [manager GET:[NSString stringWithFormat:@"%@/start",baseurl] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Started");
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
        }];
    }else{
        [locationManager stopUpdatingLocation];
        [t invalidate];
        AFSecurityPolicy *securityPolicy = [[AFSecurityPolicy alloc] init];
        [securityPolicy setAllowInvalidCertificates:YES];
        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        manager.securityPolicy = securityPolicy;
        
        NSDictionary *parameters = @{ @"rnd":@(arc4random()%1000000)};
        
        [manager GET:[NSString stringWithFormat:@"%@/kill",baseurl] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"Killed");
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
        }];
        
    }
}


#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError: %@", error);
    UIAlertView *errorAlert = [[UIAlertView alloc]
                               initWithTitle:@"Error" message:@"Failed to Get Your Location" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [errorAlert show];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    //NSLog(@"didUpdateToLocation: %@", newLocation);
    CLLocation *currentLocation = newLocation;
    
    if (currentLocation != nil) {
        spd = [NSString stringWithFormat:@"%.8f", currentLocation.speed*2.23694];
        lng = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.longitude];
        lat = [NSString stringWithFormat:@"%.8f", currentLocation.coordinate.latitude];
    }
}

-(void)updateWeb{
    AFSecurityPolicy *securityPolicy = [[AFSecurityPolicy alloc] init];
    [securityPolicy setAllowInvalidCertificates:YES];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.securityPolicy = securityPolicy;
    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    NSNumber * _lat = [f numberFromString:lat];
    NSNumber * _lng = [f numberFromString:lng];
    NSNumber * _spd = [f numberFromString:spd];
    
    
    NSDictionary *parameters = @{@"lat":_lat,@"lng":_lng, @"spd":_spd, @"rnd":@(arc4random()%1000000)};

    [manager GET:[NSString stringWithFormat:@"%@/update",baseurl] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [locList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    cell.textLabel.text = [locList objectAtIndex:indexPath.row];
    
    return cell;
    
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString* addr = [locList objectAtIndex:indexPath.row];
    tmpAddr = addr;
    NSString *actionSheetTitle = addr; //Action Sheet Title
    NSString *other1 = @"Set as From";
    NSString *other2 = @"Set as To";
    NSString *cancelTitle = @"Cancel";
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:actionSheetTitle
                                  delegate:self
                                  cancelButtonTitle:cancelTitle
                                  destructiveButtonTitle:nil
                                  otherButtonTitles:other1, other2, nil];
    [actionSheet showInView:self.view];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex){
        case 0:
            //From
            fromField.text = tmpAddr;
            break;
        case 1:
            //To
            toField.text = tmpAddr;
            break;
        case 2:
            NSLog(@"Cancelled");
            break;
    }
}

- (IBAction)setDirections:(id)sender {
    

    AFSecurityPolicy *securityPolicy = [[AFSecurityPolicy alloc] init];
    [securityPolicy setAllowInvalidCertificates:YES];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.securityPolicy = securityPolicy;
    
    NSDictionary *parameters = @{@"from":fromField.text,@"to":toField.text, @"rnd":@(arc4random()%1000000)};
    
    [manager GET:[NSString stringWithFormat:@"%@/setaddr",baseurl] parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Yay");
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

@end
