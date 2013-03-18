//
//  BRKHomeViewController.h
//  Chaffeur
//
//  Created by Zakaria on 3/16/13.
//  Copyright (c) 2013 Zakaria. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BRKHomeViewController : UIViewController
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *debugField;
- (IBAction)busyAction:(id)sender;
- (IBAction)availableAction:(id)sender;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *busyButton;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *availableButton;

@end
