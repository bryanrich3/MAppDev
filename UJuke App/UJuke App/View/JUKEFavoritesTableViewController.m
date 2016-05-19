//
//  JUKEFavoritesTableViewController.m
//  UJuke
//
//  Created by Mohammed Kheder on 4/30/14.
//  Copyright (c) 2014 Chris Wendel. All rights reserved.
//

#import "JUKEFavoritesTableViewController.h"
#import "SWTableViewCell.h"
#import "JUKEFavoritesTableViewCell.h"
#import "ViewController.h"
#import "JUKETrack.h"

@interface JUKEFavoritesTableViewController ()

@property (nonatomic, weak) IBOutlet UITableView *favoritesTableView;
@property (nonatomic) BOOL useCustomCells;
@property (nonatomic, weak) UIRefreshControl *refreshControl;
@property (nonatomic, strong) NSMutableArray *trackObj;
@property (nonatomic, strong) NSString *filePath;

@end

@implementation JUKEFavoritesTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.favoritesTableView.delegate = self;
    self.favoritesTableView.dataSource = self;
    self.favoritesTableView.rowHeight = 55;
    
    
    // Setup refresh control for example app
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(toggleCells:) forControlEvents:UIControlEventValueChanged];
    refreshControl.tintColor = [UIColor colorWithRed:241.0/255.0 green:184.0/255.0 blue:45.0/255.0 alpha:1];
    
    [self.favoritesTableView addSubview:refreshControl];
    self.refreshControl = refreshControl;
    
    // If you set the seperator inset on iOS 6 you get a NSInvalidArgumentException...weird
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
        self.favoritesTableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0); // Makes the horizontal row seperator stretch the entire length of the table view
    }
    
    ViewController *tv = (ViewController *)[[self.tabBarController viewControllers] objectAtIndex:0];
    _filePath = tv.filePath;
    _trackObj = [[NSKeyedUnarchiver unarchiveObjectWithFile:_filePath] mutableCopy];
    
    self.edgesForExtendedLayout = UIRectEdgeAll;
    self.favoritesTableView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, CGRectGetHeight(self.tabBarController.tabBar.frame), 0.0f);
}

-(void)viewDidAppear:(BOOL)animated
{
    _trackObj = [[NSKeyedUnarchiver unarchiveObjectWithFile:_filePath] mutableCopy];
    
    [UIView setAnimationsEnabled:NO];
    [_refreshControl beginRefreshing];
    self.useCustomCells = !self.useCustomCells;
    
    [self.favoritesTableView reloadData];
    [_refreshControl endRefreshing];
    [UIView setAnimationsEnabled:YES];
}

-(UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_trackObj count];
}

#pragma mark - UIRefreshControl Selector

- (void)toggleCells:(UIRefreshControl*)refreshControl
{
    [refreshControl beginRefreshing];
    self.useCustomCells = !self.useCustomCells;
    
    [self.favoritesTableView reloadData];
    [refreshControl endRefreshing];
}

#pragma mark - UIScrollViewDelegate

- (JUKEFavoritesTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    JUKEFavoritesTableViewCell *cell = [self.favoritesTableView dequeueReusableCellWithIdentifier:@"FavoritesCell" forIndexPath:indexPath];
    
    cell.rightUtilityButtons = [self rightButtons];
    cell.delegate = self;
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    cell.favoritesAlbumArtImage.image = [[_trackObj objectAtIndex:indexPath.row] cover];
    cell.favoriteSongTitleLabel.text = [[_trackObj objectAtIndex:indexPath.row] track];
    cell.favoritesArtistLabel.text = [[_trackObj objectAtIndex:indexPath.row] artist];
    
    return cell;
    
    
}

- (NSArray *)rightButtons
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:241.0/255.0 green:184.0/255.0 blue:45.0/255.0 alpha:1]
                                                 icon:[UIImage imageNamed:@"delete.png"]];

    return rightUtilityButtons;
}


#pragma mark - SWTableViewDelegate

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
    switch (index) {
        case 0://DELETE button was pressed
        {
            NSIndexPath *cellIndexPath = [self.favoritesTableView indexPathForCell:cell];
            
            _trackObj = [[NSKeyedUnarchiver unarchiveObjectWithFile:_filePath] mutableCopy];
            
            [_trackObj removeObjectAtIndex:cellIndexPath.row];
            [self.favoritesTableView deleteRowsAtIndexPaths:@[cellIndexPath] withRowAnimation:UITableViewRowAnimationLeft];
            
            [NSKeyedArchiver archiveRootObject:_trackObj toFile:_filePath];
            
            break;
        }
        default:
            break;
    }
}

- (BOOL)swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:(SWTableViewCell *)cell {
    return YES;
}

@end

