//
//  BRKHomeViewController.h
//  chauffeur
//
//  Created by Zakaria on 3/16/13.
//  Copyright (c) 2013 Zakaria. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BRKHomeViewController : UIViewController

- (IBAction)cancelCourseAction:(id)sender;
- (IBAction)busyAction:(id)sender;
- (IBAction)availableAction:(id)sender;

@property (unsafe_unretained, nonatomic) IBOutlet UIButton *busyButton;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *availableButton;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *statusLabel;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *titleLabel;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *addressLabel;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *cancelButton;

@end
