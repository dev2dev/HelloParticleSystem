
#import <Foundation/Foundation.h>

#import "TEITexture.h"

@interface TEIParticle : NSObject {
	
	double birth;
    BOOL alive;
	
	CGPoint location;
	CGPoint	velocity;
	
    int textureAtlasS;
    int textureAtlasT;
		
    float alpha;
	
    float size;
	
    float rotation;
    float rotationDirection;
			
}

@property BOOL alive;
@property double birth;

@property CGPoint location;
@property CGPoint velocity;

@property int textureAtlasS;
@property int textureAtlasT;

@property float alpha;

@property float size;

@property float rotation;
@property float rotationDirection;

- (id)initAtLocation:(CGPoint)newLocation birthTime:(double)time willPush:(BOOL)push;

@end

@interface ParticleSystem : NSObject {

	NSMutableArray*	_openglPackedVertices;
	NSMutableArray*     _particles;
	
	int _particleTraunch;
	
    CGPoint _location;
	
    NSTimeInterval _birth;
	NSTimeInterval _mostRecentTime;
	
    BOOL _initialAnimationStep;
	
    double _lastTime;
    BOOL _decay;

	NSString* touchPhaseName;
}

@property CGPoint						location;
@property int							particleTraunch;
@property (nonatomic, retain) NSString	*touchPhaseName;

- (id)initAtLocation:(CGPoint)location;

- (BOOL)animateBetter:(NSTimeInterval)time;

- (void)drawBetter;

- (void)fill:(CGPoint)location;

- (void)setDecay:(BOOL)decay;

+ (void)buildTextureAtlasIndexTable;
+ (void)buildBackdropWithBounds:(CGRect)bounds;
+ (void)buildParticleTextureAtlas;

+ (TEITexture *)particleTexture;
+ (TEITexture *)backdropTexture;

+ (void)renderParticles;
+ (void)renderBackground;

@end
