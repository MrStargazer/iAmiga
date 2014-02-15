//
//  BaseEmulationViewController.m
//  iAmiga
//
//  Created by Stuart Carnie on 6/22/11.
//  Copyright 2011 Manomio LLC. All rights reserved.
//

#import "BaseEmulationViewController.h"
#import "uae.h"
#import "CocoaUtility.h"
#import "UIKitDisplayView.h"
#import "TouchHandlerView.h"
#import "NSObject+Blocks.h"

#define kDisplayWidth							320.0f
#define kDisplayHeight							240.0f
#define kDisplayTopOffset                       7.0f


@interface BaseEmulationViewController()

@property (nonatomic, retain) UIView<DisplayViewSurface>	*displayView;
@property (nonatomic,retain) UIWindow	*displayViewWindow;
@property (nonatomic, readonly) CGRect currentDisplayFrame;

@end

@implementation BaseEmulationViewController

@synthesize displayView, displayViewWindow;
@synthesize integralSize=_integralSize;
@dynamic bundleVersion;

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // self.integralSize = YES;
    
    UIView *view = self.view;
    
    SDL_Init(0);
	SDL_Surface *surface = SDL_SetVideoMode(kDisplayWidth, kDisplayHeight, 16, 0);
	UIView<DisplayViewSurface> *surfaceView = (UIView<DisplayViewSurface>*)surface->userdata;
    surfaceView.contentMode = UIViewContentModeScaleToFill;
	surfaceView.paused = YES;
	surfaceView.frame = self.currentDisplayFrame;
    surfaceView.backgroundColor = [UIColor blackColor];
    /*UIView *testview = [[UIView alloc] initWithFrame:CGRectMake(500, 300, 200, 100)];
    testview.backgroundColor = [UIColor blackColor];*/
    	
	self.displayView = surfaceView;
	if (displayViewWindow != nil) {
		[displayViewWindow addSubview:self.displayView];
	} else {
		[view addSubview:self.displayView];
    }
}

- (void)sendKeys:(SDLKey*)keys count:(size_t)count keyState:(SDL_EventType)keyState afterDelay:(NSTimeInterval)delayInSeconds {
    SDLKey *keyCopy = (SDLKey *)malloc(sizeof(SDLKey) * count);
    memcpy(keyCopy, keys, sizeof(SDLKey) * count);
    
    [self performBlock:^(void) {
        for (int i=0; i < count; i++) {
            SDL_Event evt;
            evt.type = keyState;
            evt.key.keysym.sym = keyCopy[i];
            SDL_PushEvent(&evt);
        }
        free(keyCopy);
    } afterDelay:delayInSeconds];
}

- (NSString *)bundleVersion {
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    return version;
}

- (void)viewDidAppear:(BOOL)animated {
	[self startEmulator];
}

- (void)viewWillDisappear:(BOOL)animated {
	[self pauseEmulator];
}

- (void)setIntegralSize:(BOOL)value {
	_integralSize = value;
	self.displayView.frame = self.currentDisplayFrame;
}

static CGRect CreateIntegralScaledView(CGRect aFrame, BOOL top) {
	CGSize frameSize = aFrame.size;
	CGFloat scale = frameSize.width < frameSize.height ? floorf(frameSize.width / kDisplayWidth) : floorf(frameSize.height / kDisplayHeight);
	int width = kDisplayWidth * scale, height = kDisplayHeight * scale;
	CGFloat y = top ? 0 : (frameSize.height - height) / 2;
	return CGRectMake((frameSize.width - width) / 2, y, width, height);
}

- (CGFloat)displayTop {
    return kDisplayTopOffset;
}

- (CGRect)currentDisplayFrame {	
	if (_isExternal) {
		if (_integralSize) {
			return CreateIntegralScaledView(displayViewWindow.bounds, NO);
		}
		// assuming external display it's width > height
		return displayViewWindow.bounds;
	} 
    
	CGSize frameSize = self.view.frame.size;
    CGSize tmp = frameSize;
    frameSize.width = tmp.height;
    frameSize.height = tmp.width;
	
	if (_integralSize) {
		CGRect aFrame;
		if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
			aFrame = CGRectMake(0, 0, frameSize.width, frameSize.height);
		} else {
			aFrame = self.view.frame;
		}
		return CreateIntegralScaledView(aFrame, YES);
	}
	
	// full-screen, landscape mode
	if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
		// assuming landscape width > height
		return CGRectMake(0, self.displayTop, frameSize.width, frameSize.height);
	}
	
	// aspect fill (portrait mode)
	CGFloat xRatio = frameSize.width / kDisplayWidth;
	CGFloat yRatio = frameSize.height / kDisplayHeight;
	CGFloat ratio = MIN(xRatio, yRatio);
    
	return CGRectMake(0, 0, kDisplayWidth * ratio, kDisplayHeight * ratio);
}

- (void)setDisplayViewWindow:(UIWindow*)window isExternal:(BOOL)isExternal {
	_isExternal = isExternal;
	self.displayViewWindow = window;
	if (displayView == nil)
		return;
	
	if (window) {
		[window addSubview:displayView];
	} else {
		[self.view insertSubview:displayView atIndex:0];
	}
	
	self.displayView.frame = self.currentDisplayFrame;
}

#pragma mark - Emulator Functions

- (void)enableUserInteraction {
	[self.view setUserInteractionEnabled:YES];
}

- (void)startEmulator {
	if (emulatorState == EmulatorPaused) {
		[self resumeEmulator];
	} else if (emulatorState == EmulatorNotStarted) {
		emulationThread = [[NSThread alloc] initWithTarget:self selector:@selector(runEmulator) object:nil];
		[emulationThread start];
		[self performSelector:@selector(enableUserInteraction) withObject:nil afterDelay:0.25];
        displayView.paused = NO;
	}
}

- (void)stopEmulator {
	[emulationThread release];
    emulationThread = nil;
    emulatorState = EmulatorNotStarted;
}

- (void)runEmulator {
	emulatorState = EmulatorRunning;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[NSThread setThreadPriority:0.7];
	g_emulator.real_main();
	[pool release];
}

- (void)pauseEmulator {
	emulatorState = EmulatorPaused;
	g_emulator.uae_pause();
	displayView.paused = YES;
}

- (void)resumeEmulator {
	if (emulatorState != EmulatorPaused)
		return;
	emulatorState = EmulatorRunning;
	g_emulator.uae_resume();
	displayView.paused = NO;
}

-(NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskLandscape;
}

@end
