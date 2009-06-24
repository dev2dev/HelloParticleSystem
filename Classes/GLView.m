//
//  GLView.m
//  HelloTexture
//
//  Created by turner on 5/26/09.
//  Copyright Douglass Turner Consulting 2009. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import "GLView.h"
#import "GLViewController.h"

@interface GLView (private)

- (id)initGLES;
- (BOOL)createFramebuffer;
- (void)destroyFramebuffer;

@end

@implementation GLView

@synthesize backingWidth;
@synthesize backingHeight;
@synthesize animationInterval;

+ (Class) layerClass {
	return [CAEAGLLayer class];
}

-(id)initWithFrame:(CGRect)frame {
	
	self = [super initWithFrame:frame];
	
	if(self != nil) {
		self = [self initGLES];
	}
	
	return self;
}

- (id)initWithCoder:(NSCoder*)coder {
	
	if((self = [super initWithCoder:coder])) {
		
		self = [self initGLES];
	}	
	
	return self;
}

-(id)initGLES {
	
	CAEAGLLayer *eaglLayer = (CAEAGLLayer*) self.layer;
	
	eaglLayer.opaque = YES;
//	eaglLayer.opaque	= NO;	
//	eaglLayer.opacity	= 5.0f/10.0f;
	
	eaglLayer.drawableProperties = 
	[NSDictionary dictionaryWithObjectsAndKeys:
	[NSNumber numberWithBool:FALSE], 
	kEAGLDrawablePropertyRetainedBacking,
	 
	kEAGLColorFormatRGBA8, 
	 
	kEAGLDrawablePropertyColorFormat,
	nil];
	
	// Create our EAGLContext, and if successful make it current and create our framebuffer.
	context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
	
	if( !context ) {
		[self release];
		return nil;
	}
	
	if( ![EAGLContext setCurrentContext:context] ) {
		[self release];
		return nil;
	}
	
	if( ![self createFramebuffer] ) {
		[self release];
		return nil;
	}
	
	animationInterval = 1.0 / kRenderingFrequency;

	
    self.userInteractionEnabled	= YES;
//    self.multipleTouchEnabled	= YES;
    self.multipleTouchEnabled	= NO;
	
	
	return self;
}

-(GLViewController *)controller {
	return controller;
}

-(void)setController:(GLViewController *)d {
	controller = d;
	controllerSetup = ![controller respondsToSelector:@selector(setupView:)];
}

// If our view is resized, we'll be asked to layout subviews.
// This is the perfect opportunity to also update the framebuffer so that it is
// the same size as our display area.
-(void)layoutSubviews {
	
	[EAGLContext setCurrentContext:context];
	
	[self destroyFramebuffer];
	[self createFramebuffer];
	
	[self drawView];
}

- (BOOL)createFramebuffer {
	
	// Generate IDs for a framebuffer object and a color renderbuffer
	glGenFramebuffersOES(1, &viewFramebuffer);
	glGenRenderbuffersOES(1, &viewRenderbuffer);
	
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	
	// This call associates the storage for the current render buffer with the EAGLDrawable (our CAEAGLLayer)
	// allowing us to draw into a buffer that will later be rendered to screen whereever the layer is (which corresponds with our view).
	[context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(id<EAGLDrawable>)self.layer];
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);
	
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
	
	// For this sample, we also need a depth buffer, so we'll create and attach one via another renderbuffer.
	glGenRenderbuffersOES(1, &depthRenderbuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthRenderbuffer);
	glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, backingWidth, backingHeight);
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, depthRenderbuffer);

	if(glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES)
	{
		NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
		return NO;
	}
	
	return YES;
}

// Clean up any buffers we have allocated.
- (void)destroyFramebuffer {
	
	glDeleteFramebuffersOES(1, &viewFramebuffer);
	viewFramebuffer = 0;
	
	glDeleteRenderbuffersOES(1, &viewRenderbuffer);
	viewRenderbuffer = 0;
	
	if(depthRenderbuffer) {
		glDeleteRenderbuffersOES(1, &depthRenderbuffer);
		depthRenderbuffer = 0;
	}
}

- (void)startAnimation {
	animationTimer = [NSTimer scheduledTimerWithTimeInterval:animationInterval target:self selector:@selector(drawView) userInfo:nil repeats:YES];
}

- (void)stopAnimation {
	[animationTimer invalidate];
	animationTimer = nil;
}

- (void)setAnimationInterval:(NSTimeInterval)interval {
	
	animationInterval = interval;
	
	if(animationTimer) {
		[self stopAnimation];
		[self startAnimation];
	}
	
}

// Updates the OpenGL view when the timer fires
- (void)drawView {
	
	// Make sure that you are drawing to the current context
	[EAGLContext setCurrentContext:context];
	
	// If our drawing delegate needs to have the view setup, then call -setupView: and flag that it won't need to be called again.
	if(!controllerSetup) {
		[controller setupView:self];
		controllerSetup = YES;
	}
	
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	
	[controller drawView:self];
	
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER_OES];
	
	GLenum err = glGetError();
	if(err) {
		NSLog(@"%x error", err);
	}
	
}

// Stop animating and release resources when they are no longer needed.
- (void)dealloc {
	
	[self stopAnimation];
	
	if([EAGLContext currentContext] == context) {
		
		[EAGLContext setCurrentContext:nil];
	}
	
	[context release];
	context = nil;
	
	[super dealloc];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	
	[self.nextResponder touchesBegan:touches withEvent:event];

}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	
	[self.nextResponder touchesMoved:touches withEvent:event];
	
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	
	[self.nextResponder touchesEnded:touches withEvent:event];
	
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	
	[self.nextResponder touchesCancelled:touches withEvent:event];
	
}

@end
