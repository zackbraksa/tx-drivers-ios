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
#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import <QuartzCore/QuartzCore.h>


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
    
    pendingAlertView = 0;
    
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
    
    if(!busy){
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *dbPath = [documentsDirectory stringByAppendingPathComponent:@"db.sqlite"];
        FMDatabase *db = [FMDatabase databaseWithPath:dbPath];
        
        db.logsErrors = YES;
        
        if([db open]){
            NSLog(@"Opened");
            NSLog(@"Alert View In Forground");
        }else{
            NSLog(@"Not Opened");
        }
        
        FMResultSet *s = [db executeQuery:@"select * from reservations WHERE status != 'ignored'"];
        
        if ([db hadError]) {
            NSLog(@"DB Error %d: %@", [db lastErrorCode], [db lastErrorMessage]);
        }
        
        while ([s next] && pendingAlertView == 0) {
            NSString* depart = [[NSString alloc] initWithFormat:@"Client à %@", [s stringForColumn:@"depart"] ];
            NSString* title = [[NSString alloc] initWithFormat:@"Course en attente #%d", [s intForColumn:@"id"]];
            
            UIAlertView *message = [[UIAlertView alloc] initWithTitle:title
                                                              message:depart
                                                             delegate:self
                                                    cancelButtonTitle:@"Accepter"
                                                    otherButtonTitles:@"Ignorer", nil];
            [message show];
            pendingAlertView++;
        }
        
        if(pendingAlertView){
            busy = true;
        }
        
    }


    
    [locationManager stopMonitoringSignificantLocationChanges];
    [locationManager startUpdatingLocation];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    NSRange range;
    range = [[alertView title] rangeOfString:@"#"];
    int *len = [[alertView title] length];
    len--;
    NSRange searchRange = NSMakeRange(range.location + 1, (alertView.title.length - range.location - 1));
    NSString* someString = [[alertView title] substringWithRange:searchRange];
    
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    if([title isEqualToString:@"Accepter"])
    {
        NSLog(@"Accepting Reservation");
        NSMutableData *data = [[NSMutableData alloc] init];
        self.receivedData = data;
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *user_id = [defaults objectForKey:@"user_id"];
        
        //initialize new mutable data
        self.receivedData = data;
        
        //initialize url that is going to be fetched.
        NSURL *url = [NSURL URLWithString:@"http://localhost:8888/tx/index.php/api/chaffeurs/acceptReservation/format/json"];
        
        //initialize a request from url
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[url standardizedURL]];
        
        //set http method
        [request setHTTPMethod:@"POST"];
        //initialize a post data
        NSString *postData = [[NSString alloc] initWithFormat:@"idReservation=%@&idChauffeur=%@", someString, user_id];
        
        NSLog(@"idReservation: %@, idChauffeur: %@", someString, user_id);
        
        //set request content type we MUST set this value.
        
        [request setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        
        //set post data of request
        [request setHTTPBody:[postData dataUsingEncoding:NSUTF8StringEncoding]];
        
        //initialize a connection from request
        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        self.connection = connection;
        
        //start the connection
        [connection start];
        
        activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        activityIndicator.layer.backgroundColor = [[UIColor colorWithWhite:0.0f alpha:0.5f] CGColor];
        activityIndicator.hidesWhenStopped = YES;
        activityIndicator.frame = self.window.bounds;
        [self.window addSubview:activityIndicator];
        [activityIndicator startAnimating];
    }
    else if([title isEqualToString:@"Ignorer"])
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults removeObjectForKey:@"pending_reservation"];
        pendingAlertView--;
        
        
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *dbPath = [documentsDirectory stringByAppendingPathComponent:@"db.sqlite"];
        //NSLog(@"%@",dbPath);
        FMDatabase *db = [FMDatabase databaseWithPath:dbPath];
        
        db.logsErrors = YES;
        
        
        if([db open]){
            NSLog(@"Opened");
        }else{
            NSLog(@"Not Opened");
        }
        
        [db executeUpdateWithFormat:@"UPDATE reservations SET status = 'ignored' WHERE id = (%d)", [someString intValue]];

        if(pendingAlertView == 0){
            busy = false;
        }
        
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
    
    NSLog(@"DATE SENT");
    
    //si la reponse est de type updatePosition (+ Recevoir les reservations en cours).
    if(json && [[json objectForKey:@"action"] isEqualToString:@"updatePosition"]){
        //s'il y a des reservations en attente
        if([[json objectForKey:@"status"] isEqualToString:@"done"]){
            
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSString *dbPath = [documentsDirectory stringByAppendingPathComponent:@"db.sqlite"];
            FMDatabase *db = [FMDatabase databaseWithPath:dbPath];
            NSLog(@"%@",dbPath);
            db.logsErrors = YES;
            
            if([db open]){
                NSLog(@"DB Opened in updatePosition");
            }else{
                NSLog(@"DB Not Opened in updatePosition");
            }
            
            NSArray* reservations = [json objectForKey:@"reservation"];
            for(int j = 0; j < [reservations count]; j++){
                NSLog(@"Adding Reservation %d to DB.", j);
                NSDictionary* uneReservation = [reservations objectAtIndex:j];
                NSString* query = [[NSString alloc] initWithFormat:@"select count(id) from reservations WHERE id = (%d)",[[uneReservation objectForKey:@"id"] intValue]];
                NSUInteger count = [db intForQuery:query];
                
                if(count == 0){
                    NSLog(@"Inserting");
                    [db executeUpdate:@"INSERT INTO reservations(id,latitude, longitude,status,date, depart) VALUES (?, ?, ?, ?, ?, ?)",[uneReservation objectForKey:@"id"],[uneReservation objectForKey:@"latitude"],[uneReservation objectForKey:@"longitude"],[uneReservation objectForKey:@"status"],[uneReservation objectForKey:@"date"], [uneReservation objectForKey:@"adresse"]];
                }
            }
            
            
            
            UIApplicationState state = [[UIApplication sharedApplication] applicationState];
            
            //si app en background ou inactive alors envoyer notification. 
            if (state == UIApplicationStateBackground || state == UIApplicationStateInactive)
            {
                
                NSUInteger nbrReservations = [db intForQuery:@"select count(id) from reservations WHERE status != 'ignored'"];
                
                NSString* notifTitle = [[NSString alloc] initWithFormat:@"Vous avez des courses en attente"];
                
                [[UIApplication sharedApplication] cancelAllLocalNotifications];
                
                if(nbrReservations != 0){
                    busy = false;
                }
                
                Class cls = NSClassFromString(@"UILocalNotification");
                if (cls != nil && nbrReservations != 0) {
                    NSLog(@"Sending Notification to iOS");
                    [self.connection cancel];
                    busy = true;
                    pendingNotifications++;
                    UILocalNotification *notif = [[cls alloc] init];
                    notif.timeZone = [NSTimeZone defaultTimeZone];
                    notif.alertBody = notifTitle;
                    notif.alertAction = @"Afficher";
                    notif.soundName = UILocalNotificationDefaultSoundName;
                    notif.applicationIconBadgeNumber = 1;
                    [[UIApplication sharedApplication] presentLocalNotificationNow:notif];
                }
                
            }
            //sinon afficher directement le UIAlertView à l'écran. 
            else{
                FMResultSet *s = [db executeQuery:@"select * from reservations WHERE status != 'ignored'"];
                
                if ([db hadError]) {
                    NSLog(@"DB Error %d: %@", [db lastErrorCode], [db lastErrorMessage]);
                }
                
                while ([s next] && pendingAlertView == 0) {
                    busy = true;
                    NSString* depart = [[NSString alloc] initWithFormat:@"Client à %@", [s stringForColumn:@"depart"] ];
                    NSString* title = [[NSString alloc] initWithFormat:@"Course en attente #%d", [s intForColumn:@"id"]];
                    
                    UIAlertView *message = [[UIAlertView alloc] initWithTitle:title
                                                                message:depart
                                                                delegate:self
                                                                cancelButtonTitle:@"Accepter"
                                                                otherButtonTitles:@"Ignorer", nil];
                    [message show];
                    pendingAlertView++;
                    NSLog(@"Alert View In Download");
                }
                NSLog(@"Showing AlertView2 done. with %d", pendingAlertView);
            }
        
            if(pendingAlertView == 0 && pendingNotifications == 0){
                busy = false;
            }
        
        
        }
        //s'il n'y a pas de reservations en attente. 
        else{
            NSLog(@"No Pending Reservation");
        }
        
        
    }
    //si la reponse est de type accepterReservation. 
    else if([[json objectForKey:@"action"] isEqualToString:@"confirmationReservation"]){
        if([[json objectForKey:@"status"] isEqualToString:@"accepted"]){
            
            NSLog(@"json/confirmerReservation: %@",json);
            
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSString *dbPath = [documentsDirectory stringByAppendingPathComponent:@"db.sqlite"];
            FMDatabase *db = [FMDatabase databaseWithPath:dbPath];
            
            db.logsErrors = YES;
            
            if([db open]){
                NSLog(@"DB Opened in confirmer Reservation");
            }else{
                NSLog(@"DB Not Opened confirmer Reservation");
            }
            
            [db executeUpdateWithFormat:@"UPDATE reservations SET status = 'accepted' WHERE id = (%d)", [[json objectForKey:@"id"] intValue]];
            
            [activityIndicator stopAnimating];
            
            FMResultSet *s = [db executeQueryWithFormat:@"select * from reservations WHERE id = (%@)", [json objectForKey:@"id"]];
            if([s next]){
                if ([self.viewController respondsToSelector:@selector(selectedViewController)]) {
                    BRKHomeViewController* homeView = (BRKHomeViewController*)((UITabBarController*)self.viewController).selectedViewController;
                    if([homeView respondsToSelector:@selector(debugField)]){
                        homeView.debugField.text =  [[NSString alloc] initWithFormat:@"Adresse départ de votre client: %@",[s stringForColumn:@"depart"]];
                    }
                }
            }

        }else{
            
        }
    }
    
    
}


-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [self.receivedData appendData:data];
}


-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    NSLog(@"%@" , error);
}


-(void) makeBusy{
    [self.connection cancel];
    busy = true;
}

- (void) makeAvailable{
    busy = false;
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
