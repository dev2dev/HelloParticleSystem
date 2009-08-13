//
//  GLViewController.h
//  HelloTexture
//
//  Created by turner on 5/26/09.
//  Copyright Douglass Turner Consulting 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import "GLView.h"

@class TEIParticle;
@class ParticleSystem;

@interface GLViewController : UIViewController <GLViewDelegate, UIAccelerometerDelegate> {
	
	UIAccelerationValue accelerationValueX;
	UIAccelerationValue accelerationValueY;
	UIAccelerationValue accelerationValueZ;
		
	ParticleSystem	*_touchedParticleSystem;
    NSMutableArray	*particleSystems;
}

@property UIAccelerationValue accelerationValueX;
@property UIAccelerationValue accelerationValueY;
@property UIAccelerationValue accelerationValueZ;

@property (nonatomic, retain) ParticleSystem *touchedParticleSystem;
@property (nonatomic, retain) NSMutableArray *particleSystems;

- (NSString*) phaseName:(UITouchPhase) phase;

- (void)startObservingParticle:(TEIParticle *)p;
- (void)stopObservingParticle:(TEIParticle *)p;

- (void)startObservingParticleSystem:(ParticleSystem *)ps;
- (void)stopObservingParticleSystem:(ParticleSystem *)ps;

- (void)drawView:(GLView*)view;
- (void)setupView:(GLView*)view;

- (void)enableAcclerometerEvents;
- (void)disableAcclerometerEvents;

@end
