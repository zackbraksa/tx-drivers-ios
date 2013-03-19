//
//  BRKAppDelegate.h
//  Chaffeur
//
//  Created by Zakaria on 3/10/13.
//  Copyright (c) 2013 Zakaria. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@class BRKViewController;

@interface BRKAppDelegate : UIResponder <UIApplicationDelegate,CLLocationManagerDelegate>{
    CLLocationManager *locationManager;
    int i;
    float old_lat;
    float old_long;
    BOOL busy;
    int pendingAlertView;
    int pendingNotifications;
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UIViewController *viewController;
@property (retain, nonatomic) NSMutableData *receivedData;
@property (retain, nonatomic) NSURLConnection *connection;


- (BOOL) getBusyStatus;
- (void) makeBusy;
- (void) makeAvailable;
- (void)createEditableCopyOfDatabaseIfNeeded;


@end
