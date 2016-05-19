//
//  JUKEPlaylistTableViewCell.h
//  UJuke
//
//  Created by Mohammed Kheder on 4/30/14.
//  Copyright (c) 2014 Chris Wendel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWTableViewCell.h"

@interface JUKEPlaylistTableViewCell : SWTableViewCell

@property (nonatomic, weak) IBOutlet UILabel *playlistSongTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel *playlistArtistLabel;
@property (nonatomic, weak) IBOutlet UIImageView *playlistAlbumArtImage;

@end
