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

@class GLView;
@class ParticleSystem;

@interface GLViewController : UIViewController  <UIAccelerometerDelegate> {
	
	int testing123;
	
	UIAccelerationValue accelerationValueX;
	UIAccelerationValue accelerationValueY;
	UIAccelerationValue accelerationValueZ;
		
	ParticleSystem		*_touchedParticleSystem;
    NSMutableArray		*particleSystems;
    NSMutableArray		*deadParticleSystems;
}

@property int testing123;

@property UIAccelerationValue accelerationValueX;
@property UIAccelerationValue accelerationValueY;
@property UIAccelerationValue accelerationValueZ;

@property (nonatomic, retain) ParticleSystem *touchedParticleSystem;
@property (nonatomic, retain) NSMutableArray *particleSystems;
@property (nonatomic, retain) NSMutableArray *deadParticleSystems;

- (NSString*) phaseName:(UITouchPhase) phase;

- (void)drawView:(GLView*)view;
- (void)setupView:(GLView*)view;

- (void)enableAcclerometerEvents;
- (void)disableAcclerometerEvents;

@end
