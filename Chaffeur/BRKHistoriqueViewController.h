//
//  BRKHistoriqueViewController.h
//  Chaffeur
//
//  Created by Zakaria on 5/12/13.
//  Copyright (c) 2013 Zakaria. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FMDatabase;


@interface BRKHistoriqueViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>{
    
    FMDatabase *db;
}

@property (unsafe_unretained, nonatomic) IBOutlet UITableView *tableView;

- (IBAction)goBack:(id)sender;

@end
