//
//  ViewController.m
//  UJuke
//
//  Created by Mohammed Kheder on 4/22/14.
//  Copyright (c) 2014 Mohammed Kheder. All rights reserved.
//

#import "ViewController.h"
#import "SWTableViewCell.h"
#import "JUKETableViewCell.h"
#import "JUKETrack.h"
#import "JUKEGetData.h"
#import "JUKESocket.h"
#import "BeaconHandler.h"

@interface ViewController (){
    Boolean inRange;
}

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic) BOOL useCustomCells;
@property (nonatomic, weak) UIRefreshControl *refreshControl;
@property (nonatomic, strong) NSString *current;
@property (nonatomic, strong) NSString *cid;
@property (nonatomic, strong) JUKETrack *nowPlaying;
@property (nonatomic, strong) BeaconHandler *beaconHandler;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = 55;
    
    
    // Setup refresh control for example app
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(toggleCells:) forControlEvents:UIControlEventValueChanged];
    refreshControl.tintColor = [UIColor colorWithRed:241.0/255.0 green:184.0/255.0 blue:45.0/255.0 alpha:1];
    
    [self.tableView addSubview:refreshControl];
    self.refreshControl = refreshControl;

    // If you set the seperator inset on iOS 6 you get a NSInvalidArgumentException...weird
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
       self.tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0); // Makes the horizontal row seperator stretch the entire length of the table view
    }
    
    //Archive file path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    _filePath = [documentsDirectory stringByAppendingPathComponent: @"favorite.juke"];
    
    _favorites = [[NSMutableArray alloc] init];
    if([[NSFileManager defaultManager] fileExistsAtPath:_filePath])
    {
        _favorites = [[NSKeyedUnarchiver unarchiveObjectWithFile:_filePath] mutableCopy];
    } else {
        [NSKeyedArchiver archiveRootObject:_favorites toFile:_filePath];
        _favorites = [[NSKeyedUnarchiver unarchiveObjectWithFile:_filePath] mutableCopy];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playlist:) name:@"playlist" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentSong:) name:@"currentSong" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(votesOrCurrent:) name:@"votesOrCurrent" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(foundBeacon:) name:@"foundBeacon" object:nil];
    
    _jukeSocket = [[JUKESocket alloc] init];

    //inRange = false;
    //_beaconHandler = [[BeaconHandler alloc] init];
    
    //connect to socket
    _beacon = @"40390";
    [_jukeSocket socketConnect:_beacon];
    
    self.edgesForExtendedLayout = UIRectEdgeAll;
    self.tableView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, CGRectGetHeight(self.tabBarController.tabBar.frame), 0.0f);
}

-(void)beaconNotifaction
{
    UILocalNotification *notification = [UILocalNotification new];
    notification.alertBody = [NSString stringWithFormat:@"Entered UJuke region. Currently playing song: %@.", [_nowPlaying track]];
    
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}

-(void)foundBeacon:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    CLBeacon *temp = userInfo[@"beacon"];

    _beacon = [temp.minor stringValue];
    
    id item = [userInfo valueForKeyPath:@"beacon"];
    if(item){
        if (!inRange) {
            [_jukeSocket socketConnect:_beacon];
            
            inRange = true;
        }
    } else {

        [_jukeSocket outOfRange];
        [_tracks removeAllObjects];
        [_queue removeAllObjects];
        
        UILocalNotification *notification = [UILocalNotification new];
        notification.alertBody = [NSString stringWithFormat:@"Exited UJuke region."];
        
        [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
        
        inRange = false;
    }
}

-(void)currentSong:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    NSDictionary *temp = userInfo[@"jsonData"];
    NSData *newData = [[NSString stringWithFormat:@"%@", temp[@"data"]] dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *current = [NSJSONSerialization JSONObjectWithData:newData options:0 error:NULL];
    NSDictionary *currentInfo = [current objectForKey:@"currentSongInfoTO"];
    
    _current = currentInfo[@"spotifyId"];
}

-(void)playlist:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    NSData *newData = [[NSString stringWithFormat:@"%@", userInfo[@"jsonData"]] dataUsingEncoding:NSUTF8StringEncoding];

    NSDictionary *playlist = [NSJSONSerialization JSONObjectWithData:newData options:0 error:NULL];
    NSDictionary *playlistArray = [playlist objectForKey:@"newPlaylist"];

    [self start:playlistArray];
}

-(void)votesOrCurrent:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    NSData *newData = [[NSString stringWithFormat:@"%@", userInfo[@"jsonData"]] dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *current = [NSJSONSerialization JSONObjectWithData:newData options:0 error:NULL];
    
    NSDictionary *currentInfo;
    id item = [current valueForKeyPath:@"currentSongInfoTO"];
    if (item) {
        currentInfo = [current objectForKey:@"currentSongInfoTO"];
        NSString *temp = currentInfo[@"spotifyId"];
        
        for (JUKETrack *ids in _tracks) {
            if ([ids.trackID isEqualToString:temp]) {
                _nowPlaying = ids;
                [self setNowPlaying:ids];
                break;
            }
        }
        
        NSSortDescriptor *queueSorter = [[NSSortDescriptor alloc] initWithKey:@"votes" ascending:NO];
        NSArray *queueSortDescriptor =  @[queueSorter];
        NSArray *queueSortedArray = [_queue sortedArrayUsingDescriptors:queueSortDescriptor];
        _queue = [(NSArray*)queueSortedArray mutableCopy];
        
        [UIView setAnimationsEnabled:NO];
        [_refreshControl beginRefreshing];
        [_tableView reloadData];
        [_refreshControl endRefreshing];
        [UIView setAnimationsEnabled:YES];
        
    } else {
        JUKETrack *temp = [[JUKETrack alloc] init];
        for (JUKETrack *ids in _tracks) {
            if ([ids.songID isEqualToString:current[@"songId"]]) {
                ids.votes = [current[@"votes"] integerValue];
                temp = ids;
                break;
            }
        }
        
        if (temp.votes > 0) {
            NSInteger count = 0;
            for (count = 0; count < [_queue count]; count++) {
                if([[[_queue objectAtIndex:count] songID]isEqualToString:temp.songID]){
                    [_queue removeObject:[_queue objectAtIndex:count]];
                    count--;
                }
            }
            [_queue addObject:temp];
        } else if(temp.votes == 0) {
            NSInteger count = 0;
            for (count = 0; count < [_queue count]; count++) {
                if([[[_queue objectAtIndex: count] songID] isEqualToString:temp.songID]){
                    [_queue removeObject:[_queue objectAtIndex:count]];
                    count--;
                }
            }
        }
        
        NSSortDescriptor *queueSorter = [[NSSortDescriptor alloc] initWithKey:@"votes" ascending:NO];
        NSArray *queueSortDescriptor =  @[queueSorter];
        NSArray *queueSortedArray = [_queue sortedArrayUsingDescriptors:queueSortDescriptor];
        _queue = [(NSArray*)queueSortedArray mutableCopy];
        
        [UIView setAnimationsEnabled:NO];
        [_refreshControl beginRefreshing];
        [_tableView reloadData];
        [_refreshControl endRefreshing];
        [UIView setAnimationsEnabled:YES];
    }
}

/*
 * Initalize tracks array and queue array
 * Loop through ids and get metadata from spotify for each song, add to tracks array
 * When loop is done sort tracks array by track name ascending
 * Loop through tracks array and match current song id with track object and set now playing
 * Add all songs with votes to queue array
 * Sort queue array by votes decending
 * Refresh table to show queued songs
 */
-(void)start:(NSDictionary *)ids
{
    _tracks = [[NSMutableArray alloc] init];
    _queue = [[NSMutableArray alloc] init];
    
    __block int trackListSize = (int)[ids count];
    __block int trackLoaded = 0;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^ {
        for (NSDictionary *trackID in ids) {
            dispatch_async(dispatch_get_global_queue(0, 0), ^ {
                [self.tracks addObject:[JUKEGetData getData:trackID[@"spotifyId"] votes:trackID[@"votes"] songID:trackID[@"id"]]];
                if (trackListSize == ++trackLoaded) {
                    NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"track" ascending:YES];
                    NSArray *sortDescriptor =  @[sorter];
                    NSArray *sortedArray = [_tracks sortedArrayUsingDescriptors:sortDescriptor];
                    _tracks = [(NSArray*)sortedArray mutableCopy];
                    NSLog(@"Got Data");
                    
                    for (JUKETrack *ids in _tracks) {
                        if ([ids.trackID isEqualToString:_current]) {
                            _nowPlaying = ids;
                            [self setNowPlaying:ids];
                        }
                        
                        if (ids.votes > 0 && ![ids.trackID isEqualToString:_current]) {
                            NSLog(@"%ld", (long)ids.votes);
                            [_queue addObject:ids];
                        }
                    }
                    
                    NSSortDescriptor *queueSorter = [[NSSortDescriptor alloc] initWithKey:@"votes" ascending:NO];
                    NSArray *queueSortDescriptor =  @[queueSorter];
                    NSArray *queueSortedArray = [_queue sortedArrayUsingDescriptors:queueSortDescriptor];
                    _queue = [(NSArray*)queueSortedArray mutableCopy];
                    
                    [_refreshControl beginRefreshing];
                    self.useCustomCells = !self.useCustomCells;
                    
                    [self.tableView reloadData];
                    [_refreshControl endRefreshing];
                    
                    [self beaconNotifaction];
                }
            });
        }
    });
}

/*
 * Send track object and set now playing, remove from queue
 */
-(void)setNowPlaying:(JUKETrack *)track
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_nowCover setImage:[track cover]];
        _nowTrack.text = [track track];
        _nowArtist.text = [track artist];
        
        UIImage *heart = [UIImage imageNamed:@"heart"];
        [_nowFavoriteButton setImage:heart forState:UIControlStateNormal];
    });
    
    NSInteger count = 0;
    for (count = 0; count < [_queue count]; count++) {
        if ([[[_queue objectAtIndex:count] trackID] isEqualToString:track.trackID]) {
            [[_queue objectAtIndex:count] setVotes:0];
            [_queue removeObject:[_queue objectAtIndex:count]];
            count--;
        }
    }
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_queue count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UIRefreshControl Selector

- (void)toggleCells:(UIRefreshControl*)refreshControl
{
    [refreshControl beginRefreshing];
    self.useCustomCells = !self.useCustomCells;

    [self.tableView reloadData];
    [refreshControl endRefreshing];
}

#pragma mark - UIScrollViewDelegate

- (JUKETableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    JUKETableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"QueueCell" forIndexPath:indexPath];
        
    cell.rightUtilityButtons = [self rightButtons];
    cell.delegate = self;
    
    cell.artistLabel.text = [[_queue objectAtIndex:indexPath.row] artist];
    cell.songTitleLabel.text = [[_queue objectAtIndex:indexPath.row] track];
    cell.albumArtImage.image = [[_queue objectAtIndex:indexPath.row] cover];
    NSString *vote = [NSString stringWithFormat:@"%ld", (long)[[_queue objectAtIndex:indexPath.row] votes]];
    cell.voteCount.text = vote;
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
            NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:cell];
            
            UIAlertView *alertTest = [[UIAlertView alloc] initWithTitle:@"Favorite" message:[NSString stringWithFormat:@"%@ By %@ has been added to your favorites", [[_queue objectAtIndex:cellIndexPath.row] track], [[_queue objectAtIndex:cellIndexPath.row] artist]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alertTest show];
            
            [cell hideUtilityButtonsAnimated:YES];
            
            dispatch_async(dispatch_get_global_queue(0, 0), ^ {
                _favorites = [[NSKeyedUnarchiver unarchiveObjectWithFile:_filePath] mutableCopy];
                
                NSInteger count = 0;
                for (count = 0; count < [_favorites count]; count++) {
                    if([[[_favorites objectAtIndex:count ] trackID] isEqualToString:[[_queue objectAtIndex:cellIndexPath.row] trackID]]){
                        [_favorites removeObject:[_favorites objectAtIndex:count]];
                        count--;
                    }
                }
                
                [_favorites addObject:[_queue objectAtIndex:cellIndexPath.row]];
                
                NSSortDescriptor *queueSorter = [[NSSortDescriptor alloc] initWithKey:@"track" ascending:YES];
                NSArray *queueSortDescriptor =  @[queueSorter];
                NSArray *queueSortedArray = [_favorites sortedArrayUsingDescriptors:queueSortDescriptor];
                _favorites = [(NSArray*)queueSortedArray mutableCopy];
                
                [NSKeyedArchiver archiveRootObject:_favorites toFile:_filePath];
            });
            
            [cell hideUtilityButtonsAnimated:YES];
            break;
        }
        case 1://Vote button was pressed
        {
            NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:cell];
            NSString *temp = [[_queue objectAtIndex:cellIndexPath.row] songID];
            
            NSString *str  = [NSString stringWithFormat:@"{\"id\":311,\"data\":\"%@\",\"clientIdentifier\":\"%@\"}\n", temp, _beacon];
            
            [_jukeSocket vote:str];
            
            UIAlertView *alertTest = [[UIAlertView alloc] initWithTitle:@"Vote" message:[NSString stringWithFormat:@"You voted for %@ By %@", [[_queue objectAtIndex:cellIndexPath.row] track], [[_queue objectAtIndex:cellIndexPath.row] artist]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
            [alertTest show];
            
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
- (IBAction)buttonClicked:(id)sender {

    UIImage *buttonPressed = [UIImage imageNamed:@"heart-full"];
    [_nowFavoriteButton setImage:buttonPressed forState:UIControlStateNormal];
    
    
    UIAlertView *alertTest = [[UIAlertView alloc] initWithTitle:@"Favorite" message:[NSString stringWithFormat:@"%@ By %@ has been added to your favorites", _nowPlaying.track, _nowPlaying.artist] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alertTest show];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^ {
        _favorites = [[NSKeyedUnarchiver unarchiveObjectWithFile:_filePath] mutableCopy];
        
        NSInteger count = 0;
        for(count = 0; count < [_favorites count]; count++) {
            if([[[_favorites objectAtIndex: count] trackID] isEqualToString:_nowPlaying.trackID]){
                [_favorites removeObject:[_favorites objectAtIndex:count]];
                count--;
            }
        }
        [_favorites addObject:_nowPlaying];
        
        NSSortDescriptor *queueSorter = [[NSSortDescriptor alloc] initWithKey:@"track" ascending:YES];
        NSArray *queueSortDescriptor =  @[queueSorter];
        NSArray *queueSortedArray = [_favorites sortedArrayUsingDescriptors:queueSortDescriptor];
        _favorites = [(NSArray*)queueSortedArray mutableCopy];
        
        [NSKeyedArchiver archiveRootObject:_favorites toFile:_filePath];
    });

}

@end
