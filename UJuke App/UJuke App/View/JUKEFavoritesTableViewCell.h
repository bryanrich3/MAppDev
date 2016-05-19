//
//  JUKEFavoritesTableViewCell.h
//  UJuke
//
//  Created by Mohammed Kheder on 4/30/14.
//  Copyright (c) 2014 Chris Wendel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWTableViewCell.h"

@interface JUKEFavoritesTableViewCell : SWTableViewCell

@property (nonatomic, weak) IBOutlet UILabel *favoriteSongTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel *favoritesArtistLabel;
@property (nonatomic, weak) IBOutlet UIImageView *favoritesAlbumArtImage;

@end
