//
//  BRKHomeViewController.m
//  Chaffeur
//
//  Created by Zakaria on 3/16/13.
//  Copyright (c) 2013 Zakaria. All rights reserved.
//

#import "BRKHomeViewController.h"
#import "BRKAppDelegate.h"
#import "FMDatabase.h"
@interface BRKHomeViewController ()

@end

@implementation BRKHomeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        //UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(fetchReservation)];
        //self.navigationItem.rightBarButtonItem = button;
        
        BRKAppDelegate *appDelegate = (BRKAppDelegate *)[[UIApplication sharedApplication ] delegate];
        [appDelegate makeAvailable];
        
        
        

        
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *dbPath = [documentsDirectory stringByAppendingPathComponent:@"db.sqlite"];
        
        FMDatabase *db = [FMDatabase databaseWithPath:dbPath];
        
        db.logsErrors = YES;

        
        if([db open]){
            NSLog(@"Opened");
        }else{
            NSLog(@"Not Opened");  
        }
        
        
        FMResultSet *s = [db executeQuery:@"select * from reservations"];
        if ([db hadError]) {
            NSLog(@"DB Error %d: %@", [db lastErrorCode], [db lastErrorMessage]); }
        while ([s next]) {
            NSLog(@"Sqlite %@",[s resultDictionary]);
        }
        
        

        
        /* change tab item title */
        UITabBarItem* tbi = [self tabBarItem];
        [tbi setTitle:@"Tableau de bord"];
        UIImage* i = [UIImage imageNamed:@"globe.png"];
        [tbi setImage:i];
    }
    return self;
}


- (void)viewDidLoad
{
    BRKAppDelegate *appDelegate = (BRKAppDelegate *)[[UIApplication sharedApplication ] delegate];
    BOOL busy = [appDelegate getBusyStatus];
    if(busy){
        [self.busyButton setEnabled:NO];
    }else{
        [self.availableButton setEnabled:NO];
    }
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)busyAction:(id)sender {
    BRKAppDelegate *appDelegate = (BRKAppDelegate *)[[UIApplication sharedApplication ] delegate];
    [appDelegate makeBusy];
    [self.availableButton setEnabled:YES];
    [sender setEnabled:NO];
    
}

- (IBAction)availableAction:(id)sender {
    BRKAppDelegate *appDelegate = (BRKAppDelegate *)[[UIApplication sharedApplication ] delegate];
    [appDelegate makeAvailable];
    [self.busyButton setEnabled:YES];
    [sender setEnabled:NO];


}
- (void)viewDidUnload {
    [self setDebugField:nil];
    [self setBusyButton:nil];
    [self setAvailableButton:nil];
    [super viewDidUnload];
}

@end
