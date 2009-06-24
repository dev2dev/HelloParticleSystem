//
//  GLView.h
//  HelloTexture
//
//  Created by turner on 5/26/09.
//  Copyright Douglass Turner Consulting 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import "ConstantsAndMacros.h"

@class GLViewController;
@interface GLView : UIView {
	@private
	// The pixel dimensions of the backbuffer
	GLint backingWidth;
	GLint backingHeight;
	
	EAGLContext *context;
	GLuint viewRenderbuffer;
	GLuint viewFramebuffer;
	GLuint depthRenderbuffer;
	NSTimer *animationTimer;
	NSTimeInterval animationInterval;

	GLViewController *controller;
	BOOL controllerSetup;
}

@property GLint backingWidth;
@property GLint backingHeight;
@property NSTimeInterval animationInterval;
@property(nonatomic, assign) GLViewController *controller;

-(void)startAnimation;
-(void)stopAnimation;
-(void)drawView;

@end
