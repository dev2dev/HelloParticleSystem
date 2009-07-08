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
	
	[controller addObserver:self forKeyPath:@"touchedParticleSystem"		options:0															context:self];
	[controller addObserver:self forKeyPath:@"touchedParticleSystem.alive"	options:(NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew) context:self];

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
	
	[controller removeObserver:self forKeyPath:@"touchedParticleSystem.alive"];
	[controller removeObserver:self forKeyPath:@"touchedParticleSystem"];

}

// Boom! Boom! Boom!
- (void)_playBoom {
	
    int index = (random() % 3);
    AudioServicesPlaySystemSound(_boomSoundIDs[index]);
	
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

	id thang = (id)context;
	NSLog(@"Context(%@) Object(%@)", [thang class], [object class]);

    if ([keyPath isEqualToString:@"touchedParticleSystem"]) {
		
		NSLog(@"keyPath(%@)", keyPath);
		return;
		
	} // if ([keyPath isEqualToString:@"touchedParticleSystem"])
	
    if ([keyPath isEqualToString:@"touchedParticleSystem.alive"]) {

		BOOL newValue	= [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
//		NSLog(@"Class(%@) keyPath(%@) NewValue(%d)", [object class], keyPath, newValue);
		
		// Play a sound announcing the birth of a particle system (alive = YES).
		if (newValue == YES) {
			
			NSLog(@"KeyPath(%@) I'm alive!", keyPath);
			[self _playBoom];
			
			return;
		}
		
		// Eventually, play a sound announcing the death of a particle system (alive = NO).
		if (newValue == NO) {
			
			NSLog(@"KeyPath(%@) I'm dead!", keyPath);
			return;
		}
		
		return;
		
	} // if ([keyPath isEqualToString:@"touchedParticleSystem.alive"])

	
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];

}

@end

