//
//  HelloParticleSystemAppDelegate.h
//  HelloParticleSystem
//
//  Created by turner on 6/15/09.
//  Copyright Douglass Turner Consulting 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GLViewController;

@interface HelloParticleSystemAppDelegate : NSObject <UIApplicationDelegate> {
	UIWindow				*window;
	GLViewController		*controller;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet GLViewController *controller;

@end

