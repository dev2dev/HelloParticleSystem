//
//  SoundFXOperation.h
//  HelloParticleSystem
//
//  Created by turner on 8/27/09.
//  Copyright 2009 Douglass Turner Consulting. All rights reserved.
//

#import <Foundation/NSOperation.h>
#import <AVFoundation/AVFoundation.h>

@interface SoundFXOperation : NSOperation {
	
	NSData			*data;
	AVAudioPlayer	*player;

}

- (id)initWithData:(NSData *)aData;
- (id)initWithPlayer:(AVAudioPlayer *)aPlayer;

@end

