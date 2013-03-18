//
//  BRKLoginViewController.h
//  Chaffeur
//
//  Created by Zakaria on 3/16/13.
//  Copyright (c) 2013 Zakaria. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BRKLoginViewController : UIViewController <UIActionSheetDelegate>{
    UIActivityIndicatorView *activityIndicator;
}

@property (unsafe_unretained, nonatomic) IBOutlet UITextField *emailField;
@property (unsafe_unretained, nonatomic) IBOutlet UITextField *passwordField;
@property (retain, nonatomic) NSURLConnection *connection;
@property (retain, nonatomic) NSMutableData *receivedData;

- (IBAction)connexionAction:(id)sender;
- (IBAction)creerCompteAction:(id)sender;
- (IBAction)textFieldDoneEditing:(id)sender;
- (IBAction)backgroundTap:(id)sender;

@end
