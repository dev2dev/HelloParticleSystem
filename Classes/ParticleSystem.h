
#import <Foundation/Foundation.h>

#import "TEITexture.h"

@interface TEIParticle : NSObject {
	
	double birth;
    BOOL _alive;
	
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
	
    BOOL			_alive;

	NSMutableArray	*_particles;
	
	int				_particleTraunch;
	
    CGPoint			_location;
	
    NSTimeInterval	_birth;
    NSTimeInterval	_lastTime;
	
    BOOL			_decay;

	NSString		*touchPhaseName;
}

@property BOOL									alive;
@property (nonatomic, retain) NSMutableArray	*particles;
@property CGPoint								location;
@property int									particleTraunch;
@property (nonatomic, retain) NSString			*touchPhaseName;

- (id)initAtLocation:(CGPoint)location birthTime:(NSTimeInterval)birthTime;

- (BOOL)isAlive;
- (int)countLiveParticles;

- (void)addParticleAtBirthTime:(NSTimeInterval)birthTime;

- (BOOL)updateState:(NSTimeInterval)time;
- (void)prepareVerticesforRendering;

- (void)fill:(CGPoint)location;

- (void)setDecay:(BOOL)decay;

+ (int)totalLivingParticles;
+ (void)buildParticleTextureAtlas;
+ (void)buildTextureAtlasIndexTable;
+ (void)buildBackdropWithBounds:(CGRect)bounds;

+ (TEITexture *)particleTexture;
+ (TEITexture *)backdropTexture;

+ (void)renderBackground;
+ (void)renderParticles;
+ (void)setGravity:(CGPoint)gravityVector;

@end
