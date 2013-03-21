//
//  BRKAppDelegate.h
//  chauffeur
//
//  Created by Zakaria on 3/10/13.
//  Copyright (c) 2013 Zakaria. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@class BRKViewController;
@class FMDatabase;

@interface BRKAppDelegate : UIResponder <UIApplicationDelegate,CLLocationManagerDelegate>{
    CLLocationManager *locationManager;
    int i;
    FMDatabase *db;
    BOOL busy;
    int pendingAlertView;
    int pendingNotifications;
    UIActivityIndicatorView *activityIndicator;

}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UIViewController *viewController;
@property (retain, nonatomic) NSMutableData *receivedData;
@property (retain, nonatomic) NSURLConnection *connection;


- (BOOL) getBusyStatus;
- (void) cancelCourse;
- (void) makeBusy;
- (void) makeAvailable;
- (void) createEditableCopyOfDatabaseIfNeeded;
- (NSString*) getUserId;
- (void) dbLogErrors;


@end
