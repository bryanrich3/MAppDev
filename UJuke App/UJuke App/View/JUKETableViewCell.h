//
//  JUKETableViewCell.h
//  UJuke
//
//  Created by Mohammed Kheder on 4/22/14.
//  Copyright (c) 2014 Mohammed Kheder. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SWTableViewCell.h"

@interface JUKETableViewCell : SWTableViewCell

@property (nonatomic, weak) IBOutlet UILabel *songTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel *artistLabel;
@property (nonatomic, weak) IBOutlet UIImageView *albumArtImage;
@property (weak, nonatomic) IBOutlet UILabel *voteCount;

@end
