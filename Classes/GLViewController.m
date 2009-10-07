//
//  GLViewController.h
//  HelloTexture
//
//  Created by turner on 5/26/09.
//  Copyright Douglass Turner Consulting 2009. All rights reserved.
//

#import <AudioToolbox/AudioServices.h>
#import <AVFoundation/AVFoundation.h>
#import "ConstantsAndMacros.h"
#import "GLViewController.h"
#import "GLView.h"
#import "ParticleSystem.h"

static UITouchPhase GLViewControllerCurrentTouchPhase = 0;

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

static SystemSoundID GLViewControllerSoundFX[3];


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
	AudioServicesCreateSystemSoundID((CFURLRef)soundURL, &GLViewControllerSoundFX[0]);
	
	soundURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"firework_2" ofType:@"wav"]];
	AudioServicesCreateSystemSoundID((CFURLRef)soundURL, &GLViewControllerSoundFX[1]);
	
	soundURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"firework_3" ofType:@"wav"]];
	AudioServicesCreateSystemSoundID((CFURLRef)soundURL, &GLViewControllerSoundFX[2]);
	

}

// Boom! Boom! Boom!
- (void)GLViewControllerPlaySoundFX {
	
	int index = (random() % 3);
	AudioServicesPlaySystemSound(GLViewControllerSoundFX[index]);

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
	
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
	
	// This behavior adds one additional particle as long as the touch phase has not ended (the finger is still touching the screen)
	// Alternatively I could do this in the touchesMoved:withEvent: method which would add a particle as long as the finger is being
	// dragged across the screen.
	
	if (GLViewControllerCurrentTouchPhase != UITouchPhaseEnded) {
		
		[[self touchedParticleSystem] addParticleAtBirthTime:now];
	} // if (GLViewControllerCurrentTouchPhase != UITouchPhaseEnded)
	
	// Update the state of all particle systems
    for (ParticleSystem *ps in particleSystems) {
		
		if (ps.alive == NO) {
			
			// If the entire particle system is dead, ignore it.
			continue;
			
		} // if (ps.alive == NO)
		
		// Update the particle system state. If live particles remain, draw them.
		if ([ps updateState:now]) {
			
			// Apply the changes in model state to the vertices that will be rendered by the GPU
            [ps prepareVerticesforRendering];			
			
		} // if ([ps updateState:now])
		
    } // for (particleSystems)
	
	
	// Once all particle systems are dead, stop observing and remove them.
	if ([ParticleSystem totalLivingParticles] == 0) {
		
		for (ParticleSystem *ps in particleSystems) {
			
			[self stopObservingParticleSystem:ps];
			
		} // for (particleSystems)
		
		[particleSystems removeAllObjects];
		
	} // if ([ParticleSystem totalLivingParticles] == 0)
	
	
	// NOTE: The background completely fills the window, eliminating the
	// need for a costly clearing of depth and color every frame.
	[ParticleSystem renderBackground];
	
	
	// Send vertices to GPU
	[ParticleSystem renderParticles];
	
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

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	//	id thang = (id)context;
	//	NSLog(@"Keypath(%@) Class(%@) Context(%@)", keyPath, [object class], [thang class]);
	
	//	if ([object isKindOfClass:[ParticleSystem class]]) {
	
	if ([keyPath isEqualToString:@"alive"]) {
		
		BOOL newValue = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
		
		// Do something at the birth of a particle system (alive = YES).
		if (newValue == YES) {
			
			//				NSLog(@"This %@ is alive.", [object class]);
			[self GLViewControllerPlaySoundFX];
			
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
- (NSString*)phaseName:(UITouchPhase) phase {
	
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
	
	// Only single touch for now
	UITouch *touch	= [touches anyObject];
	
	GLViewControllerCurrentTouchPhase = touch.phase;
	
	ParticleSystem *ps = [ [[ParticleSystem alloc] initAtLocation:[touch locationInView:self.view] birthTime:[NSDate timeIntervalSinceReferenceDate]] autorelease];
	
	[self startObservingParticleSystem:ps];
	[ps setValue:[NSNumber numberWithBool:YES] forKeyPath:@"alive"];
	
	ps.touchPhaseName = [self phaseName:touch.phase];
	self.touchedParticleSystem = ps;
	
	[particleSystems addObject:ps];	
	
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	
	// Only single touch for now
	UITouch *touch	= [touches anyObject];	
	
	GLViewControllerCurrentTouchPhase = touch.phase;
	
	self.touchedParticleSystem.touchPhaseName	= [self phaseName:touch.phase];
	self.touchedParticleSystem.location			= [touch locationInView:self.view];
	
	//	[self.touchedParticleSystem fill:[touch locationInView:self.view]];
	
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	
	// Only single touch for now
	UITouch *touch	= [touches anyObject];
	
	GLViewControllerCurrentTouchPhase = touch.phase;
	
	self.touchedParticleSystem.touchPhaseName = [self phaseName:touch.phase];	
	[self.touchedParticleSystem setDecay:YES];
	
	//	[self stopObservingParticleSystem:self.touchedParticleSystem];
	
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	
	UITouch *touch	= [touches anyObject];
	
	GLViewControllerCurrentTouchPhase = touch.phase;
	
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
