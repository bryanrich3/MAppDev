//
//  ViewController.h
//  UJuke
//
//  Created by Mohammed Kheder on 4/22/14.
//  Copyright (c) 2014 Mohammed Kheder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWTableViewCell.h"
#import "GCDAsyncSocket.h"
#import "JUKESocket.h"

@interface ViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, SWTableViewCellDelegate>

@property (nonatomic, strong) GCDAsyncSocket *socket;
@property (nonatomic, strong) NSMutableArray *tracks;
@property (nonatomic, strong) NSMutableArray *queue;
@property (nonatomic, strong) NSMutableArray *favorites;
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) NSString *beacon;
@property (nonatomic, strong) JUKESocket *jukeSocket;
@property (nonatomic, strong) NSMutableArray *test;
@property (weak, nonatomic) IBOutlet UIImageView *nowCover;
@property (weak, nonatomic) IBOutlet UILabel *nowTrack;
@property (weak, nonatomic) IBOutlet UILabel *nowArtist;
@property (weak, nonatomic) IBOutlet UIButton *nowFavoriteButton;

@end
