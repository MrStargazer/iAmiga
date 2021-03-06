//  Created by Emufr3ak on 29.05.14.
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
// You should have received a copy of the GNU General Public License
//along with this program; if not, write to the Free Software
//Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

#import "MFIControllerReaderView.h"
#import <UIKit/UIKit.h>
#import "debug.h"
#import "touchstick.h"
#import "JoypadKey.h"
#import "Settings.h"
#import "SDL_events.h"
#import "MultiPeerConnectivityController.h"

@implementation MFIControllerReaderView {
    int _button[9];
    TouchStickDPadState _hat_statelast;
    TouchStickDPadState _hat_state;
    MultiPeerConnectivityController *mpcController;
    int _buttontoreleasehorizontal;
    int _buttontoreleasevertical;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    _hat_state = DPadCenter;
    _buttonapressed = false;
    //_thejoystick = &g_touchStick;
    _hat_statelast = DPadCenter;
    mpcController = [MultiPeerConnectivityController getinstance];
    
    for(int i=0;i<=7;i++)
        _button[i] = 0;
    
    [self discoverController];
    //_settings = [[Settings alloc] init];
    
    return self;
}

- (void)discoverController {
    
    if ([[GCController controllers] count] == 0) {
        [GCController startWirelessControllerDiscoveryWithCompletionHandler:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(controllerDiscovered)
                                                     name:GCControllerDidConnectNotification
                                                   object:nil];
    } else {
        [self controllerDiscovered];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(discoverController)
                                                     name:GCControllerDidDisconnectNotification
                                                   object:nil];
    }
}

- (void)sendinputbuttons:(int)buttonid
{
    _button[buttonid] = [mpcController sendinputbuttons:buttonid buttonstate:_button[buttonid]];
}

- (void)controllerDiscovered {
    
    GCController *controller = [GCController controllers][0];
    
    controller.controllerPausedHandler = ^(GCController *controller) {
        _paused = (_paused == 1) ? 0 : 1;
    };
    
    controller.gamepad.valueChangedHandler = ^(GCGamepad *gamepad, GCControllerElement
                                               *element)
    {
        if(gamepad.buttonA.isPressed != _button[BTN_A])
            [self sendinputbuttons: BTN_A];
        else if(gamepad.buttonB.isPressed != _button[BTN_B])
               [self sendinputbuttons: BTN_B];
        else if(gamepad.buttonX.isPressed!= _button[BTN_X])
               [self sendinputbuttons: BTN_X];
        else if(gamepad.buttonY.isPressed != _button[BTN_Y])
               [self sendinputbuttons: BTN_Y];
        else if(gamepad.rightShoulder.isPressed != _button[BTN_R1])
               [self sendinputbuttons: BTN_R1];
        else if(gamepad.leftShoulder.isPressed != _button[BTN_L1])
                [self sendinputbuttons: BTN_L1];
        else if(gamepad.controller.extendedGamepad.rightTrigger.isPressed != _button[BTN_R2])
                [self sendinputbuttons: BTN_R2];
        else if(gamepad.controller.extendedGamepad.leftTrigger.isPressed !=     _button[BTN_L2])
              [self sendinputbuttons: BTN_L2];
        
        if(gamepad.dpad.left.pressed || gamepad.controller.extendedGamepad.leftThumbstick.left.pressed)
        {
            if(gamepad.dpad.up.pressed)
            {
                _hat_state = DPadUpLeft;
            }
            else if(gamepad.dpad.down.pressed || gamepad.controller.extendedGamepad.leftThumbstick.down.pressed)
            {
                _hat_state = DPadDownLeft;
            }
            else
            {
                _hat_state = DPadLeft;
            }
        }
        else if(gamepad.dpad.right.pressed || gamepad.controller.extendedGamepad.leftThumbstick.right.pressed)
        {
            if(gamepad.dpad.up.pressed || gamepad.controller.extendedGamepad.leftThumbstick.up.pressed)
            {
                _hat_state = DPadUpRight;
            }
            else if(gamepad.dpad.down.pressed || gamepad.controller.extendedGamepad.leftThumbstick.down.pressed)
            {
                _hat_state = DPadDownRight;
            }
            else
            {
                _hat_state = DPadRight;
            }
        }
        else if(gamepad.dpad.up.pressed || gamepad.controller.extendedGamepad.leftThumbstick.up.pressed)
        {
            _hat_state = DPadUp;
        }
        else if(gamepad.dpad.down.pressed || gamepad.controller.extendedGamepad.leftThumbstick.down.pressed)
        {
            _hat_state = DPadDown;
        }
        else
        {
            _hat_state = DPadCenter;
        }
        
        if (_hat_state != _hat_statelast) {
            _hat_statelast = _hat_state;
            
            int buttonvertical = [mpcController dpadstatetojoypadkey:@"vertical" hatstate:_hat_state];
            int buttonhorizontal = [mpcController dpadstatetojoypadkey:@"horizontal" hatstate: _hat_state];
            
            [mpcController sendinputdirections:_hat_state buttontoreleasevertical:_buttontoreleasevertical buttontoreleasehorizontal: _buttontoreleasehorizontal];
            
            _buttontoreleasevertical = buttonvertical;
            _buttontoreleasehorizontal = buttonhorizontal;
        }

    };
    
    GCControllerDirectionPad *dpad = controller.gamepad.dpad;
    dpad.valueChangedHandler = ^ (GCControllerDirectionPad *directionpad,
                                  float xValue, float yValue) {
        NSLog(@"Changed xValue on dPad = %f yValue = %f" ,xValue, yValue);
    };
    
    dpad.xAxis.valueChangedHandler = ^(GCControllerAxisInput *xAxis,float value) {
        NSLog(@"X Axis changed value %f",value);
    };
    
}

-(void)dealloc
{
    [super dealloc];
}

@end

