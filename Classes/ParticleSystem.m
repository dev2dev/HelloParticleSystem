
#import <OpenGLES/ES1/gl.h>
#import "ParticleSystem.h"


static void _checkGLError(void) {
	
    GLenum error = glGetError();
    if (error) {
        fprintf(stderr, "GL Error: %x\n", error);
        exit(0);
    }
}

typedef struct _ParticleSystemOpenGLVertexData { short xy[2]; unsigned argb; float st[2]; } ParticleSystemOpenGLVertexData;


// Particle vertext array
#define MAX_VERTS (20000)
static int ParticleSystemParticleVertexCount = 0;
static ParticleSystemOpenGLVertexData ParticleSystemParticleVertices[MAX_VERTS];

// Background rectangular card
static ParticleSystemOpenGLVertexData ParticleSystemBackdropRectangeVertices[4];

static void 
ParticleSystemAddVertex(ParticleSystemOpenGLVertexData* vertices, float x, float y, float s, float t, unsigned argb, int *counter) {
	
//    ParticleSystemOpenGLVertexData *vert = &vertices[ParticleSystemParticleVertexCount];	
//	
//	// spatial vertex
//    vert->xy[0] = (short)x;
//    vert->xy[1] = (short)y;
//	
//	// teture vertex
//    vert->st[0] = s;
//    vert->st[1] = t;
//	
//	// alpha | red | green | blue
//    vert->argb = argb;

	// spatial vertex
    vertices[(*counter)].xy[0] = (short)x;
    vertices[(*counter)].xy[1] = (short)y;
	
	// teture vertex
    vertices[(*counter)].st[0] = s;
    vertices[(*counter)].st[1] = t;
	
	// alpha | red | green | blue
    vertices[(*counter)].argb = argb;
	
	
	(*counter)++;
}

#define TEXTURE_ATLAS_NXN_DIMENSION (3)
#define NUM_TEXTURES (TEXTURE_ATLAS_NXN_DIMENSION * TEXTURE_ATLAS_NXN_DIMENSION)

@implementation TEIParticle

@synthesize alive;
@synthesize birth;

@synthesize location;
@synthesize velocity;

@synthesize textureAtlasS;
@synthesize textureAtlasT;

@synthesize alpha;

@synthesize size;

@synthesize rotation;
@synthesize rotationDirection;

- (void)dealloc {
	
    [super dealloc];
}

- (id)init {
	
	if(self = [super init]) {
		// do stuff
	}
	
	return self;
}

- (id)initAtLocation:(CGPoint)newLocation birthTime:(double)time willPush:(BOOL)push {
	
	self = [super init];
	
	if(nil != self) {
		
		alive = YES;
		
		// location
		location = newLocation;
		
		// rotation
		float angle = (arc4random() % 360) * (M_PI / 180.0f);
		
		// scalefactor
		float scale = 30.0f + (arc4random() % 120);
		
		// velocity
		velocity.x = cosf(angle) * scale;
		velocity.y = sinf(angle) * scale;
		
		// give particles slightly different vertical velocities
		if (push == YES) {
			velocity.y -= 30.0f + (arc4random() % 30);
		}
		
		// birth time
		self.birth = time;
		
		// alpha
		alpha = 1.0f;
		
		// size
//		size = 0.0f;
		size = 1.0f;
		
		// randomize rotation direction
		if (arc4random() % 2 == 0) {
			
			rotationDirection = -1.0;
		} else {
			
			rotationDirection =  1.0;
		}
		
		rotation = (arc4random() % 360) * (M_PI / 180.0f);
		
		// randomly select section of texture atlas
		textureAtlasS = arc4random() % TEXTURE_ATLAS_NXN_DIMENSION;
		textureAtlasT = arc4random() % TEXTURE_ATLAS_NXN_DIMENSION;
		
	}
	
	return self;
}

@end

@implementation ParticleSystem

static TEITexture		*ParticleSystemParticleTexture		= nil;
static TEITexture		*ParticleSystemBackdropTexture		= nil;
static NSMutableArray	*ParticleSystemTextureCoordinates	= nil;

@synthesize location=_location;
@synthesize particleTraunch=_particleTraunch;
@synthesize touchPhaseName;

- (void)dealloc {

	[_openglPackedVertices	removeAllObjects];
	[_particles				removeAllObjects];
	
	[_openglPackedVertices	release];
	[_particles				release];
    
	[touchPhaseName			release];
	
    [super dealloc];
}

- (id)init {

	return [self initAtLocation:CGPointMake(0.0, 0.0)];
	
		}

- (id)initAtLocation:(CGPoint)location {
	
	if (self = [super init]) {
		
		_openglPackedVertices =	[[NSMutableArray alloc] init];
		_particles		=		[[NSMutableArray alloc] init];
		
		_initialAnimationStep	= YES;
		
		_location				= location;
		_particleTraunch		= 16;
		_birth					= [NSDate timeIntervalSinceReferenceDate];
		_mostRecentTime			= [NSDate timeIntervalSinceReferenceDate];
	}
	
    return self;
}

+ (void)buildParticleTextureAtlas {
	
//	ParticleSystemParticleTexture = 
//	[ [TEITexture alloc] initWithImageFile:@"kids_grid_3x3"				extension:@"png" mipmap:YES ];
	
	ParticleSystemParticleTexture = 
	[ [TEITexture alloc] initWithImageFile:@"kids_grid_3x3_translucent"	extension:@"png" mipmap:YES ];
	
//	ParticleSystemParticleTexture = 
//	[ [TEITexture alloc] initWithImageFile:@"particles_dugla"			extension:@"png" mipmap:YES ];
	
	[self buildTextureAtlasIndexTable];
		
}

+ (void)buildTextureAtlasIndexTable {
	
	static BOOL textureCoordinateTableIsBuilt = NO;
	
	if (textureCoordinateTableIsBuilt == YES) {
		return;
	}
	
	ParticleSystemTextureCoordinates = [[NSMutableArray alloc] init];
	
	for (int i = 0; i < TEXTURE_ATLAS_NXN_DIMENSION; i++) {
		
		float t = (float)i;
		
		t /= ((float)TEXTURE_ATLAS_NXN_DIMENSION);
		[ParticleSystemTextureCoordinates addObject:[NSNumber numberWithFloat:t]];
	}
	
	textureCoordinateTableIsBuilt = YES;
	
}

+ (void)buildBackdropWithBounds:(CGRect)bounds {
	
	// OpenGL defaults to CCW winding rule for triangles.
	// The patten is: V0 -> V1 -> V2 then V2 -> V1 -> V3 ... etc.
	// At draw time I use glDrawArrays(GL_TRIANGLE_STRIP, 0, _vertexCount)
	// addVertex(x,y,  r,g,b,a,  s,t)
		
	// Good ole 8-bit pixels. Format is: a r g b
	unsigned char a = 255;       
	unsigned char rgb[3] = { 255, 255, 255 };
	unsigned argb = (a << 24) | (rgb[0] << 16) | (rgb[1] << 8) | (rgb[2] << 0);
	
	GLfloat n_xy = bounds.origin.y;
	GLfloat s_xy = bounds.size.height;
	
	GLfloat w_xy = bounds.origin.x;
	GLfloat e_xy = bounds.size.width;
	
	GLfloat n_st = 1.0f;
	GLfloat s_st = 0.0f;
	
	GLfloat w_st = 0.0f;
	GLfloat e_st = 1.0f;
//	
//	// V0
//	ParticleSystemAddVertex(ParticleSystemBackdropRectangeVertices, w_xy, s_xy, 0.0f, 0.0f, argb, &ParticleSystemBackdropRectangeVertexCount);
//	
//	// V1
//	ParticleSystemAddVertex(ParticleSystemBackdropRectangeVertices, e_xy, s_xy, 1.0f, 0.0f, argb, &ParticleSystemBackdropRectangeVertexCount);
//	
//	// V2
//	ParticleSystemAddVertex(ParticleSystemBackdropRectangeVertices, w_xy, n_xy, 0.0f, 1.0f, argb, &ParticleSystemBackdropRectangeVertexCount);
//	
//	// V3
//	ParticleSystemAddVertex(ParticleSystemBackdropRectangeVertices, e_xy, n_xy, 1.0f, 1.0f, argb, &ParticleSystemBackdropRectangeVertexCount);

	static int unused = 0;
	
	// V0
	ParticleSystemAddVertex(ParticleSystemBackdropRectangeVertices, w_xy, s_xy, w_st, s_st, argb, &unused);
	
	// V1
	ParticleSystemAddVertex(ParticleSystemBackdropRectangeVertices, e_xy, s_xy, e_st, s_st, argb, &unused);
	
	// V2
	ParticleSystemAddVertex(ParticleSystemBackdropRectangeVertices, w_xy, n_xy, w_st, n_st, argb, &unused);
	
	// V3
	ParticleSystemAddVertex(ParticleSystemBackdropRectangeVertices, e_xy, n_xy, e_st, n_st, argb, &unused);
	
	
	ParticleSystemBackdropTexture = 
//	[ [TEITexture alloc] initWithImageFile:@"mandrill"		extension:@"png" mipmap:YES ];
	[ [TEITexture alloc] initWithImageFile:@"swirl-rose"	extension:@"png" mipmap:YES ];
	
}

- (void)setDecay:(BOOL)decay {
	
    if (decay == _decay) {
		
		return;
	}
	
    _decay = decay;
}

- (void)fill:(CGPoint)location  {
	
	if (CGPointEqualToPoint(_location, location) == YES) {
		
		return;
	}
	
//    double now = [NSDate timeIntervalSinceReferenceDate];
//	
//	float dx = _location.x - location.x;
//	float dy = _location.y - location.y;
//	float distance = sqrt((dx * dx) + (dy * dy));
//	
//	static const float step = 5.0f;
//	
//	unsigned count = distance / step;
//	
//	for (unsigned i = 0; i < count; i++) {
//		
//		float fraction = (float)i / (float)count;
//		
//		CGPoint loc;
//		loc.x = _location.x + (dx * fraction);
//		loc.y = _location.y + (dy * fraction);
//		
//		TEIParticle* particle = [[TEIParticle alloc] initAtLocation:loc birthTime:now willPush:NO ];
//		
//		[_particles addObject:particle];
//		
//		[particle release];
//		
//	} // for (count)
	
    _location = location;
}

- (BOOL)animateBetter:(NSTimeInterval)time {

	NSTimeInterval step;
	
	if (_initialAnimationStep == YES) {
		
		_birth	= time;
		step	= (NSTimeInterval)0.0;	
		
    } else {
		
		step = (time - _lastTime);
	}
	
    _lastTime = time;
	
	// :::::::::::::::::::::::::::::: bring particles to life :::::::::::::::::::::::::
    if (_decay == NO || _initialAnimationStep == YES) {
		
		if (_birth == time) {
			
			for (int i = 0; i < _particleTraunch; i++) {
				
				TEIParticle* particle = [[TEIParticle alloc] initAtLocation:_location birthTime:time willPush:YES];
				
				[_particles addObject:particle];
				
				[particle release];
				
			} // for (count)
			
		} else {
			
			TEIParticle* particle = [[TEIParticle alloc] initAtLocation:_location birthTime:time willPush:NO];
			
			[_particles addObject:particle];
			
			[particle release];
			
		}
				
    } // if (_decay == NO || _initialAnimationStep == YES)

	_initialAnimationStep = NO;

	// Take a time step in particle system state. Cull dead particles as needed.
	
	for (TEIParticle* particle in _particles) {
		
		if (particle.alive == NO) {
			continue;
		}

		// gravity
		static const float gravity = 120.0f;
		
		// velocity
		particle.velocity = CGPointMake(particle.velocity.x, particle.velocity.y + (gravity * step));
				
		// take a step in time to integrate velocity into distance
		float dx = particle.velocity.x * step;
		float dy = particle.velocity.y * step;
		
		// add delta step to location to compute new location
		particle.location = CGPointMake(particle.location.x + dx, particle.location.y + dy);
		
		
		// fall off bottom of screen
		if (particle.location.y > 500) {
			
			particle.alive = NO;
			continue;
		}
		
		static const float fadeTime = 3.0f;
		float elapsedTimeSinceBirth	= (time - particle.birth);		
		float fadeFraction			= MIN(1.0f, elapsedTimeSinceBirth / fadeTime);

		
		
		// ::::::::::::::::::::::::::::: IGNORE FADING OUT THE SPRITE FOR NOW :::::::::::::::::::::::::::::
		// fade
//		particle.alpha = 0.8f;
//		
//		particle.alpha *= 1.0 - fadeFraction;
//		
//		if (fadeFraction >= 1.0f) {
//			
//			particle.alive = NO;
//			continue;
//		}
		// ::::::::::::::::::::::::::::: IGNORE FADING OUT THE SPRITE FOR NOW :::::::::::::::::::::::::::::

		
		
		
		
		// scale
		if (fadeFraction < 0.08f)     particle.size = fadeFraction / 0.08f;
		else if (fadeFraction > 0.8f) particle.size = 1.0 - ((fadeFraction - 0.8f) / 0.2f);
		else                          particle.size = 1.0f;
		
		
		// rotate
		float rotationRate = 5.0f/2.0f;
		particle.rotation += rotationRate * step * particle.rotationDirection;

		
		
	} // for (_particles)

			
	for (TEIParticle *particle in _particles) {
		
		if (particle.alive == YES) {
						
			return YES;
			
		} // if (particle.alive = YES)
		
	} // for (TEIParticle *particle in _particles)

	return NO;
	
}

static inline float VFPFastAbs(float x) { 
	return (x < 0) ? -x : x; 
}

static inline float VFPFastSin(float x) {
	
	// fast sin function; maximum error is 0.001
	const float P = 0.225f;
	
	x = x * M_1_PI;
	int k = (int) roundf(x);
	x = x - k;
    
	float y = (4.0f - 4.0f * VFPFastAbs(x)) * x;
    
	y = P * (y * VFPFastAbs(y) - y) + y;
    
	return (k&1) ? -y : y;
}

static inline float TEIFastCos(float x) {
	
	return VFPFastSin(x + M_PI_2);
	
}

- (void)drawBetter {
	
    for (TEIParticle* particle in _particles) {
		
        // half width and height
        float w = particle.size * 42.0f;
		
		// Jiggle the sprites
        float radians = particle.rotation + (M_PI / 4.0f) * particle.rotationDirection;
        float topRightX = particle.location.x + (TEIFastCos(radians) * w);
        float topRightY = particle.location.y + (VFPFastSin(radians) * w);
		
        radians = particle.rotation + (M_PI * 3.0f / 4.0f) * particle.rotationDirection;
        float topLeftX = particle.location.x + (TEIFastCos(radians) * w);
        float topLeftY = particle.location.y + (VFPFastSin(radians) * w);
		
        radians = particle.rotation + (M_PI * 5.0f / 4.0f) * particle.rotationDirection;
        float bottomLeftX = particle.location.x + (TEIFastCos(radians) * w);
        float bottomLeftY = particle.location.y + (VFPFastSin(radians) * w);
		
        radians = particle.rotation + (M_PI * 7.0f / 4.0f) * particle.rotationDirection;
        float bottomRightX = particle.location.x + (TEIFastCos(radians) * w);
        float bottomRightY = particle.location.y + (VFPFastSin(radians) * w);
		
        // Texture atlas hackery.
        float minST[2];
        float maxST[2];
		
		float delta = ((float)TEXTURE_ATLAS_NXN_DIMENSION);
		delta = 1.0f/delta;
		
		
		int s_index = (int)particle.textureAtlasS;
		int t_index = (int)particle.textureAtlasT;
		
		minST[0] = [[ParticleSystemTextureCoordinates objectAtIndex:s_index] floatValue];
		minST[1] = [[ParticleSystemTextureCoordinates objectAtIndex:t_index] floatValue];
		
		maxST[0] = minST[0] + delta; 
		maxST[1] = minST[1] + delta;        
		
        unsigned char a = 255;       
		unsigned char rgb[3];
        unsigned argb = (a << 24) | (rgb[0] << 16) | (rgb[1] << 8) | (rgb[2] << 0);
        
        // Triangle #1
        ParticleSystemAddVertex(ParticleSystemParticleVertices,	topLeftX,		topLeftY,		minST[0], minST[1], argb, &ParticleSystemParticleVertexCount);
        ParticleSystemAddVertex(ParticleSystemParticleVertices,	topRightX,		topRightY,		maxST[0], minST[1], argb, &ParticleSystemParticleVertexCount);
        ParticleSystemAddVertex(ParticleSystemParticleVertices,	bottomLeftX,	bottomLeftY,	minST[0], maxST[1], argb, &ParticleSystemParticleVertexCount);
        
        // Triangle #2
        ParticleSystemAddVertex(ParticleSystemParticleVertices,	topRightX,		topRightY,		maxST[0], minST[1], argb, &ParticleSystemParticleVertexCount);
        ParticleSystemAddVertex(ParticleSystemParticleVertices,	bottomLeftX,	bottomLeftY,	minST[0], maxST[1], argb, &ParticleSystemParticleVertexCount);
        ParticleSystemAddVertex(ParticleSystemParticleVertices,	bottomRightX,	bottomRightY,	maxST[0], maxST[1], argb, &ParticleSystemParticleVertexCount);
        
//        ParticleSystemParticleVertexCount += 6;
        
        // Don't go over vert limit!
        if (ParticleSystemParticleVertexCount >= MAX_VERTS) {
			
            ParticleSystemParticleVertexCount = MAX_VERTS;
            break;
        }
        
    } // for (_particles)

//	NSLog(@"drawBetter: Particles(%d) Vertices(%d)", _particles.count, ParticleSystemParticleVertexCount);

}

+ (TEITexture *)particleTexture {
	return ParticleSystemParticleTexture;
}

+ (TEITexture *)backdropTexture {
	return ParticleSystemBackdropTexture;
}

+ (void)renderBackground {
	
	glBindTexture(GL_TEXTURE_2D, [[ParticleSystem backdropTexture] name]);
	
    glVertexPointer(  2, GL_SHORT,         sizeof(ParticleSystemOpenGLVertexData), &ParticleSystemBackdropRectangeVertices[0].xy  );
    glTexCoordPointer(2, GL_FLOAT,         sizeof(ParticleSystemOpenGLVertexData), &ParticleSystemBackdropRectangeVertices[0].st  );
    glColorPointer(   4, GL_UNSIGNED_BYTE, sizeof(ParticleSystemOpenGLVertexData), &ParticleSystemBackdropRectangeVertices[0].argb);
	
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
}

+ (void)renderParticles {
	
	glBindTexture(GL_TEXTURE_2D, [[ParticleSystem particleTexture] name]);
	
    glVertexPointer(  2, GL_SHORT,         sizeof(ParticleSystemOpenGLVertexData), &ParticleSystemParticleVertices[0].xy  );
    glTexCoordPointer(2, GL_FLOAT,         sizeof(ParticleSystemOpenGLVertexData), &ParticleSystemParticleVertices[0].st  );
    glColorPointer(   4, GL_UNSIGNED_BYTE, sizeof(ParticleSystemOpenGLVertexData), &ParticleSystemParticleVertices[0].argb);
	
    glDrawArrays(GL_TRIANGLES, 0, ParticleSystemParticleVertexCount);
	
    ParticleSystemParticleVertexCount = 0;
}

@end


