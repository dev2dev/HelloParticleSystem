//
//  GLViewController.h
//  HelloTexture
//
//  Created by turner on 5/26/09.
//  Copyright Douglass Turner Consulting 2009. All rights reserved.
//

#import "ConstantsAndMacros.h"
#import "GLViewController.h"
#import "GLView.h"
#import "ParticleSystem.h"

@implementation GLViewController

@synthesize testing123;

@synthesize accelerationValueX;
@synthesize accelerationValueY;
@synthesize accelerationValueZ;

@synthesize touchedParticleSystem = _touchedParticleSystem;
@synthesize particleSystems;
@synthesize deadParticleSystems;

- (void)dealloc {
	
	[_touchedParticleSystem release];
	
	[particleSystems		removeAllObjects];	
	[particleSystems		release];
	
	[deadParticleSystems	removeAllObjects];	
	[deadParticleSystems	release];
	
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

// The Stanford Pattern
- (void)viewDidLoad {
	
	// Prepare particle system arrays
	particleSystems		= [[NSMutableArray alloc] init];
	deadParticleSystems	= [[NSMutableArray alloc] init];

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
	
    NSTimeInterval time = [NSDate timeIntervalSinceReferenceDate];
	
	if (nil != _touchedParticleSystem) {
		
		NSLog(@"GLViewController.drawView _touchedParticleSystem(NON-NIL) particleSystems(%d) touchPhaseName(%@)", 
			  [particleSystems count], _touchedParticleSystem.touchPhaseName);
		
		if ([_touchedParticleSystem animate:time]) {
			
			[_touchedParticleSystem draw];
			
		} else {
			
			[_touchedParticleSystem release];
			_touchedParticleSystem = nil;
		}
		
	} // if (nil != _touchedParticleSystem)

	
    for (ParticleSystem *ps in particleSystems) {
		
//		NSLog(@"GLViewController.drawView - drawing       particleSystems touchPhaseName(%@)", ps.touchPhaseName);
		
		if ([ps animate:time]) {
			
            [ps draw];			
			
		} else {
			
			[deadParticleSystems	addObject:ps];
        }
		
    } // for (_particleSystems)

	
	for (ParticleSystem *ps in deadParticleSystems) {
		
        [particleSystems removeObjectIdenticalTo:ps];
    }
	
	[deadParticleSystems removeAllObjects];
	
	
	// NOTE: The background should completely fill the window, eliminating the
	// need for a costly clearing of depth and color every frame.
	[ParticleSystem renderBackground];
	
	[ParticleSystem renderParticles];
	
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
	
	ParticleSystem* ps = nil;
	ps = [[[ParticleSystem alloc] initAtLocation:[touch locationInView:self.view]] autorelease];
	ps.touchPhaseName = [self phaseName:touch.phase];

//	self.touchedParticleSystem = ps;
	[self setValue:ps								forKeyPath:@"_touchedParticleSystem"];
//	[self setValue:[NSNumber numberWithBool:YES]	forKeyPath:@"_touchedParticleSystem.alive"];
	
	
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
	
	_touchedParticleSystem.touchPhaseName	= [self phaseName:touch.phase];
	
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
	
	[particleSystems addObject:_touchedParticleSystem];
	
	[_touchedParticleSystem release];
	_touchedParticleSystem = nil;
	
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

#define kFilteringFactor			( 0.1)
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
	accelerationValueX = acceleration.x * kFilteringFactor + accelerationValueX * (1.0 - kFilteringFactor);
	accelerationValueY = acceleration.y * kFilteringFactor + accelerationValueY * (1.0 - kFilteringFactor);
	accelerationValueZ = acceleration.z * kFilteringFactor + accelerationValueZ * (1.0 - kFilteringFactor);
	
	// ParticleSystem particles live in 2D. Use x and y compoments of "G"
	[ParticleSystem setGravity:CGPointMake(accelerationValueX, accelerationValueY)];
}


@end
