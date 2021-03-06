//  Created by Simon Toens on 01.10.15
//
//  iUAE is free software: you may copy, redistribute
//  and/or modify it under the terms of the GNU General Public License as
//  published by the Free Software Foundation, either version 2 of the
//  License, or (at your option) any later version.
//
//  This file is distributed in the hope that it will be useful, but
//  WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//  General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

#import <Foundation/Foundation.h>

@interface KeyButtonsEnabledCell : UITableViewCell

@property (nonatomic, assign) IBOutlet UISwitch *keyButtonsEnabledSwitch;

@end

@interface ButtonViewConfigurationCell : UITableViewCell

@property (nonatomic, assign) IBOutlet UILabel *keyNameLabel;
@property (nonatomic, assign) IBOutlet UISwitch *showOutlineSwitch;
@property (nonatomic, assign) IBOutlet UISwitch *enabledSwitch;

@end


@interface KeyButtonManagementController : UITableViewController

@end