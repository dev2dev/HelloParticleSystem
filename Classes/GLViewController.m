//
//  GLViewController.h
//  HelloTexture
//
//  Created by turner on 5/26/09.
//  Copyright Douglass Turner Consulting 2009. All rights reserved.
//

#import <AudioToolbox/AudioServices.h>

#import "ConstantsAndMacros.h"
#import "GLViewController.h"
#import "GLView.h"
#import "ParticleSystem.h"

// Accelerometer sampling frequency in hertz (hz)
#define kAccelerometerFrequency		(30.0)

@implementation GLViewController

- (void)dealloc {
	
	
    [super dealloc];
}

// The Stanford Pattern
- (void)loadView {
	
	CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
	
	GLView *glView = nil;
	glView = [[GLView alloc] initWithFrame:applicationFrame];
	
	glView.controller = self;
		
	self.view = glView;
	[glView release];
}

static SystemSoundID _boomSoundIDs[3];

// The Stanford Pattern
- (void)viewDidLoad {
	
	// Prepare particle system arrays
	_particleSystems		= [[NSMutableArray alloc] init];
	_deadParticleSystems	= [[NSMutableArray alloc] init];

	// set up sound effects
	NSURL *soundURL = nil;
	
	soundURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"firework_6" ofType:@"wav"]];
	AudioServicesCreateSystemSoundID((CFURLRef)soundURL, &_boomSoundIDs[0]);
	
	soundURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"firework_2" ofType:@"wav"]];
	AudioServicesCreateSystemSoundID((CFURLRef)soundURL, &_boomSoundIDs[1]);
	
	soundURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"firework_3" ofType:@"wav"]];
	AudioServicesCreateSystemSoundID((CFURLRef)soundURL, &_boomSoundIDs[2]);

	[ParticleSystem buildParticleTextureAtlas];
	
	GLView *glView = (GLView *)self.view;
	[ParticleSystem buildBackdropWithBounds:[glView bounds]];
	
	//Configure and start accelerometer
	[[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0 / kAccelerometerFrequency)];
	[[UIAccelerometer sharedAccelerometer] setDelegate:self];
	
}

// The Stanford Pattern
- (void)viewWillAppear:(BOOL)animated {
	
	[super viewWillAppear:animated];
	
	// Do stuff
	GLView *glView = (GLView *)self.view;

	glView.animationInterval = 1.0 / kRenderingFrequency;
	[glView startAnimation];
	
//	[self beginLoadingDataFromWeb];
//	[self showLoadingProgress];

}

// The Stanford Pattern
- (void)viewWillDisappear:(BOOL)animated {
	
	// Do stuff
	GLView *glView = (GLView *)self.view;
	[glView stopAnimation];

	[_particleSystems		removeAllObjects];	
	[_deadParticleSystems	removeAllObjects];
	
	[_particleSystems		release];
	[_deadParticleSystems	release];

	//	[self rememberState];
	//	[self saveStateToDisk];
	
	[super viewWillDisappear:animated];
}

-(void)setupView:(GLView*)view {
	
	GLfloat w		= view.bounds.size.width;
	GLfloat h		= view.bounds.size.height;
    glViewport(0, 0, w, h);
    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrthof(0, w, h, 0, 0, 1);
	
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
	
    glEnable(GL_TEXTURE_2D);
	
    glEnable(GL_BLEND);

	glBlendFunc(GL_ONE,			GL_ONE_MINUS_SRC_ALPHA);
	
	
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glEnableClientState(GL_COLOR_ARRAY);
	
	
}

- (void)drawView:(GLView*)view {
	
	
    NSTimeInterval time = [NSDate timeIntervalSinceReferenceDate];
	
	if (nil != _touchedParticleSystem) {
		
		if ([_touchedParticleSystem animate:time]) {
			
			[_touchedParticleSystem draw];
			
		} else {
			
			[_touchedParticleSystem release];
			_touchedParticleSystem = nil;
		}
		
	} // if (nil != _touchedParticleSystem)

	
    for (ParticleSystem *ps in _particleSystems) {
		
		if ([ps animate:time]) {
			
            [ps draw];			
			
		} else {
			
			[_deadParticleSystems	addObject:ps];
        }
		
    } // for (_particleSystems)

	
	for (ParticleSystem *ps in _deadParticleSystems) {
		
        [_particleSystems removeObjectIdenticalTo:ps];
    }
	
	[_deadParticleSystems removeAllObjects];
	
	
	// NOTE: The background should completely fill the window, eliminating the
	// need for a costly clearing of depth and color every frame.
	[ParticleSystem renderBackground];
	
	[ParticleSystem renderParticles];
	
}

- (void)_playBoom {
	
    int index = (random() % 3);
    AudioServicesPlaySystemSound(_boomSoundIDs[index]);
	
}

- (NSString*) phaseName:(UITouchPhase) phase {
	
	NSString* result = nil;
	
	switch (phase) {
			
		case UITouchPhaseBegan:
			result = @"UITouchPhaseBegan";
			break;
		case UITouchPhaseMoved:
			result = @"UITouchPhaseMoved";
			break;
		case UITouchPhaseStationary:
			result = @"UITouchPhaseStationary";
			break;
		case UITouchPhaseEnded:
			result = @"UITouchPhaseEnded";
			break;
		case UITouchPhaseCancelled:
			return @"UITouchPhaseCancelled";
			break;
		default:
			result = @"Huh?";
	}
	
	return result;
};

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	
	[self _playBoom];
	
	// Only single touch for now
	UITouch *touch	= [touches anyObject];
	
//	NSObject *o		= touch;
//	NSLog(@"touchesBegan: touch(%p) phase(%@) tapCount(%d) time(%f) location( previous(%f %f) current(%f %f) )", 
//		  o, 
//		  [self phaseName:touch.phase],
//		  touch.tapCount, 
//		  touch.timestamp, 
//		  [touch	previousLocationInView:self.view].x,	[touch	previousLocationInView:self.view].y,
//		  [touch			locationInView:self.view].x,	[touch			locationInView:self.view].y
//		  );
	
	_touchedParticleSystem = [[ParticleSystem alloc] initAtLocation:[touch locationInView:self.view]];	
	_touchedParticleSystem.touchPhaseName = [self phaseName:touch.phase];
	
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	
	// Only single touch for now
	UITouch *touch	= [touches anyObject];	
	
//	NSObject *o		= touch;
//	NSLog(@"touchesMoved: touch(%p) phase(%@) tapCount(%d) time(%f) location( previous(%f %f) current(%f %f) )", 
//		  o, 
//		  [self phaseName:touch.phase],
//		  touch.tapCount, 
//		  touch.timestamp, 
//		  [touch	previousLocationInView:self.view].x,	[touch	previousLocationInView:self.view].y,
//		  [touch			locationInView:self.view].x,	[touch			locationInView:self.view].y
//		  );
	
	_touchedParticleSystem.touchPhaseName = [self phaseName:touch.phase];
	_touchedParticleSystem.location = [touch locationInView:self.view];
//	[_touchedParticleSystem fill:[touch locationInView:self.view]];
	
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	
	// Only single touch for now
	UITouch *touch	= [touches anyObject];	
//	NSObject *o		= touch;
//	NSLog(@"touchesEnded: touch(%p) phase(%@) tapCount(%d) time(%f) location( previous(%f %f) current(%f %f) )", 
//		  o, 
//		  [self phaseName:touch.phase],
//		  touch.tapCount, 
//		  touch.timestamp, 
//		  [touch	previousLocationInView:self.view].x,	[touch	previousLocationInView:self.view].y,
//		  [touch			locationInView:self.view].x,	[touch			locationInView:self.view].y
//		  );
	
	_touchedParticleSystem.touchPhaseName = [self phaseName:touch.phase];
	[_touchedParticleSystem setDecay:YES];
	[_particleSystems addObject:_touchedParticleSystem];
	
//	NSLog(@"touchesEnded: _particleSystems.length(%d)", _particleSystems.count); 
	
	[_touchedParticleSystem release];
	_touchedParticleSystem = nil;
	
//	NSLog(@" ");
	
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	
//	UITouch *touch = [touches anyObject];	
//	NSObject *o = touch;
//	NSLog(@"touch(%p) phase(%@) tapCount(%d) time(%f) location( previous(%f %f) current(%f %f) )", 
//		  o, 
//		  [self phaseName:touch.phase],
//		  touch.tapCount, 
//		  touch.timestamp, 
//		  [touch	previousLocationInView:self.view].x,	[touch	previousLocationInView:self.view].y,
//		  [touch			locationInView:self.view].x,	[touch			locationInView:self.view].y
//		  );
	
	// Do stuff
	GLView *glView = (GLView *)self.view;
	[glView stopAnimation];
	
	[_particleSystems		removeAllObjects];	
	[_deadParticleSystems	removeAllObjects];
	
	[_particleSystems		release];
	[_deadParticleSystems	release];
	
}

#define kFilteringFactor			(0.1)
- (void)accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*)acceleration {
	
	//Use a basic low-pass filter to only keep the gravity in the accelerometer values
	accel[0] = acceleration.x * kFilteringFactor + accel[0] * (1.0 - kFilteringFactor);
	accel[1] = acceleration.y * kFilteringFactor + accel[1] * (1.0 - kFilteringFactor);
	accel[2] = acceleration.z * kFilteringFactor + accel[2] * (1.0 - kFilteringFactor);
}


@end
