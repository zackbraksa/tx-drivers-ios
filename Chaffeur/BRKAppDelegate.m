//
//  BRKAppDelegate.m
//  Chaffeur
//
//  Created by Zakaria on 3/10/13.
//  Copyright (c) 2013 Zakaria. All rights reserved.
//

#import "BRKAppDelegate.h"
#import "BRKLoginViewController.h"
#import "BRKTabBarViewController.h"
#import "BRKHomeViewController.h"

@implementation BRKAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    // Override point for customization after application launch.
    [self performSelector:@selector(createEditableCopyOfDatabaseIfNeeded) withObject:nil];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *user_id = [defaults objectForKey:@"user_id"];
    NSLog(@"LOGIN user_id : %@",user_id);
    
    if(user_id == NULL){
        busy = true;
         BRKLoginViewController *firstView = [[BRKLoginViewController alloc] initWithNibName:@"BRKLoginViewController" bundle:nil];
        self.viewController = [[UINavigationController alloc] initWithRootViewController:firstView];
        ((UINavigationController*)self.viewController).navigationBar.tintColor = [UIColor blackColor];
        
    }else{
        busy = FALSE;
        self.viewController = [[BRKTabBarViewController alloc] initWithNibName:@"BRKHomeViewController" bundle:nil];
    }
    
    
    self.window.rootViewController = self.viewController;
    
    locationManager = [[CLLocationManager alloc] init];
    [locationManager setDelegate:self];
    [locationManager setDistanceFilter:kCLDistanceFilterNone];
    [locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    
    NSLog(@"App didFinishLaunchingWithOptions");
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    NSLog(@"Enter Background");
    
    [locationManager startMonitoringSignificantLocationChanges];
    
    //[locationManager stopMonitoringSignificantLocationChanges];
    //[locationManager startUpdatingLocation];

}

-(BOOL)getBusyStatus{
    return busy;
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    NSLog(@"Enter Foreground");
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *reservation = [defaults objectForKey:@"pending_reservation"];
    
    if(reservation != NULL){
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Course en attente!"
                                                          message:@""
                                                         delegate:self
                                                cancelButtonTitle:@"Accepter"
                                                otherButtonTitles:@"Ignorer", nil];
        [message show];
    }else{
        
    }
    
    [locationManager stopMonitoringSignificantLocationChanges];
    [locationManager startUpdatingLocation];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    if([title isEqualToString:@"Accepter"])
    {
        
    }
    else if([title isEqualToString:@"Ignorer"])
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults removeObjectForKey:@"pending_reservation"];
        busy = false;
    }
    
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


-(void) locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{

    if(!busy){
    NSLog(@"req sent: sendData");
    
    NSMutableData *data = [[NSMutableData alloc] init];
    self.receivedData = data;
    
    
        // simulate movement 
        if(old_lat == 0 && old_long == 0){
            old_lat = newLocation.coordinate.latitude;
            old_long = newLocation.coordinate.longitude;
        }else{
            old_lat += 0.001;
            old_long += 0.001;
        }
        //simulate movement - end
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *user_id = [defaults objectForKey:@"user_id"];

        
        if ([self.viewController respondsToSelector:@selector(selectedViewController)]) {
            BRKHomeViewController* homeView = (BRKHomeViewController*)((UITabBarController*)self.viewController).selectedViewController;
            if([homeView respondsToSelector:@selector(debugField)]){
                homeView.debugField.text = [[NSString alloc] initWithFormat:@"sent %d", i];
            }
            i++;
        }
        
        
        //initialize new mutable data
        self.receivedData = data;
        
        //initialize url that is going to be fetched.
        NSURL *url = [NSURL URLWithString:@"http://localhost:8888/tx/index.php/api/chaffeurs/position/format/json"];
        
        //initialize a request from url
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[url standardizedURL]];
        
        //set http method
        [request setHTTPMethod:@"POST"];
        //initialize a post data
        NSString *postData = [[NSString alloc] initWithFormat:@"id=%@&latitude=%f&longitude=%f",user_id, newLocation.coordinate.latitude, newLocation.coordinate.longitude];
        
        //set request content type we MUST set this value.
        
        [request setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        
        //set post data of request
        [request setHTTPBody:[postData dataUsingEncoding:NSUTF8StringEncoding]];
        
        //initialize a connection from request
        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        self.connection = connection;
        
        //start the connection
        [connection start];
        
    }
    
    UIBackgroundTaskIdentifier backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        __block backgroundTask = UIBackgroundTaskInvalid;
        // Cancel your request here
    }];
}

- (void)requestFinished:(id)request {
    UIBackgroundTaskIdentifier backgroundTask = 0;

    [[UIApplication sharedApplication] endBackgroundTask:backgroundTask];
    backgroundTask = UIBackgroundTaskInvalid;
}


-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    
    
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:self.receivedData
                          options:kNilOptions
                          error:nil];
    
    NSLog(@"Data sent %d", i);
    
    //NSLog(@"%@",json);
    
    //si la reponse est de type updatePosition (+ Recevoir les reservations en cours).
    if(json && [[json objectForKey:@"action"] isEqualToString:@"updatePosition"]){
        //s'il y a des reservations en attente
        if([[json objectForKey:@"status"] isEqualToString:@"done"]){
            
            busy = true;
            
            
            UIApplicationState state = [[UIApplication sharedApplication] applicationState];
            
            //si app en background ou inactive alors envoyer notification. 
            if (state == UIApplicationStateBackground || state == UIApplicationStateInactive)
            {
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setObject:[[json objectForKey:@"reservation"] objectForKey:@"destination"] forKey:@"pending_reservation"];
                
                [[UIApplication sharedApplication] cancelAllLocalNotifications];
                
                Class cls = NSClassFromString(@"UILocalNotification");
                if (cls != nil) {
                    
                    UILocalNotification *notif = [[cls alloc] init];
                    notif.timeZone = [NSTimeZone defaultTimeZone];
                    
                    notif.alertBody = @"Une course en attente de confirmation.";
                    notif.alertAction = @"Afficher";
                    notif.soundName = UILocalNotificationDefaultSoundName;
                    notif.applicationIconBadgeNumber = 1;
                    
                    [[UIApplication sharedApplication] presentLocalNotificationNow:notif];
                }
                
            }
            //sinon afficher directement le UIAlertView à l'écran. 
            else{
                UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Course en attente!"
                                                                  message:@""
                                                                 delegate:self
                                                        cancelButtonTitle:@"Accepter"
                                                        otherButtonTitles:@"Ignorer", nil];
                [message show];
            }
            
        
        }
        //s'il n'y a pas de reservations en attente. 
        else{
            NSLog(@"No Pending Reservation");
        }
        
        
    }
    //si la reponse est de type accepterReservation. 
    else if([[json objectForKey:@"action"] isEqualToString:@"acceptReservation"]){
        NSLog(@"Reservation Accepted");
    }
    
    
}


-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [self.receivedData appendData:data];
}


-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    NSLog(@"%@" , error);
}


-(void) makeBusy{
    busy = TRUE;
}

- (void) makeAvailable{
    busy = FALSE;
}


- (void)createEditableCopyOfDatabaseIfNeeded {
    
    
    // First, test for existence.
    BOOL success;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:@"db.sqlite"];
    success = [fileManager fileExistsAtPath:writableDBPath];
    if (success) return;
    // The writable database does not exist, so copy the default to the appropriate location.
    NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"db.sqlite"];
    success = [fileManager copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error];
    if (!success) {
        NSAssert1(0, @"Failed to create writable database file with message '%@'.", [error localizedDescription]);
    }
}







@end
