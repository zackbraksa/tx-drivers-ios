//
//  BRKHomeViewController.m
//  chauffeur
//
//  Created by Zakaria on 3/16/13.
//  Copyright (c) 2013 Zakaria. All rights reserved.
//

#import "BRKHomeViewController.h"
#import "BRKAppDelegate.h"
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
        
        /* change tab item title */
        UITabBarItem* tbi = [self tabBarItem];
        [tbi setTitle:@"Tableau de bord"];
        UIImage* i = [UIImage imageNamed:@"house.png"];
        [tbi setImage:i];
    }
    return self;
}


- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:YES];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if([defaults objectForKey:@"depart"]){
        self.titleLabel.text = @"Adresse du client";
        self.addressLabel.text =  [[NSString alloc] initWithFormat:@"%@",[defaults objectForKey:@"depart"]];
        [self.busyButton setHidden:YES];
        [self.availableButton setHidden:YES];
        [self.cancelButton setHidden:NO];
        self.statusLabel.text = @"";
    }
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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cancelCourseAction:(id)sender {
    BRKAppDelegate *appDelegate = (BRKAppDelegate *)[[UIApplication sharedApplication ] delegate];
    [appDelegate cancelCourse];
    self.titleLabel.text = @"";
}

- (IBAction)busyAction:(id)sender {
    BRKAppDelegate *appDelegate = (BRKAppDelegate *)[[UIApplication sharedApplication ] delegate];
    [appDelegate makeBusy];
    [self.availableButton setEnabled:YES];
    [sender setEnabled:NO];
    self.statusLabel.text = @"Vous avez opté pour ne plus recevoir de course.";
    
}

- (IBAction)availableAction:(id)sender {
    BRKAppDelegate *appDelegate = (BRKAppDelegate *)[[UIApplication sharedApplication ] delegate];
    [appDelegate makeAvailable];
    [sender setEnabled:NO];
    [self.busyButton setEnabled:YES];
    self.statusLabel.text = @"Vous allez recevoir une notification dès qu'une course est disponible.";

    


}
- (void)viewDidUnload {
    [self setBusyButton:nil];
    [self setAvailableButton:nil];
    [self setStatusLabel:nil];
    [self setTitleLabel:nil];
    [self setAddressLabel:nil];
    [self setCancelButton:nil];
    [super viewDidUnload];
}

@end
