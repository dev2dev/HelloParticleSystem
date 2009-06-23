//
//  HelloParticleSystemAppDelegate.m
//  HelloParticleSystem
//
//  Created by turner on 6/15/09.
//  Copyright Douglass Turner Consulting 2009. All rights reserved.
//

#import "HelloParticleSystemAppDelegate.h"
#import "GLViewController.h"

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

@end

