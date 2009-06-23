// DO NOT USE THIS TEXTURE CLASS IN A SHIPPING APP: IT HAS BUGS AND IS FOR DEMO
// PURPOSES ONLY!
// Unless you fix the leaks... then go ahead and use it :-)



//
//  GLTexture.h
//  particleDemo
//
//  Created by Tim Omernick on 5/20/09.
//  Copyright 2009 ngmoco:). All rights reserved.
//

/*
--------

Copyright (c) 2009, ngmoco, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

   * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
   * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
   * Neither the name of ngmoco, Inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import <Foundation/Foundation.h>
#import <OpenGLES/ES1/gl.h>

@interface GLTexture : NSObject {
	
	BOOL isPowerOfTwo;
	
	int width;
	int height;
	
    GLuint _textureID;
}

- (void)bind;
- (id)initWithName:(NSString *)name andWidth:(int)w andHeight:(int)h;
- (id)initWithName:(NSString *)name storeAsPowerOfTwo:(BOOL)powerOfTwo;

@property (readonly) int width;
@property (readonly) int height;
@property (readonly) BOOL isPowerOfTwo;

@end
