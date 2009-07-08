//
//  HelloParticleSystemAppDelegate.m
//  HelloParticleSystem
//
//  Created by turner on 6/15/09.
//  Copyright Douglass Turner Consulting 2009. All rights reserved.
//

#import "HelloParticleSystemAppDelegate.h"
#import "GLViewController.h"
#import "ParticleSystem.h"

@implementation HelloParticleSystemAppDelegate

@synthesize window;
@synthesize controller;

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
	
}

- (void)applicationWillTerminate:(UIApplication *)application {
	
//	[controller removeObserver:self forKeyPath:@"touchedParticleSystem.alive"];
//	[controller removeObserver:self forKeyPath:@"touchedParticleSystem"];

}

//- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
//
////	id thang = (id)context;
////	NSLog(@"Context(%@) Object(%@)", [thang class], [object class]);
//
//    if ([keyPath isEqualToString:@"touchedParticleSystem"]) {
//		
////		NSLog(@"keyPath(%@)", keyPath);
//		return;
//		
//	} // if ([keyPath isEqualToString:@"touchedParticleSystem"])
//	
//    if ([keyPath isEqualToString:@"touchedParticleSystem.alive"]) {
//
//		BOOL newValue = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
//		
//		// Play sound announcing the birth of a particle system (alive = YES).
//		if (newValue == YES) {
//			
////			NSLog(@"KeyPath(%@) I'm alive!", keyPath);
//			[self _playBoom];
//			
//			return;
//		}
//		
//		// Eventually, play sound announcing the death of a particle system (alive = NO).
//		if (newValue == NO) {
//			
////			NSLog(@"KeyPath(%@) I'm dead!", keyPath);
//			return;
//		}
//		
//		return;
//		
//	} // if ([keyPath isEqualToString:@"touchedParticleSystem.alive"])
//
//	
//	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
//
//}

@end

