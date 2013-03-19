//
//  BRKLoginViewController.m
//  Chaffeur
//
//  Created by Zakaria on 3/16/13.
//  Copyright (c) 2013 Zakaria. All rights reserved.
//

#import "BRKLoginViewController.h"
#import "BRKSignupViewController.h"
#import "BRKTabBarViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface BRKLoginViewController ()

@end

@implementation BRKLoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated{
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
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
    [self setEmailField:nil];
    [self setPasswordField:nil];
    [super viewDidUnload];
}


- (IBAction)connexionAction:(id)sender {
    NSLog(@"LOGIN");
    
    //check login/password using web service
    
    //if there is a connection going on just cancel it.
    [self.connection cancel];
    
    //initialize new mutable data
    NSMutableData *data = [[NSMutableData alloc] init];
    self.receivedData = data;
    
    //initialize url that is going to be fetched.
    NSURL *url = [NSURL URLWithString:@"http://localhost:8888/tx/index.php/api/chaffeurs/connecter/format/json"];
    
    //initialize a request from url
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[url standardizedURL]];
    
    //set http method
    [request setHTTPMethod:@"POST"];
    //initialize a post data
    NSString *postData = [[NSString alloc] initWithFormat:@"email=%@&pwd=%@", [self.emailField text], [self.passwordField text]];
    
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
    activityIndicator.frame = self.view.bounds;
    [self.view addSubview:activityIndicator];
    [activityIndicator startAnimating];
}

- (IBAction)creerCompteAction:(id)sender {
    BRKSignupViewController *SigninView = [[BRKSignupViewController alloc] initWithNibName:@"BIDSigninViewController" bundle:nil];
    
    [[self navigationController] pushViewController:SigninView animated:YES];
}

- (IBAction)textFieldDoneEditing:(id)sender {
    NSLog(@"Return");
    [sender resignFirstResponder];
}

- (IBAction)backgroundTap:(id)sender {
    [self.emailField resignFirstResponder];
    [self.passwordField resignFirstResponder];
}


-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [self.receivedData appendData:data];
}


-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    
    [activityIndicator stopAnimating];
    
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Erreur Connexion!"
                                                      message:@"Vérifier que vous êtes connecté"
                                                     delegate:nil
                                            cancelButtonTitle:@"OK!"
                                            otherButtonTitles:nil];
    [message show];
    
}


-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
    
    
    [activityIndicator stopAnimating];
    
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:self.receivedData
                          options:kNilOptions
                          error:nil];
    
    NSLog(@"json: %@",json);
    
    
    if([[json objectForKey:@"status"] isEqualToString:@"done"])
    {
        NSLog(@"user_id : %@",[json objectForKey:@"profil"]);
        //[SSKeychain setPassword:[self.passwordField text] forService:@"loginService" account:@"AnyUser"];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:[json objectForKey:@"user_id"] forKey:@"user_id"];
        
        
        BRKTabBarViewController *homeView = [[BRKTabBarViewController alloc] initWithNibName:@"BRKTabBarViewController" bundle:nil];
        UIWindow *window = [[UIApplication sharedApplication] keyWindow];
        window.rootViewController = homeView;
        
        
    }else{
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Erreur authentification!"
                                                          message:@"Mauvaise combinaison Login/Mot de Passe."
                                                         delegate:nil
                                                cancelButtonTitle:@"Réessayez"
                                                otherButtonTitles:nil];
        [message show];
    }
}


@end
