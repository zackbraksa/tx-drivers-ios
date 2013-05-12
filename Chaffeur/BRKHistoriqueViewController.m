//
//  BRKHistoriqueViewController.m
//  Chaffeur
//
//  Created by Zakaria on 5/12/13.
//  Copyright (c) 2013 Zakaria. All rights reserved.
//

#import "BRKHistoriqueViewController.h"
#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"

@interface BRKHistoriqueViewController ()

@end

@implementation BRKHistoriqueViewController
{
    NSMutableArray *tableData;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //init db
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dbPath = [documentsDirectory stringByAppendingPathComponent:@"db.sqlite"];
    db = [FMDatabase databaseWithPath:dbPath];
    db.logsErrors = YES;
    
    if([db open]){
        NSLog(@"DB Open");
    }else{
        NSLog(@"DB Not Open");
    }
    
    tableData = [[NSMutableArray alloc] init];
    
    FMResultSet *s = [db executeQuery:@"select * from reservations"];
    
    while([s next]) {
        
        NSString* cell = [[NSString alloc] initWithFormat:@"%@ (%@)",[s stringForColumn:@"depart"],[s stringForColumn:@"status"]];
        [tableData addObject:cell];

    }
    
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    [self.tableView reloadData];
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [tableData count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"SimpleTableItem";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    cell.textLabel.text = [tableData objectAtIndex:indexPath.row];
    return cell;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)goBack:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidUnload {
    [self setTableView:nil];
    [super viewDidUnload];
}
@end
