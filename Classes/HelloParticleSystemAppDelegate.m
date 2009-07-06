//
//  HelloParticleSystemAppDelegate.m
//  HelloParticleSystem
//
//  Created by turner on 6/15/09.
//  Copyright Douglass Turner Consulting 2009. All rights reserved.
//

#import <AudioToolbox/AudioServices.h>

#import "HelloParticleSystemAppDelegate.h"
#import "GLViewController.h"
#import "ParticleSystem.h"

@implementation HelloParticleSystemAppDelegate

@synthesize window;
@synthesize controller;

static SystemSoundID _boomSoundIDs[3];

// The following is from Stanford Class Lecture #6 ViewController LifeCycle Pattern

// The Stanford Patterm
- (void)dealloc {
	
    [controller release];
    [window release];
    [super dealloc];
}

// The Stanford Patterm
- (void)applicationDidFinishLaunching:(UIApplication *)application {
	
    [window addSubview:controller.view];
    [window makeKeyAndVisible];
	
	[controller addObserver:self forKeyPath:@"_touchedParticleSystem"		options:0 context:NULL];
//	[controller addObserver:self forKeyPath:@"_touchedParticleSystem.alive"	options:0 context:NULL];

	// set up sound effects
	NSURL *soundURL = nil;
	
	soundURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"firework_6" ofType:@"wav"]];
	AudioServicesCreateSystemSoundID((CFURLRef)soundURL, &_boomSoundIDs[0]);
	
	soundURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"firework_2" ofType:@"wav"]];
	AudioServicesCreateSystemSoundID((CFURLRef)soundURL, &_boomSoundIDs[1]);
	
	soundURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"firework_3" ofType:@"wav"]];
	AudioServicesCreateSystemSoundID((CFURLRef)soundURL, &_boomSoundIDs[2]);
	
}

- (void)applicationWillTerminate:(UIApplication *)application {
	
	// do your stuff here...
//	[controller removeObserver:self forKeyPath:@"_touchedParticleSystem.alive"];
	[controller removeObserver:self forKeyPath:@"_touchedParticleSystem"];

}

// Boom! Boom! Boom!
- (void)_playBoom {
	
    int index = (random() % 3);
    AudioServicesPlaySystemSound(_boomSoundIDs[index]);
	
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
    if ([keyPath isEqualToString:@"_touchedParticleSystem"]) {
		
		// do stuff
		NSLog(@"keyPath(%@)", keyPath);
		
		[self _playBoom];
		
		return;
	} 
	
//    if ([keyPath isEqualToString:@"_touchedParticleSystem.alive"]) {
//				
//		BOOL b = controller.touchedParticleSystem.alive;
//
//		NSLog(@"keyPath(%@) Value(%d)", keyPath, b);
//		
//		
//		return;
//	} 
	
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];

}

@end

