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

@synthesize touchedParticleSystem=_touchedParticleSystem;
@synthesize particleSystems;

- (void)dealloc {
	
	[particleSystems		removeAllObjects];	
	[particleSystems		release];
	
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

// Draw an OpenGL frame
- (void)drawView:(GLView*)view {
	
    NSTimeInterval time = [NSDate timeIntervalSinceReferenceDate];
	
    for (ParticleSystem *ps in particleSystems) {
				
		// If the entire particle system is dead, ignore it.
		if ([ [ ps valueForKey:@"alive" ] boolValue ] == NO) {
			continue;
		}
		
		// If there are remaining live particles, draw them.
		if ([ps animate:time]) {
			
            [ps draw];			
        }
		
    } // for (particleSystems)

	// Once all particle systems are dead, discard the lot.
	if ([self countLiveParticleSystems] == 0) {
		
		[particleSystems removeAllObjects];
	}
	
	// NOTE: The background completely fills the window, eliminating the
	// need for a costly clearing of depth and color every frame.
	[ParticleSystem renderBackground];
	
	// Render particles
	[ParticleSystem renderParticles];
	
}

// How many live particle systems do we have
- (int) countLiveParticleSystems {
	
	int live = 0;
	for (ParticleSystem *ps in particleSystems) {
		
		if ([ [ ps valueForKey:@"alive" ] boolValue ] == YES) {
			++live;
		}
		
    } // for (deadParticleSystems)
	
	return live;
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

// Keep track of the currently "touched" particle system
// so that we can up date it's location during touchesMoved:withEvent
// and also enable decaying of the particle system during
// touchesEnded:withEvent
//static ParticleSystem *touched = nil;

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {

	// Only single touch for now
	UITouch *touch	= [touches anyObject];
	
	ParticleSystem *p = [[[ParticleSystem alloc] initAtLocation:[touch locationInView:self.view]] autorelease];
	p.touchPhaseName = [self phaseName:touch.phase];
//	NSLog(@"p = [[alloc] init]                                   P RetainCount(%d)", [p retainCount]);
	
//	_touchedParticleSystem = p;
	[self setValue:p forKeyPath:@"touchedParticleSystem"];
//	self.touchedParticleSystem = p;
//	NSLog(@"_touchedParticleSystem = p		                     P RetainCount(%d)", [p							retainCount]);
//	NSLog(@"_touchedParticleSystem = p		_touchedParticleSystem RetainCount(%d)", [self.touchedParticleSystem	retainCount]);
	
	[particleSystems addObject:p];
//	NSLog(@"[particleSystems addObject:p]		                 P RetainCount(%d)", [p							retainCount]);
//	NSLog(@"[particleSystems addObject:p]	_touchedParticleSystem RetainCount(%d)", [self.touchedParticleSystem	retainCount]);

	
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	
	// Only single touch for now
	UITouch *touch	= [touches anyObject];	

	_touchedParticleSystem.touchPhaseName	= [self phaseName:touch.phase];
	_touchedParticleSystem.location			= [touch locationInView:self.view];
	
//	[_touchedParticleSystem fill:[touch locationInView:self.view]];
	
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	
	// Only single touch for now
	UITouch *touch	= [touches anyObject];

	_touchedParticleSystem.touchPhaseName = [self phaseName:touch.phase];	
	[_touchedParticleSystem setDecay:YES];

}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	
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
