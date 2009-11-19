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
	
	UIAccelerationValue _accelerationValueX;
	UIAccelerationValue _accelerationValueY;
	UIAccelerationValue _accelerationValueZ;
		
	ParticleSystem	*_touchedParticleSystem;
    NSMutableArray	*_particleSystems;
}

@property (nonatomic, assign) UIAccelerationValue	accelerationValueX;
@property (nonatomic, assign) UIAccelerationValue	accelerationValueY;
@property (nonatomic, assign) UIAccelerationValue	accelerationValueZ;
@property (nonatomic, retain) ParticleSystem		*touchedParticleSystem;
@property (nonatomic, retain) NSMutableArray		*particleSystems;

- (NSString*)phaseName:(UITouchPhase) phase;

- (void)startObservingParticleSystem:(ParticleSystem *)ps;
- (void)stopObservingParticleSystem:(ParticleSystem *)ps;

- (void)drawView:(GLView*)view;
- (void)setupView:(GLView*)view;

- (void)enableAcclerometerEvents;
- (void)disableAcclerometerEvents;

@end
