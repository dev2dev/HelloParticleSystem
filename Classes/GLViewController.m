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

@implementation GLViewController

@synthesize touchedParticleSystem;

- (void)dealloc {
	
	[touchedParticleSystem release];
	
	[_particleSystems		removeAllObjects];	
	[_particleSystems		release];
	
	[_deadParticleSystems	removeAllObjects];	
	[_deadParticleSystems	release];
	
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
	touchedParticleSystem	= nil;
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
	
}

// The Stanford Pattern
- (void)viewWillAppear:(BOOL)animated {
	
	[super viewWillAppear:animated];
	
	// Do stuff
	GLView *glView = (GLView *)self.view;

	glView.animationInterval = 1.0 / kRenderingFrequency;
	[glView startAnimation];
	
	[self enableAcclerometerEvents];

}

// The Stanford Pattern
- (void)viewWillDisappear:(BOOL)animated {
	
	//	[self rememberState];
	//	[self saveStateToDisk];
	
	[self disableAcclerometerEvents];
	
	// Do stuff
	GLView *glView = (GLView *)self.view;
	[glView stopAnimation];
	
	[super viewWillDisappear:animated];
}

// Initialize OpenGL Schmutz
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

// Draw a frame
- (void)drawView:(GLView*)view {
	
//	if (touchedParticleSystem != nil) {
//		
//		NSLog(@"GLViewController.drawView - touchPhaseName(%@)", touchedParticleSystem.touchPhaseName);	
//	} else if ([_particleSystems count] > 0) {
//		
//		NSLog(@"GLViewController.drawView - _particleSystems(%d) touchPhaseName(%@)", [_particleSystems count], touchedParticleSystem.touchPhaseName);	
//	}
		
    NSTimeInterval time = [NSDate timeIntervalSinceReferenceDate];
	
	if (nil != touchedParticleSystem) {

//		NSLog(@"GLViewController.drawView - drawing touchedParticleSystem touchPhaseName(%@)", _touchedParticleSystem.touchPhaseName);

		if ([touchedParticleSystem animate:time]) {
			
			[touchedParticleSystem draw];
			
		} else {
			
			[touchedParticleSystem release];
			touchedParticleSystem = nil;
		}
		
	} // if (nil != _touchedParticleSystem)

	
    for (ParticleSystem *ps in _particleSystems) {
		
//		NSLog(@"GLViewController.drawView - drawing       particleSystems touchPhaseName(%@)", ps.touchPhaseName);
		
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

// Boom! Boom! Boom!
- (void)_playBoom {
	
    int index = (random() % 3);
    AudioServicesPlaySystemSound(_boomSoundIDs[index]);
	
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	if (context == touchedParticleSystem) {

		if ([keyPath isEqualToString:@"alive"]) {
			
			[self _playBoom];
			
			NSLog(@"GLViewController - Observing %@.%@", [object class], keyPath);
			
//			[object removeObserver:self forKeyPath:@"alive"];
		}
			
	} else {
		
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
		
}

// String name for touch phase
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

// The touch phase quartet
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	
//	[self _playBoom];
	
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
	
	touchedParticleSystem = [[ParticleSystem alloc] initAtLocation:[touch locationInView:self.view]];
	touchedParticleSystem.touchPhaseName	= [self phaseName:touch.phase];
	
	
	[touchedParticleSystem addObserver:self 
							 forKeyPath:@"alive" 
								options:NSKeyValueObservingOptionNew 
								context:touchedParticleSystem];
	
	[touchedParticleSystem setValue:[NSNumber numberWithBool:YES] forKey:@"alive"];

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
	
	touchedParticleSystem.touchPhaseName	= [self phaseName:touch.phase];
	
	touchedParticleSystem.location = [touch locationInView:self.view];
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
	
	touchedParticleSystem.touchPhaseName = [self phaseName:touch.phase];	
	[touchedParticleSystem setDecay:YES];
	
	[_particleSystems addObject:touchedParticleSystem];

	[touchedParticleSystem removeObserver:self forKeyPath:@"alive"];
	
	[touchedParticleSystem release];
	touchedParticleSystem = nil;
	
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
	
	[self disableAcclerometerEvents];
	
	GLView *glView = (GLView *)self.view;
	[glView stopAnimation];
		
}

#define kFilteringFactor			(0.10)
#define kAccelerometerFrequency		(30.0)

- (void)enableAcclerometerEvents {
	
	UIAccelerometer *theAccelerometer = [UIAccelerometer sharedAccelerometer];
	
	[theAccelerometer setUpdateInterval:(1.0 / kAccelerometerFrequency)];
	[theAccelerometer setDelegate:self];
	
}

- (void)disableAcclerometerEvents {
	
	UIAccelerometer *theAccelerometer = [UIAccelerometer sharedAccelerometer];
	
	theAccelerometer.delegate = nil;
	
}

- (void)accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*)acceleration {
	
	// Compute "G"
	_accelerationValue[0] = acceleration.x * kFilteringFactor + _accelerationValue[0] * (1.0 - kFilteringFactor);
	_accelerationValue[1] = acceleration.y * kFilteringFactor + _accelerationValue[1] * (1.0 - kFilteringFactor);
	_accelerationValue[2] = acceleration.z * kFilteringFactor + _accelerationValue[2] * (1.0 - kFilteringFactor);
	
	// ParticleSystem particles live in 2D. Use x and y compoments of "G"
	[ParticleSystem setGravity:CGPointMake(_accelerationValue[0], _accelerationValue[1])];
}


@end
