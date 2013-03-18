//
//  BRKParametresViewController.m
//  Chaffeur
//
//  Created by Zakaria on 3/16/13.
//  Copyright (c) 2013 Zakaria. All rights reserved.
//

#import "BRKParametresViewController.h"
#import "BRKLoginViewController.h"
#import "BRKAppDelegate.h"

@interface BRKParametresViewController ()

@end

@implementation BRKParametresViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        //UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(fetchReservation)];
        //self.navigationItem.rightBarButtonItem = button;
        
        /* change tab item title */
        
        UITabBarItem* tbi = [self tabBarItem];
        [tbi setTitle:@"Paramétres"];
        UIImage* i = [UIImage imageNamed:@"globe.png"];
        [tbi setImage:i];
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [super viewDidUnload];
}
- (IBAction)deconnexionPressed:(id)sender {
    BRKAppDelegate *appDelegate = (BRKAppDelegate *)[[UIApplication sharedApplication ] delegate];
    [appDelegate makeBusy];
    
    //[SSKeychain deletePasswordForService:@"loginService" account:@"AnyUser"];
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    
    BRKLoginViewController *loginView = [[BRKLoginViewController alloc] initWithNibName:@"BRKLoginViewController" bundle:nil];
    UIViewController *loginNavigationControllerView = [[UINavigationController alloc] initWithRootViewController:loginView];
    
    ((UINavigationController*)loginNavigationControllerView).navigationBar.tintColor = [UIColor blackColor];
    
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    window.rootViewController = loginNavigationControllerView;
}

@end
