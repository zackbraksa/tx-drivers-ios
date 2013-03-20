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
    [self performSelector:@selector(createEditableCopyOfDatabaseIfNeeded) withObject:nil];
    
    //basic initialization
    pendingAlertView = 0;
    pendingNotifications = 0;
    
    
    if([self getUserId] == NULL){
         BRKLoginViewController *firstView = [[BRKLoginViewController alloc] initWithNibName:@"BRKLoginViewController" bundle:nil];
        self.viewController = [[UINavigationController alloc] initWithRootViewController:firstView];
        ((UINavigationController*)self.viewController).navigationBar.tintColor = [UIColor blackColor];
        
    }else{
        self.viewController = [[BRKTabBarViewController alloc] initWithNibName:@"BRKHomeViewController" bundle:nil];
    }
    
    //init db
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dbPath = [documentsDirectory stringByAppendingPathComponent:@"db.sqlite"];
    db = [FMDatabase databaseWithPath:dbPath];
    db.logsErrors = YES;
    
    if([db open]){
        NSLog(@"DB Opened");
    }else{
        NSLog(@"DB Not Opened");
    }
    
    //init location manager
    locationManager = [[CLLocationManager alloc] init];
    [locationManager setDelegate:self];
    [locationManager setDistanceFilter:kCLDistanceFilterNone];
    [locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (NSString*) getUserId{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *user_id = [defaults objectForKey:@"user_id"];
    return user_id;
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
    
    [locationManager startMonitoringSignificantLocationChanges];
    
    //[locationManager stopMonitoringSignificantLocationChanges];
    //[locationManager startUpdatingLocation];

}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    //Enter Foreground
    
    [locationManager stopMonitoringSignificantLocationChanges];
    [locationManager startUpdatingLocation];
    
    NSString* query = [[NSString alloc] initWithFormat:@"select count(id) from reservations WHERE status = 'accepted'"];
    NSUInteger count = [db intForQuery:query];
    
    if(count != 0){
        busy = true;
    }
    
    //if user is logged in + there pending notifications + busy.
    if([self getUserId] && pendingNotifications != 0){
        
        //get non-ignored reservations. 
        FMResultSet *s = [db executeQuery:@"select * from reservations WHERE status != 'ignored'"];
        [self dbLogErrors];        
        
        if ([s next]) {
            NSString* depart = [[NSString alloc] initWithFormat:@"Client à %@", [s stringForColumn:@"depart"] ];
            NSString* title = [[NSString alloc] initWithFormat:@"Course en attente #%d", [s intForColumn:@"id"]];
            UIAlertView *message = [[UIAlertView alloc] initWithTitle:title
                                                              message:depart
                                                             delegate:self
                                                    cancelButtonTitle:@"Accepter"
                                                    otherButtonTitles:@"Ignorer", nil];
            [message show];
        }

    }

    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    //fetch id reservation fron alertview title. 
    NSRange searchRange = NSMakeRange([[alertView title] rangeOfString:@"#"].location + 1, (alertView.title.length - [[alertView title] rangeOfString:@"#"].location - 1));
    NSString* reservation_id = [[alertView title] substringWithRange:searchRange];
    //--
    
    
    NSUInteger count = [db intForQuery:@"SELECT count(id) FROM reservations WHERE status = 'accepted'"];
    
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    if([title isEqualToString:@"Accepter"] && count == 0)
    {
        self.receivedData = [[NSMutableData alloc] init];
        NSURL *url = [NSURL URLWithString:@"http://localhost:8888/tx/index.php/api/chaffeurs/acceptReservation/format/json"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[url standardizedURL]];
        [request setHTTPMethod:@"POST"];
        NSString *postData = [[NSString alloc] initWithFormat:@"idReservation=%@&idChauffeur=%@", reservation_id, [self getUserId]];
        [request setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:[postData dataUsingEncoding:NSUTF8StringEncoding]];
        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        self.connection = connection; [connection start];
        
        activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        activityIndicator.layer.backgroundColor = [[UIColor colorWithWhite:0.0f alpha:0.5f] CGColor];
        activityIndicator.hidesWhenStopped = YES;
        activityIndicator.frame = self.window.bounds;
        [self.window addSubview:activityIndicator];
        [activityIndicator startAnimating];
        
    }
    else if([title isEqualToString:@"Ignorer"])
    {        
        [db executeUpdateWithFormat:@"UPDATE reservations SET status = 'ignored' WHERE id = (%d)", [reservation_id intValue]];
        //fetch reservations restantes
        FMResultSet *s = [db executeQuery:@"select * from reservations WHERE status != 'ignored'"]; [self dbLogErrors];
        
        //show the next reservation in AlertView. 
        if ([s next]) {
            NSString* depart = [[NSString alloc] initWithFormat:@"Client à %@", [s stringForColumn:@"depart"] ];
            NSString* title = [[NSString alloc] initWithFormat:@"Course en attente #%d", [s intForColumn:@"id"]];
            UIAlertView *message = [[UIAlertView alloc] initWithTitle:title
                                                              message:depart
                                                             delegate:self
                                                    cancelButtonTitle:@"Accepter"
                                                    otherButtonTitles:@"Ignorer", nil];
            [message show];
        }else{
            pendingNotifications = 0;
            pendingAlertView = 0;
            busy = false;
            NSLog(@"No more AlertViews to show. ");
        }
    }else if([title isEqualToString:@"Continuer"]){
        //afficher le reste des AlertViews.
    }
    
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}
-(void) locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{

    if([self getUserId] && !busy ){ //if user is logged in + not busy. 
        
        self.receivedData = [[NSMutableData alloc] init];
        if ([self.viewController respondsToSelector:@selector(selectedViewController)]) {
            BRKHomeViewController* homeView = (BRKHomeViewController*)((UITabBarController*)self.viewController).selectedViewController;
            //if([homeView respondsToSelector:@selector(debugField)]) homeView.debugField.text = [[NSString alloc] initWithFormat:@"sent %d", i];
            if([homeView respondsToSelector:@selector(debugField)]) homeView.debugField.text = [[NSString alloc] initWithFormat:@"sent %d", i];
            i++;
        }

        //POST Req = send new position + get pending reservations from server 
        NSURL *url = [NSURL URLWithString:@"http://localhost:8888/tx/index.php/api/chaffeurs/position/format/json"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[url standardizedURL]];
        [request setHTTPMethod:@"POST"];
        NSString *postData = [[NSString alloc] initWithFormat:@"id=%@&latitude=%f&longitude=%f",[self getUserId], newLocation.coordinate.latitude, newLocation.coordinate.longitude];
        [request setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:[postData dataUsingEncoding:NSUTF8StringEncoding]];
        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        self.connection = connection;
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
    
    NSLog(@"...");
    
    //si la reponse est de type updatePosition (+ Recevoir les reservations en cours).
    if(json && [[json objectForKey:@"action"] isEqualToString:@"updatePosition"]){
        
        //s'il y a des reservations en attente
        if([[json objectForKey:@"status"] isEqualToString:@"done"]){
            
            NSLog(@"There is a Pending Reservations");
            NSArray* reservations = [json objectForKey:@"reservation"];
            
            for(int j = 0; j < [reservations count]; j++){
                
                NSDictionary* uneReservation = [reservations objectAtIndex:j];
                NSString* query = [[NSString alloc] initWithFormat:@"select count(id) from reservations WHERE id = (%d)",[[uneReservation objectForKey:@"id"] intValue]];
                NSUInteger count = [db intForQuery:query];
                
                //insert if and only if reservation doesn't already exist. 
                if(count == 0){
                    [db executeUpdate:@"INSERT INTO reservations(id,latitude, longitude,status,date, depart) VALUES (?, ?, ?, ?, ?, ?)",[uneReservation objectForKey:@"id"],[uneReservation objectForKey:@"latitude"],[uneReservation objectForKey:@"longitude"],[uneReservation objectForKey:@"status"],[uneReservation objectForKey:@"date"], [uneReservation objectForKey:@"adresse"]];
                }
            }
            
            UIApplicationState state = [[UIApplication sharedApplication] applicationState];
            
            //si app en background ou inactive alors envoyer notification. 
            if (state == UIApplicationStateBackground || state == UIApplicationStateInactive)
            {
                
                NSUInteger countPendingReservations = [db intForQuery:@"select count(id) from reservations WHERE status != 'ignored'"];
                [self dbLogErrors];
                NSString* notifTitle = [[NSString alloc] initWithFormat:@"Vous avez des courses en attente"];
                [[UIApplication sharedApplication] cancelAllLocalNotifications];
                
                Class cls = NSClassFromString(@"UILocalNotification");
                if (cls != nil && countPendingReservations != 0) {
                    [self.connection cancel];   //cancel ongoing connections. 
                    busy = true;                //stop receiving pending reservations from server. 
                    pendingNotifications = 1;
                    UILocalNotification *notif = [[cls alloc] init];
                    notif.timeZone = [NSTimeZone defaultTimeZone];
                    notif.alertBody = notifTitle;
                    notif.alertAction = @"Afficher";
                    notif.soundName = UILocalNotificationDefaultSoundName;
                    notif.applicationIconBadgeNumber = countPendingReservations;
                    [[UIApplication sharedApplication] presentLocalNotificationNow:notif];
                }
                
            }
            //sinon afficher directement les reservations dans des AlertViews. 
            else{
                
                //select all non-ignored reservations. 
                FMResultSet *s = [db executeQuery:@"select * from reservations WHERE status != 'ignored'"];
                [self dbLogErrors];
                
                if ([s next]) {
                    busy = true; //stop receiving pending reservations from server. 
                    NSLog(@"Showing First Pending Reservation in AlertView from DB.");
                    NSString* depart = [[NSString alloc] initWithFormat:@"Client à %@", [s stringForColumn:@"depart"] ];
                    NSString* title = [[NSString alloc] initWithFormat:@"Course en attente #%d", [s intForColumn:@"id"]];
                    UIAlertView *message = [[UIAlertView alloc] initWithTitle:title
                                                                message:depart
                                                                delegate:self
                                                                cancelButtonTitle:@"Accepter"
                                                                otherButtonTitles:@"Ignorer", nil];
                    [message show];
                    pendingAlertView = 1;
                }
            }
        
        }
        //s'il n'y a pas de reservations en attente. 
        else{
            NSLog(@"No Pending Reservation on server.");
        }
        
        
    }
    //si la reponse est de type accepterReservation. 
    else if([[json objectForKey:@"action"] isEqualToString:@"confirmationReservation"]){
        if([[json objectForKey:@"status"] isEqualToString:@"accepted"]){
            
            NSLog(@"Reservation request was accepted by server.");
            
            [db executeUpdateWithFormat:@"UPDATE reservations SET status = 'accepted' WHERE id = (%d)", [[json objectForKey:@"id"] intValue]];
            [self dbLogErrors];
            
            //get [reservation client address] to display it to user. 
            FMResultSet *s = [db executeQueryWithFormat:@"SELECT * FROM reservations WHERE id = (%@)", [json objectForKey:@"id"]];
            
            if([s next]){
                if ([self.viewController respondsToSelector:@selector(selectedViewController)]) {
                    BRKHomeViewController* homeView = (BRKHomeViewController*)((UITabBarController*)self.viewController).selectedViewController;
                    if([homeView respondsToSelector:@selector(debugField)]){
                        homeView.debugField.text =  [[NSString alloc] initWithFormat:@"%@",[s stringForColumn:@"depart"]];
                    }
                }
            }
            
            [activityIndicator stopAnimating];
            pendingNotifications = 0; //no pending notifications to show anymore.

        }else{
            //afficher AlertView d'erreur + Bouton Continuer
        }
    }else if([[json objectForKey:@"action"] isEqualToString:@"cancelReservation"]){
        if([[json objectForKey:@"status"] isEqualToString:@"done"]){
            [db executeUpdateWithFormat:@"UPDATE reservations SET status = 'ignored' WHERE id = (%d)", [[json objectForKey:@"id"] intValue]];
            [activityIndicator stopAnimating];
            busy = false;
        }else{
            NSLog(@"Can't cancel reservation.");
        }
    }

}

- (void) cancelCourse{
    FMResultSet *s = [db executeQuery:@"SELECT * FROM reservations WHERE status = 'accepted'"];
    [self dbLogErrors];
    
    if([s next]){
        NSString* id = [s stringForColumn:@"id"];
        NSLog(@"Canceling Reservation %@", id);
        self.receivedData = [[NSMutableData alloc] init];
        NSURL *url = [NSURL URLWithString:@"http://localhost:8888/tx/index.php/api/chaffeurs/cancelReservation/format/json"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[url standardizedURL]];
        [request setHTTPMethod:@"POST"];
        NSString *postData = [[NSString alloc] initWithFormat:@"idReservation=%@", id];
        [request setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:[postData dataUsingEncoding:NSUTF8StringEncoding]];
        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        self.connection = connection; [connection start];
        
        activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        activityIndicator.layer.backgroundColor = [[UIColor colorWithWhite:0.0f alpha:0.5f] CGColor];
        activityIndicator.hidesWhenStopped = YES;
        activityIndicator.frame = self.window.bounds;
        [self.window addSubview:activityIndicator];
        [activityIndicator startAnimating];
    }
}
- (void) dbLogErrors{
    if ([db hadError]) {
        NSLog(@"DB Error %d: %@", [db lastErrorCode], [db lastErrorMessage]);
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
-(BOOL)getBusyStatus{
    return busy;
}
- (void) makeAvailable{
    [self.connection cancel];
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
