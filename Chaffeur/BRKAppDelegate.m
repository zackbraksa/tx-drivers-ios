//
//  BRKAppDelegate.m
//  chauffeur
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
    
    NSLog(@"USER ID: %@",[self getUserId]);
    
    if([self getUserId] == NULL){
         BRKLoginViewController *firstView = [[BRKLoginViewController alloc] initWithNibName:@"BRKLoginViewController" bundle:nil];
        self.viewController = [[UINavigationController alloc] initWithRootViewController:firstView];
        ((UINavigationController*)self.viewController).navigationBar.tintColor = [UIColor blackColor];
        
    }else{
        self.viewController = [[BRKHomeViewController alloc] initWithNibName:@"BRKHomeViewController" bundle:nil];
    }
    
    //init badge number
    UIApplication* app = [UIApplication sharedApplication];
    app.applicationIconBadgeNumber = 0;
    
    //init db
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dbPath = [documentsDirectory stringByAppendingPathComponent:@"db.sqlite"];
    db = [FMDatabase databaseWithPath:dbPath];
    db.logsErrors = YES;
    
    if([db open]){
        NSLog(@"DB Open");
    }else{
        NSLog(@"DB Not Open");
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


- (void)applicationDidBecomeActive:(UIApplication *)application
{
    
    [locationManager stopMonitoringSignificantLocationChanges];
    [locationManager startUpdatingLocation];
    
    
    //we check if there is any pending reservations in the the internal database
    NSString* query = [[NSString alloc] initWithFormat:@"select count(id) from reservations WHERE status = 'accepted'"];
    NSUInteger count = [db intForQuery:query];
    
    
    //if there are any pending reservations we stop broadacasting 
    if(count != 0){
        busy = true;
    }
    
    //if the user is logged in and there is pending notifications then show all non-ignored reservations in the form of UIAlertViews
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
        NSURL *url = [NSURL URLWithString:@"http://test.braksa.com/tx/index.php/api/chauffeurs/acceptReservation/format/json"];
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
        
        NSLog(@"Driver accepts reservation");
        
    }
    else if([title isEqualToString:@"Ignorer"] || [title isEqualToString:@"Continuer"])
    {
        NSLog(@"Reservation %d Ignored ", [reservation_id intValue]);
        if(![title isEqualToString:@"Continuer"]){
            [db executeUpdateWithFormat:@"UPDATE reservations SET status = 'ignored' WHERE id = (%d)", [reservation_id intValue]];
        }
        
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
            UIApplication* app = [UIApplication sharedApplication];
            app.applicationIconBadgeNumber = 0;
            busy = false;
            NSLog(@"No more AlertViews to show. ");
        }
    }else{
        busy = false;
    }
    
}


-(void) locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{

    if([self getUserId] && !busy ){ //if user is logged in + not busy. 
        
        NSLog(@"Updating Position.");
        self.receivedData = [[NSMutableData alloc] init];
        BRKHomeViewController* homeView = (BRKHomeViewController*)self.viewController;
        homeView.addressLabel.text = [[NSString alloc] initWithFormat:@"%d", i];
        i++;
        


        //POST Req = send new position + get pending reservations from server
        NSURL *url = [NSURL URLWithString:@"http://test.braksa.com/tx/index.php/api/chauffeurs/position/format/json"];
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

-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    
    
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:self.receivedData
                          options:kNilOptions
                          error:nil];
    
    NSLog(@"...");
    
    //updatePosition
    if(json && [[json objectForKey:@"action"] isEqualToString:@"updatePosition"]){
        
        //pending reservations ON
        if([[json objectForKey:@"status"] isEqualToString:@"done"]){
            
            NSLog(@"There is at least a pending reservation");
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
            
            //in background
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
                
            }else{
                
                //select all non-ignored reservations. 
                FMResultSet *s = [db executeQuery:@"select * from reservations WHERE status != 'ignored'"];
                [self dbLogErrors];
                
                if ([s next]) {
                    [self.connection cancel];
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
        //no pending reservation 
        else{
            NSLog(@"No pending reservations.");
        }
        
        
    }
    //confirmationReservation 
    else if([[json objectForKey:@"action"] isEqualToString:@"confirmationReservation"]){
        
        //Reservation accepted
        if([[json objectForKey:@"status"] isEqualToString:@"accepted"]){
            
            NSLog(@"Reservation %d request was accepted by server", [[json objectForKey:@"id"] intValue]);
            
            [db executeUpdateWithFormat:@"UPDATE reservations SET status = 'accepted' WHERE id = (%d)", [[json objectForKey:@"id"] intValue]];
            [self dbLogErrors];
            
            FMResultSet *s = [db executeQueryWithFormat:@"SELECT * FROM reservations WHERE id = (%@)", [json objectForKey:@"id"]];
            
            [activityIndicator stopAnimating];
            
            if([s next]){
                BRKHomeViewController* homeView = (BRKHomeViewController*)self.viewController;
                homeView.titleLabel.text = @"Adresse du client";
                homeView.addressLabel.text =  [[NSString alloc] initWithFormat:@"%@",[s stringForColumn:@"depart"]];
                
                //hide busy/available buttons
                [homeView.busyButton setHidden:YES];
                [homeView.availableButton setHidden:YES];
                
                //show cancel/remind client buttons
                [homeView.cancelButton setHidden:NO];
                [homeView.rappelerButton setHidden:NO];
                
                //empty status label
                homeView.statusLabel.text = @"";
                
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                NSString* idReservation = [[NSString alloc] initWithFormat:@"%@",[json objectForKey:@"id"]];
                [defaults setObject:idReservation  forKey:@"idReservation"];
                NSLog(@"idReservation was set !! %@", [json objectForKey:@"id"]);
            }
            
            pendingNotifications = 0; //no pending notifications to show anymore.

        //Reservation not accepted
        }else{

            NSLog(@"Reservation not accepted");
            NSLog(@"Canceling Reservation %d", [[json objectForKey:@"id"] intValue]);
            
            
            [db executeUpdateWithFormat:@"UPDATE reservations SET status = 'ignored' WHERE id = (%d)", [[json objectForKey:@"id"] intValue]];
            [self dbLogErrors];
            
            
            NSLog(@"Request refused");
            [activityIndicator stopAnimating];
            UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Requete refusée."
                                                              message:@"Votre requete à était refusé par notre serveur."
                                                             delegate:self
                                                    cancelButtonTitle:@"Continuer"
                                                    otherButtonTitles:@"Ignorer", nil];
            [message show];
        }
        
    //cancelReservation
    }else if([[json objectForKey:@"action"] isEqualToString:@"cancelReservation"]){
        
        //done
        if([[json objectForKey:@"status"] isEqualToString:@"done"]){
            
            [db executeUpdateWithFormat:@"UPDATE reservations SET status = 'ignored' WHERE id = (%d)", [[json objectForKey:@"id"] intValue]];
            
            [activityIndicator stopAnimating];
            
            //make driver available again
            busy = false;
            
            BRKHomeViewController* homeView = (BRKHomeViewController*)self.viewController;
            //show the busy/available buttons 
            [homeView.busyButton setHidden:NO];
            [homeView.availableButton setHidden:NO];
                
                //hide all other buttons 
            [homeView.cancelButton setHidden:YES];
            [homeView.rappelerButton setHidden:YES];
            [homeView.terminerButton setHidden:YES];
                
            //homeView.statusLabel.text = @"Vous allez recevoir une notification dès qu'une course est disponible.";
            homeView.addressLabel.text = @"En Ligne";
            
        }else{
            //can't be done
            NSLog(@"Can't cancel reservation.");
        }
        
    //unknown response
    }else{
        NSLog(@"Couldn't handle this request");
            NSLog(@"%@",json);
    }

}


- (void)requestFinished:(id)request {
    UIBackgroundTaskIdentifier backgroundTask = 0;
    
    [[UIApplication sharedApplication] endBackgroundTask:backgroundTask];
    backgroundTask = UIBackgroundTaskInvalid;
}

- (void) cancelCourse{
    
    FMResultSet *s = [db executeQuery:@"SELECT * FROM reservations WHERE status = 'accepted'"];
    [self dbLogErrors];
    
    if([s next]){
        NSString* id = [s stringForColumn:@"id"];
        NSLog(@"Canceling Reservation %@", id);
        self.receivedData = [[NSMutableData alloc] init];
        NSURL *url = [NSURL URLWithString:@"http://test.braksa.com/tx/index.php/api/chauffeurs/cancelReservation/format/json"];
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
    [db executeUpdate:@"UPDATE reservations SET status = 'ignored' WHERE status = 'accepted'"];
    [self.connection cancel];
    busy = false;
    NSLog(@"Making Driver Available");
}

- (void)applicationWillTerminate:(UIApplication *)application{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}
- (void)applicationWillResignActive:(UIApplication *)application{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}
- (void)applicationDidEnterBackground:(UIApplication *)application{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    [locationManager startMonitoringSignificantLocationChanges];
    
    //[locationManager stopMonitoringSignificantLocationChanges];
    //[locationManager startUpdatingLocation];
    
}
- (void)applicationWillEnterForeground:(UIApplication *)application{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}


@end
