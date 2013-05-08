//
//  BRKHomeViewController.m
//  chauffeur
//
//  Created by Zakaria on 3/16/13.
//  Copyright (c) 2013 Zakaria. All rights reserved.
//

#import "BRKHomeViewController.h"
#import "BRKAppDelegate.h"
#import "BRKParametresViewController.h"


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

- (IBAction)bringConfiguration:(id)sender {
    BRKParametresViewController *paramView =[[BRKParametresViewController alloc]init];
    [self presentModalViewController:paramView animated:YES];
}

- (IBAction)rappelerAction:(id)sender {
    
    [self.connection cancel];
    NSMutableData *data = [[NSMutableData alloc] init];
    self.receivedData = data;
    
    NSURL *url = [NSURL URLWithString:@"http://test.braksa.com/tx/index.php/api/chauffeurs/rappel/format/json"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[url standardizedURL]];
    [request setHTTPMethod:@"POST"];
    NSString *postData = [[NSString alloc] initWithFormat:@"idReservation=%@",[self getReservationId]];
    [request setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[postData dataUsingEncoding:NSUTF8StringEncoding]];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    self.connection = connection;
    [connection start];
}

- (IBAction)terminerAction:(id)sender {

    [self.connection cancel];
    NSMutableData *data = [[NSMutableData alloc] init];
    self.receivedData = data;
    NSURL *url = [NSURL URLWithString:@"http://test.braksa.com/tx/index.php/api/chauffeurs/terminer/format/json"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[url standardizedURL]];
    [request setHTTPMethod:@"POST"];
    NSString *postData = [[NSString alloc] initWithFormat:@"idReservation=%@",[self getReservationId]];
    [request setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[postData dataUsingEncoding:NSUTF8StringEncoding]];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    self.connection = connection;
    [connection start];
}

- (NSString*) getUserId{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *user_id = [defaults objectForKey:@"user_id"];
    return user_id;
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [self.receivedData appendData:data];
}
-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
        
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Erreur Connexion!"
                                                      message:@"Vérifier que vous êtes connecté"
                                                     delegate:nil
                                            cancelButtonTitle:@"OK!"
                                            otherButtonTitles:nil];
    [message show];
    
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    
    
    
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:self.receivedData
                          options:kNilOptions
                          error:nil];
    
    NSLog(@"Home[json] :%@",json);
    
    if([[json objectForKey:@"action"] isEqualToString:@"rappel"])
    {
        if([[json objectForKey:@"status"] isEqualToString:@"done"]){
            [self.rappelerButton setHidden:YES];
            [self.terminerButton setHidden:NO];
        }else{
            NSLog(@"Rappel wasn't sent");
        }
        
    }else if([[json objectForKey:@"action"] isEqualToString:@"terminer"]){
        if([[json objectForKey:@"status"] isEqualToString:@"done"]){
            [self.availableButton setHidden:NO];
            [self.busyButton setHidden:NO];
            [self.terminerButton setHidden:YES];
            self.statusLabel.text = @"Vous allez recevoir une notification dès qu'une course est disponible.";
            
        }else{
            NSLog(@"Terminer wasn't sent");
        }
    }
    
}

- (NSString*)getReservationId{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:@"idReservation"];
}


- (void)viewDidUnload {
    [self setBusyButton:nil];
    [self setAvailableButton:nil];
    [self setStatusLabel:nil];
    [self setTitleLabel:nil];
    [self setAddressLabel:nil];
    [self setCancelButton:nil];
    [self setTerminerButton:nil];
    [self setRappelerButton:nil];
    [super viewDidUnload];
}

@end
