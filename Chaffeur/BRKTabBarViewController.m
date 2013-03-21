//
//  BRKTabBarViewController.m
//  chauffeur
//
//  Created by Zakaria on 3/16/13.
//  Copyright (c) 2013 Zakaria. All rights reserved.
//

#import "BRKTabBarViewController.h"
#import "BRKHomeViewController.h"
#import "BRKParametresViewController.h"
#import "BRKLoginViewController.h"

@interface BRKTabBarViewController ()

@end

@implementation BRKTabBarViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        BRKHomeViewController *firstView = [[BRKHomeViewController alloc] initWithNibName:@"BRKHomeViewController" bundle:nil];
        
        //UINavigationController* navController = [[UINavigationController alloc] initWithRootViewController:firstView];
        
        BRKParametresViewController *secondView = [[BRKParametresViewController alloc] initWithNibName:@"BRKParametresViewController" bundle:nil];

        
        NSArray *viewControllersArray = [[NSArray alloc] initWithObjects:firstView, secondView, nil];
        
        
        [self setViewControllers:viewControllersArray];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
