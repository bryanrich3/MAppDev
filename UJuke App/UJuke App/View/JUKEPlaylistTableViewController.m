//
//  JUKEPlaylistTableViewController.m
//  UJuke
//
//  Created by Mohammed Kheder on 4/30/14.
//  Copyright (c) 2014 UJuke. All rights reserved.
//

#import "JUKEPlaylistTableViewController.h"
#import "SWTableViewCell.h"
#import "JUKEPlaylistTableViewCell.h"
#import "ViewController.h"
#import "JUKETrack.h"
#import "JUKESocket.h"

@interface JUKEPlaylistTableViewController ()

@property (nonatomic, weak) IBOutlet UITableView *playlistTableView;
@property (nonatomic) BOOL useCustomCells;
@property (nonatomic, weak) UIRefreshControl *refreshControl;
@property (nonatomic, strong) NSArray *trackObj;
@property (nonatomic, strong) NSMutableArray *trackFav;
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) JUKESocket *socket;
@property (nonatomic, strong) NSString *beacon;

@property (nonatomic, strong) NSMutableArray *filteredTrackArray;

@end

bool isFiltered;

@implementation JUKEPlaylistTableViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.playlistTableView.delegate = self;
    self.playlistTableView.dataSource = self;
    self.playlistTableView.rowHeight = 55;
    
    // Setup refresh control for example app
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(toggleCells:) forControlEvents:UIControlEventValueChanged];
    refreshControl.backgroundColor = [UIColor blackColor];
    refreshControl.tintColor = [UIColor colorWithRed:241.0/255.0 green:184.0/255.0 blue:45.0/255.0 alpha:1];
    
    [self.playlistTableView addSubview:refreshControl];
    self.refreshControl = refreshControl;
    
    // If you set the seperator inset on iOS 6 you get a NSInvalidArgumentException...weird
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
        self.playlistTableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0); // Makes the horizontal row seperator stretch the entire length of the table view
    }
    
    
    ViewController *tv = (ViewController *)[[self.tabBarController viewControllers] objectAtIndex:0];
    _trackObj = tv.tracks;
    _trackFav = tv.favorites;
    _filePath = tv.filePath;
    _beacon = tv.beacon;
    _socket = tv.jukeSocket;
    
    self.edgesForExtendedLayout = UIRectEdgeAll;
    self.playlistTableView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, CGRectGetHeight(self.tabBarController.tabBar.frame), 0.0f);
    
    [self.searchDisplayController.searchResultsTableView setBackgroundColor:[UIColor blackColor]];
}

-(UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(isFiltered)
        return [_filteredTrackArray count];
    else
        return [_trackObj count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - UIRefreshControl Selector

- (void)toggleCells:(UIRefreshControl*)refreshControl
{
    [refreshControl beginRefreshing];
    self.useCustomCells = !self.useCustomCells;
    
    [self.playlistTableView reloadData];
    [refreshControl endRefreshing];
}

#pragma mark - UIScrollViewDelegate

- (JUKEPlaylistTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    JUKEPlaylistTableViewCell *cell = [self.playlistTableView dequeueReusableCellWithIdentifier:@"PlaylistCell" forIndexPath:indexPath];
    
    cell.rightUtilityButtons = [self rightButtons];
    cell.delegate = self;
    
    if(isFiltered){
        cell.playlistAlbumArtImage.image = [[_filteredTrackArray objectAtIndex:indexPath.row] cover];
        cell.playlistSongTitleLabel.text = [[_filteredTrackArray objectAtIndex:indexPath.row] track];
        cell.playlistArtistLabel.text = [[_filteredTrackArray objectAtIndex:indexPath.row] artist];
        
    }else{
        cell.playlistAlbumArtImage.image = [[_trackObj objectAtIndex:indexPath.row] cover];
        cell.playlistSongTitleLabel.text = [[_trackObj objectAtIndex:indexPath.row] track];
        cell.playlistArtistLabel.text = [[_trackObj objectAtIndex:indexPath.row] artist];
        
    }
    
    return cell;
    
    
}

- (NSArray *)rightButtons
{
    NSMutableArray *rightUtilityButtons = [NSMutableArray new];
    
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:241.0/255.0 green:184.0/255.0 blue:45.0/255.0 alpha:1]
                                                 icon:[UIImage imageNamed:@"favorites.png"]];
    [rightUtilityButtons sw_addUtilityButtonWithColor:
     [UIColor colorWithRed:241.0/255.0 green:184.0/255.0 blue:45.0/255.0 alpha:1]
                                                 icon:[UIImage imageNamed:@"vote.png"]];
    
    return rightUtilityButtons;
}


#pragma mark - SWTableViewDelegate

- (void)swipeableTableViewCell:(SWTableViewCell *)cell didTriggerRightUtilityButtonWithIndex:(NSInteger)index {
    switch (index) {
        case 0://FAVORITE BUTTON
        {
            NSIndexPath *cellIndexPath;
            
            if(isFiltered){
                cellIndexPath = [self.searchDisplayController.searchResultsTableView indexPathForCell:cell];
                UIAlertView *alertTest = [[UIAlertView alloc] initWithTitle:@"Favorite" message:[NSString stringWithFormat:@"%@ By %@ has been added to your favorites", [[_filteredTrackArray objectAtIndex:cellIndexPath.row] track], [[_filteredTrackArray objectAtIndex:cellIndexPath.row] artist]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [alertTest show];
                
                dispatch_async(dispatch_get_global_queue(0, 0), ^ {
                    _trackFav = [[NSKeyedUnarchiver unarchiveObjectWithFile:_filePath] mutableCopy];
                    
                    NSInteger count = 0;
                    for (count = 0; count < [_trackFav count]; count++) {
                        if([[[_trackFav objectAtIndex:count] trackID] isEqualToString:[[_filteredTrackArray objectAtIndex:cellIndexPath.row] trackID]]){
                            [_trackFav removeObject:[_trackFav objectAtIndex:count]];
                            count--;
                        }
                    }
                    [_trackFav addObject:[_filteredTrackArray objectAtIndex:cellIndexPath.row]];
                    
                    NSSortDescriptor *queueSorter = [[NSSortDescriptor alloc] initWithKey:@"track" ascending:YES];
                    NSArray *queueSortDescriptor =  @[queueSorter];
                    NSArray *queueSortedArray = [_trackFav sortedArrayUsingDescriptors:queueSortDescriptor];
                    _trackFav = [(NSArray*)queueSortedArray mutableCopy];
                    
                    [NSKeyedArchiver archiveRootObject:_trackFav toFile:_filePath];
                });
            }else{
                cellIndexPath = [self.playlistTableView indexPathForCell:cell];
                UIAlertView *alertTest = [[UIAlertView alloc] initWithTitle:@"Favorite" message:[NSString stringWithFormat:@"%@ By %@ has been added to your favorites", [[_trackObj objectAtIndex:cellIndexPath.row] track], [[_trackObj objectAtIndex:cellIndexPath.row] artist]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [alertTest show];
                
                dispatch_async(dispatch_get_global_queue(0, 0), ^ {
                    _trackFav = [[NSKeyedUnarchiver unarchiveObjectWithFile:_filePath] mutableCopy];
                    
                    NSInteger count = 0;
                    for (count = 0; count < [_trackFav count]; count++) {
                        if([[[_trackFav objectAtIndex:count] trackID] isEqualToString:[[_trackObj objectAtIndex:cellIndexPath.row] trackID]]){
                            [_trackFav removeObject:[_trackFav objectAtIndex:count]];
                            count--;
                        }
                    }
                    [_trackFav addObject:[_trackObj objectAtIndex:cellIndexPath.row]];
                    
                    NSSortDescriptor *queueSorter = [[NSSortDescriptor alloc] initWithKey:@"track" ascending:YES];
                    NSArray *queueSortDescriptor =  @[queueSorter];
                    NSArray *queueSortedArray = [_trackFav sortedArrayUsingDescriptors:queueSortDescriptor];
                    _trackFav = [(NSArray*)queueSortedArray mutableCopy];
                    
                    [NSKeyedArchiver archiveRootObject:_trackFav toFile:_filePath];
                });
            }
            
            [cell hideUtilityButtonsAnimated:YES];
            break;
        }
        case 1://Vote button was pressed
        {
            NSIndexPath *cellIndexPath;
            NSString *temp;
            
            if (isFiltered) {
                cellIndexPath= [self.searchDisplayController.searchResultsTableView indexPathForCell:cell];
                temp = [[_filteredTrackArray objectAtIndex:cellIndexPath.row] songID];
                
                UIAlertView *alertTest = [[UIAlertView alloc] initWithTitle:@"Vote" message:[NSString stringWithFormat:@"You voted for %@ By %@", [[_filteredTrackArray objectAtIndex:cellIndexPath.row] track], [[_filteredTrackArray objectAtIndex:cellIndexPath.row] artist]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [alertTest show];
                
            } else {
                cellIndexPath= [self.playlistTableView indexPathForCell:cell];
                temp = [[_trackObj objectAtIndex:cellIndexPath.row] songID];
                
                UIAlertView *alertTest = [[UIAlertView alloc] initWithTitle:@"Vote" message:[NSString stringWithFormat:@"You voted for %@ By %@", [[_trackObj objectAtIndex:cellIndexPath.row] track], [[_trackObj objectAtIndex:cellIndexPath.row] artist]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [alertTest show];
            }
            
            NSString *str  = [NSString stringWithFormat:@"{\"id\":311,\"data\":\"%@\",\"clientIdentifier\":\"%@\"}\n", temp, _beacon];
            
            [_socket vote:str];
            
            [cell hideUtilityButtonsAnimated:YES];
            
            break;
        }
        default:
            break;
    }
}

- (BOOL)swipeableTableViewCellShouldHideUtilityButtonsOnSwipe:(SWTableViewCell *)cell {
    return YES;
}

#pragma Search Functions

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self reloadSearchResultsWithSearchBar:searchBar];
}

-(void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    [self reloadSearchResultsWithSearchBar:searchBar];
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    isFiltered = FALSE;
    [self.playlistTableView reloadData];
}

-(void)reloadSearchResultsWithSearchBar: (UISearchBar*)searchBar
{
    NSInteger scopeBarIndex = searchBar.selectedScopeButtonIndex;
    
    NSString *searchText = searchBar.text;
    
    if(searchText.length == 0)
    {
        isFiltered = FALSE;
    }
    else
    {
        
        isFiltered = true;
        if (_filteredTrackArray == nil)
            _filteredTrackArray = [[NSMutableArray alloc] init];
        else
            [_filteredTrackArray removeAllObjects];
        
        NSString *track_string;
        for(int i=0; i< [_trackObj count];i++){
            //Sort by track
            if(scopeBarIndex == 0)
                track_string =[[_trackObj objectAtIndex:i] track];
            //Sort by artist
            else
                track_string = [[_trackObj objectAtIndex:i] artist];
            
            NSRange nameRange = [track_string rangeOfString:searchText options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch)];
            if(nameRange.location != NSNotFound)
                [_filteredTrackArray addObject:[_trackObj objectAtIndex:i]];
        }
        
    }
    [self.playlistTableView reloadData];
}

-(void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView{
    self.searchDisplayController.searchResultsTableView.backgroundColor = [UIColor blackColor];
    self.searchDisplayController.searchResultsTableView.separatorColor = [UIColor blackColor];
    self.searchDisplayController.searchResultsTableView.rowHeight = 55;
}




@end

