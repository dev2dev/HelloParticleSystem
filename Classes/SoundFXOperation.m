//
//  SoundFXOperation.m
//  HelloParticleSystem
//
//  Created by turner on 8/27/09.
//  Copyright 2009 Douglass Turner Consulting. All rights reserved.
//

#import "SoundFXOperation.h"

@implementation SoundFXOperation

- (void)dealloc {
	
    [data	release];
    [player	release];
	
    [super dealloc];
}

- (id)initWithData:(NSData *)aData {
	
	self = [super init];
	
	if(nil != self) {
		
		data = [aData retain];

		NSError *error;
		player = [[AVAudioPlayer alloc]initWithData:data error:&error];
		
		if (player == nil) {
			NSLog([error description]);
		}
		
		// Doesn't seem to help very much ...
		[player prepareToPlay];
		
	}
	
	return self;
}

- (id)initWithPlayer:(AVAudioPlayer *)aPlayer {
	
	self = [super init];
	
	if(nil != self) {

		player	= [aPlayer	retain];
	
	}
	
	return self;
}

- (void)main {
	
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    @try {
		
		NSLog(@"SoundFXOperation:main:try: BEFORE [player play]");
        [player play];
		NSLog(@"SoundFXOperation:main:try:  AFTER [player play]");
		
		
    } 
	@catch (NSException *e) {
		
		NSLog(@"SoundFXOperation:main:catch: Exception!!!");
    } 
	@finally {
		
		NSLog(@"SoundFXOperation:main:finally:  draining the autorelease pool.");
        [pool drain];
    }
	
}

@end
