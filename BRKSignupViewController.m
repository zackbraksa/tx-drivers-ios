//
//  BRKSignupViewController.m
//  Chaffeur
//
//  Created by Zakaria on 3/21/13.
//  Copyright (c) 2013 Zakaria. All rights reserved.
//

#import "BRKSignupViewController.h"

@interface BRKSignupViewController ()

@end

@implementation BRKSignupViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
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
    [self setNavigationBar:nil];
    [super viewDidUnload];
}
- (IBAction)cancelAction:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}
@end
