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
//	[ParticleSystem buildBackdropWidth:[glView backingWidth] Height:[glView backingHeight]];
	[ParticleSystem buildBackdropWithBounds:[glView bounds]];
		
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
	
	glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
//	glClearColor(1.0f/2.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glEnable(GL_TEXTURE_2D);
	
    glEnable(GL_BLEND);

	glBlendFunc(GL_ONE,			GL_ONE_MINUS_SRC_ALPHA);
	
	// THIS IS SUPPOSED TO DO STREAKING
//	glBlendFunc(GL_SRC_ALPHA,	GL_ONE);	
	
	
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glEnableClientState(GL_COLOR_ARRAY);
	
}

- (void)drawView:(GLView*)view {
	
	
    NSTimeInterval time = [NSDate timeIntervalSinceReferenceDate];
	
	if (nil != _touchedParticleSystem) {
		
		if ([_touchedParticleSystem animateBetter:time]) {
			
			[_touchedParticleSystem drawBetter];
			
		} else {
			
			[_touchedParticleSystem release];
			_touchedParticleSystem = nil;
		}
		
	} // if (nil != _touchedParticleSystem)

	
    for (ParticleSystem *ps in _particleSystems) {
		
		if ([ps animateBetter:time]) {
			
            [ps drawBetter];			
			
		} else {
			
			[_deadParticleSystems	addObject:ps];
        }
		
    } // for (_particleSystems)

	
	for (ParticleSystem *ps in _deadParticleSystems) {
		
        [_particleSystems removeObjectIdenticalTo:ps];
    }
	
	[_deadParticleSystems removeAllObjects];
	


	
	
	glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
	//	glClearColor(1.0f/2.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);


	
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

@end
