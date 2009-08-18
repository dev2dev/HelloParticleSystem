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
	
	glView = [[[GLView alloc] initWithFrame:applicationFrame] autorelease];
	glView.drawingDelegate = self;
	
	self.view = glView;

}

static SystemSoundID _boomSoundIDs[3];

// The Stanford Pattern
- (void)viewDidLoad {
	
	// Prepare particle system arrays
	particleSystems		= [[NSMutableArray alloc] init];

	[ParticleSystem buildParticleTextureAtlas];
	
	GLView *glView = (GLView *)self.view;
	[ParticleSystem buildBackdropWithBounds:[glView bounds]];
	
	// set up sound effects
	NSURL *soundURL = nil;
	
	soundURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"firework_6" ofType:@"wav"]];
	AudioServicesCreateSystemSoundID((CFURLRef)soundURL, &_boomSoundIDs[0]);
	
	soundURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"firework_2" ofType:@"wav"]];
	AudioServicesCreateSystemSoundID((CFURLRef)soundURL, &_boomSoundIDs[1]);
	
	soundURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"firework_3" ofType:@"wav"]];
	AudioServicesCreateSystemSoundID((CFURLRef)soundURL, &_boomSoundIDs[2]);
	
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
		if (ps.alive == NO) {
			
			continue;
		}
		
		// If there are remaining live particles, draw them.
		if ([ps animate:time]) {
	
//			NSLog(@"ParticleSystem(%d) TouchPhaseName(%@)", [particleSystems indexOfObject:ps], ps.touchPhaseName);

            [ps draw];			
			
		}
		
    } // for (particleSystems)

	// Once all particle systems are dead, discard the lot.
	if ([ParticleSystem totalLivingParticles] == 0) {

//		NSLog(@"All particles are dead. Stop Observing.");

		for (ParticleSystem *ps in particleSystems) {
			
//			for (TEIParticle *p in ps.particles) {
//				
//				[self stopObservingParticle:p];
//				
//			} // for (ps.particles)
			
			[self stopObservingParticleSystem:ps];
			
		} // for (particleSystems)
		
		[particleSystems removeAllObjects];
		
	}
	
	// NOTE: The background completely fills the window, eliminating the
	// need for a costly clearing of depth and color every frame.
	[ParticleSystem renderBackground];
	
	// Render particles
	[ParticleSystem renderParticles];
	
}

- (void)startObservingParticle:(TEIParticle *)p {
	
    [p addObserver:self
		 forKeyPath:@"alive"
			options:(NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew)
			context:p];
	
}

- (void)stopObservingParticle:(TEIParticle *)p {
	
    [p removeObserver:self forKeyPath:@"alive"];
}

- (void)startObservingParticleSystem:(ParticleSystem *)ps {
	
    [ps addObserver:self
		 forKeyPath:@"alive"
			options:(NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew)
			context:ps];
	
}

- (void)stopObservingParticleSystem:(ParticleSystem *)ps {
	
    [ps removeObserver:self forKeyPath:@"alive"];
}

// Boom! Boom! Boom!
- (void)_playBoom {
	
    int index = (random() % 3);
    AudioServicesPlaySystemSound(_boomSoundIDs[index]);
	
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
//	id thang = (id)context;
//	NSLog(@"Keypath(%@) Class(%@) Context(%@)", keyPath, [object class], [thang class]);
	
//	if ([object isKindOfClass:[ParticleSystem class]]) {
		
		if ([keyPath isEqualToString:@"alive"]) {
			
			BOOL newValue = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
			
			// Do something at the birth of a particle system (alive = YES).
			if (newValue == YES) {
				
//				NSLog(@"This %@ is alive.", [object class]);
				[self _playBoom];
				
				return;
			}
			
			// Do something at the death of a particle system (alive = NO).
			if (newValue == NO) {
				
//				NSLog(@"This %@ is dead.", [object class]);
				return;
			}
			
			return;
			
//		} // if ([object isKindOfClass:[ParticleSystem class]])
		
	} // if (context == ParticleSystem)
	
//	if ([object isKindOfClass:[TEIParticle class]]) {
//		
//		if ([keyPath isEqualToString:@"alive"]) {
//			
//			BOOL newValue = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
//			
//			// Do something at the birth of a particle (alive = YES).
//			if (newValue == YES) {
//				
//				NSLog(@"This %@ is alive.", [object class]);
//				return;
//			}
//			
//			// Do something at the death of a particle (alive = NO).
//			if (newValue == NO) {
//				
//				NSLog(@"This %@ is dead.", [object class]);
//				return;
//			}
//			
//			return;
//			
//		} // if ([keyPath isEqualToString:@"alive"])
//		
//	} // if ([object isKindOfClass:[TEIParticle class]])
	
	
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	
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
	
	ParticleSystem *ps = [ [[ParticleSystem alloc] initAtLocation:[touch locationInView:self.view]] autorelease ];
	
//	ParticleSystem *ps = [
//						 [[ParticleSystem alloc] initAtLocation:[touch locationInView:self.view] 
//														 target:self 
//												  startSelector:@selector(startObservingParticle:)
//												   stopSelector:@selector(stopObservingParticle:)
//						  ] 
//						 autorelease];
	
	[self startObservingParticleSystem:ps];
	[ps setValue:[NSNumber numberWithBool:YES] forKeyPath:@"alive"];
	
	ps.touchPhaseName = [self phaseName:touch.phase];
//	NSLog(@"ps = [[alloc] init]                                   P RetainCount(%d)", [ps retainCount]);

	
//	[self setValue:ps forKeyPath:@"touchedParticleSystem"];
	self.touchedParticleSystem = ps;

	
//	NSLog(@"self.touchedParticleSystem = ps		                     P RetainCount(%d)", [ps							retainCount]);
//	NSLog(@"self.touchedParticleSystem = ps		self.touchedParticleSystem RetainCount(%d)", [self.touchedParticleSystem	retainCount]);

	
	

	[particleSystems addObject:ps];	
//	NSUInteger i = [particleSystems indexOfObject:ps];
//	[self startObservingParticleSystem:[particleSystems objectAtIndex:i]];
//	[[particleSystems objectAtIndex:i] setValue:[NSNumber numberWithBool:YES] forKeyPath:@"alive"];

	
	
//	NSLog(@"[particleSystems addObject:ps]		                 P RetainCount(%d)", [ps							retainCount]);
//	NSLog(@"[particleSystems addObject:ps]	self.touchedParticleSystem RetainCount(%d)", [self.touchedParticleSystem	retainCount]);

	
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	
	// Only single touch for now
	UITouch *touch	= [touches anyObject];	

	self.touchedParticleSystem.touchPhaseName	= [self phaseName:touch.phase];
	self.touchedParticleSystem.location			= [touch locationInView:self.view];
	
//	[self.touchedParticleSystem fill:[touch locationInView:self.view]];
	
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	
	// Only single touch for now
	UITouch *touch	= [touches anyObject];

	self.touchedParticleSystem.touchPhaseName = [self phaseName:touch.phase];	
	[self.touchedParticleSystem setDecay:YES];

//	[self stopObservingParticleSystem:self.touchedParticleSystem];

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
