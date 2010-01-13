
#import <OpenGLES/ES1/gl.h>
#import "ParticleSystem.h"
#import "ConstantsAndMacros.h"

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

static CGPoint ParticleSystemGravity = { 0.0, 0.0 };

static float ParticleSystemBBoxBorder = 20.0;
static CGRect  ParticleSystemBBox;

typedef struct _ParticleSystemOpenGLVertexData { short xy[2]; unsigned argb; float st[2]; } ParticleSystemOpenGLVertexData;

static int ParticleSystemParticleCount = 0;

#define MAX_VERTS (20000)
static int ParticleSystemParticleVertexCount = 0;
static ParticleSystemOpenGLVertexData ParticleSystemParticleVertices[MAX_VERTS];

// Background rectangular card
static ParticleSystemOpenGLVertexData ParticleSystemBackdropRectangeVertices[4];
static GLubyte ParticleSystemBackdropRectangeVertexIndices[] = 
{
	0, 1, 2,
	2, 1, 3
};

static void ParticleSystemAddVertex(ParticleSystemOpenGLVertexData* vertices, float x, float y, float s, float t, unsigned argb, int *counter) {
	
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

// alias_wavefront_diagnostic
//#define TEXTURE_ATLAS_NXN_DIMENSION (8)

// kids_grid_3x3_translucent
#define TEXTURE_ATLAS_NXN_DIMENSION (3)
//#define TEXTURE_ATLAS_NXN_DIMENSION (2)

#define NUM_TEXTURES (TEXTURE_ATLAS_NXN_DIMENSION * TEXTURE_ATLAS_NXN_DIMENSION)

@implementation TEIParticle

@synthesize alive=_alive;
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
	
	return [self initAtLocation:CGPointMake(0.0, 0.0) birthTime:0.0 willPush:NO];
	
}

- (id)initAtLocation:(CGPoint)newLocation birthTime:(double)birthTime willPush:(BOOL)push {
	
	self = [super init];
	
	if(nil != self) {
		
		_alive = YES;
		
		// location
		location = newLocation;
		
		// rotation
		
		float radians = m3dDegToRad( (arc4random() % 360) );
		
		// scalefactor
		float scale = 30.0f + (arc4random() % 120);
		
		// velocity
		velocity.x = cosf(radians) * scale;
		velocity.y = sinf(radians) * scale;
		
		// Original ngmoco
//		if (push == YES) {
//			velocity.y -= 30.0f + (arc4random() % 30);
//		}
		
		// birth time
		self.birth = birthTime;
		
		// alpha
		alpha = 1.0f;
		
		// size
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
		
		++ParticleSystemParticleCount;
		
	}
	
	return self;
}

@end

@implementation ParticleSystem

static TEITexture		*ParticleSystemParticleTexture		= nil;
static TEITexture		*ParticleSystemBackdropTexture		= nil;
static NSMutableArray	*ParticleSystemTextureCoordinates	= nil;

@synthesize alive=_alive;
@synthesize particles=_particles;
@synthesize location=_location;
@synthesize particleTraunch=_particleTraunch;
@synthesize touchPhaseName;

- (void)dealloc {

	[_particles				removeAllObjects];
	[_particles				release];
    
	[touchPhaseName			release];
	
    [super dealloc];
}

- (id)init {

	return [self initAtLocation:CGPointMake(0.0, 0.0) birthTime:[NSDate timeIntervalSinceReferenceDate]];
	
}

- (id)initAtLocation:(CGPoint)location birthTime:(NSTimeInterval)birthTime {
	
	if (self = [super init]) {
		
		[self setValue:[NSNumber numberWithBool:YES] forKeyPath:@"alive"];
		
		_particles				=	[[NSMutableArray alloc] init];
		_particleTraunch		=	24;
		
		_location				= location;
		
		_birth					= birthTime;
		_lastTime				= birthTime;
		
		_decay					= NO;
		
		for (int i = 0; i < _particleTraunch; i++) {
			
			TEIParticle* particle = [[[TEIParticle alloc] initAtLocation:_location birthTime:birthTime willPush:YES] autorelease];
			
			[_particles addObject:particle];
			
		} // for (_particleTraunch)
		
	}
	
    return self;
}

- (BOOL)isAlive {
	
	if ([self countLiveParticles] == 0) {
		
		return NO;
		
	} // if ([self countLiveParticles] == 0)
	
	return YES;
}

- (int)countLiveParticles {
	
	int c = 0;
	for (TEIParticle *p in _particles) {
		
		if (p.alive == YES) {
		
			++c;
		}
		
	} // for (_particles)
	
	return c;
}

- (void)addParticleAtBirthTime:(NSTimeInterval)birthTime {
	
	TEIParticle* particle = [[[TEIParticle alloc] initAtLocation:_location birthTime:birthTime willPush:NO] autorelease];
	[_particles addObject:particle];
	
}

- (BOOL)updateState:(NSTimeInterval)time {
	
	// Take a time step in particle system state. Cull dead particles as needed.
	NSTimeInterval timeStep = (time - _lastTime);
	_lastTime = time;
	
	for (TEIParticle* particle in _particles) {
		
		if (particle.alive == NO) {
			
			continue;
		}
		
		static const float gravityScaleFactor = 120.0 * 2.0 * 2.0 * 2.0;
		
		// velocity
		float dv_x = (ParticleSystemGravity.x * gravityScaleFactor * timeStep);
		float dv_y = (ParticleSystemGravity.y * gravityScaleFactor * timeStep);
		particle.velocity = CGPointMake(particle.velocity.x + dv_x, particle.velocity.y + dv_y);
		
		
		// take a step in time to integrate velocity into distance
		float dx = particle.velocity.x * timeStep;
		float dy = particle.velocity.y * timeStep;
		
		// add delta step to location to compute new location
		particle.location = 
		CGPointMake(particle.location.x + dx, particle.location.y + dy);		
		
		if (particle.location.x < ParticleSystemBBox.origin.x || particle.location.x > ParticleSystemBBox.size.width) {
			
			particle.alive = NO;
			
			--ParticleSystemParticleCount;
			
			continue;
		}
		
		if (particle.location.y < ParticleSystemBBox.origin.y || particle.location.y > ParticleSystemBBox.size.height) {
			
			particle.alive = NO;
			
			--ParticleSystemParticleCount;
			
			continue;
		}
		
		static const float fadeTime = 3.0 * 2.0;
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
		float rotationRate = 5.0f/0.75f;
		particle.rotation += rotationRate * timeStep * particle.rotationDirection;
		
	} // for (_particles)
	
	
	for (TEIParticle *particle in _particles) {
		
		if (particle.alive == YES) {
			
			return YES;
			
		} // if (particle.alive = YES)
		
	} // for (TEIParticle *particle in _particles)
	
	[self setValue:[NSNumber numberWithBool:NO] forKeyPath:@"alive"];
	
	BOOL returnedValue = [self alive];
	
	return returnedValue;
	
}

- (void)prepareVerticesforRendering {
	
    for (TEIParticle* particle in _particles) {
		
		// No need to draw dead particles
		if (particle.alive == NO) {
		
			continue;
		}
		
		
        // half width and height
//        float w = particle.size * 42.0f ;
        float w = particle.size * 80.0f * (55.0/100.0);
		
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
        
		
        // Don't go over vert limit!
        if (ParticleSystemParticleVertexCount >= MAX_VERTS) {
			
            ParticleSystemParticleVertexCount = MAX_VERTS;
            break;
        }
        
    } // for (_particles)
	
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

- (void)setDecay:(BOOL)decay {
	
    if (decay == _decay) {
		
		return;
	}
	
    _decay = decay;
}

+ (int)totalLivingParticles {
	return ParticleSystemParticleCount;
}

+ (void)buildParticleTextureAtlas {
	
//	ParticleSystemParticleTexture = [ [TEITexture alloc] initWithImageFile:@"alias_wavefront_diagnostic"	extension:@"png" mipmap:YES ];	
//	ParticleSystemParticleTexture = [ [TEITexture alloc] initWithImageFile:@"candycane_scalar_disk_2x2"		extension:@"png" mipmap:YES ];
	ParticleSystemParticleTexture = [ [TEITexture alloc] initWithImageFile:@"kids_grid_3x3_translucent"		extension:@"png" mipmap:YES ];
//	ParticleSystemParticleTexture = [ [TEITexture alloc] initWithImageFile:@"kids_grid_3x3"					extension:@"png" mipmap:YES ];

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
	
	// When a particle goes offscreen kill it off
	ParticleSystemBBox = bounds;
	
	// allow an offscreen border for killing of particles
	ParticleSystemBBox.origin.x		-= ParticleSystemBBoxBorder;
	ParticleSystemBBox.origin.y		-= ParticleSystemBBoxBorder;
	
	ParticleSystemBBox.size.width	+= ParticleSystemBBoxBorder;
	ParticleSystemBBox.size.height	+= ParticleSystemBBoxBorder;

	
	
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
//	[ [TEITexture alloc] initWithImageFile:@"swirl-rose"	extension:@"png" mipmap:YES ];
//	[ [TEITexture alloc] initWithImageFile:@"case-identity"	extension:@"png" mipmap:YES ];
	[ [TEITexture alloc] initWithImageFile:@"playful"		extension:@"png" mipmap:YES ];
//	[ [TEITexture alloc] initWithImageFile:@"mash"	extension:@"png" mipmap:YES ];
	
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
	

	glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, ParticleSystemBackdropRectangeVertexIndices); 
	
//	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
}

+ (void)renderParticles {

	static int maxParticleVerticesRendered = 0;

	if (maxParticleVerticesRendered < ParticleSystemParticleVertexCount) {
		maxParticleVerticesRendered = ParticleSystemParticleVertexCount;
	}
	
//	NSLog(@"renderParticles: MaxVertices(%d) CurrentVertices(%d)", maxParticleVerticesRendered, ParticleSystemParticleVertexCount);

	glBindTexture(GL_TEXTURE_2D, [[ParticleSystem particleTexture] name]);
	
    glVertexPointer(  2, GL_SHORT,         sizeof(ParticleSystemOpenGLVertexData), &ParticleSystemParticleVertices[0].xy  );
    glTexCoordPointer(2, GL_FLOAT,         sizeof(ParticleSystemOpenGLVertexData), &ParticleSystemParticleVertices[0].st  );
    glColorPointer(   4, GL_UNSIGNED_BYTE, sizeof(ParticleSystemOpenGLVertexData), &ParticleSystemParticleVertices[0].argb);
	
    glDrawArrays(GL_TRIANGLES, 0, ParticleSystemParticleVertexCount);
	
    ParticleSystemParticleVertexCount = 0;
}

+ (void)setGravity:(CGPoint)gravityVector {
	
	ParticleSystemGravity.x = gravityVector.x;
	ParticleSystemGravity.y = gravityVector.y;
	
	// Flip the y-component of the gravity vector to be consistent with the screen space coordinate
	// system used in ParticleSystem. Gravity is world space. ParticleSystem is screen space.
	ParticleSystemGravity.y = -(ParticleSystemGravity.y);
	
}

@end


