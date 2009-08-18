
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
	
	id				_target;
	SEL				_startSelector;
	SEL				_stopSelector;
	
    BOOL			_alive;

	NSMutableArray	*_particles;
	
	int				_particleTraunch;
	
    CGPoint			_location;
	
    NSTimeInterval	_birth;
	NSTimeInterval	_mostRecentTime;
	
    BOOL			_isInitialAnimationStep;
	NSTimeInterval	_step;
	
    double			_lastTime;
	
    BOOL			_decay;

	NSString		*touchPhaseName;
}

@property BOOL									alive;
@property (nonatomic, retain) NSMutableArray	*particles;
@property CGPoint								location;
@property int									particleTraunch;
@property (nonatomic, retain) NSString			*touchPhaseName;

- (id)initAtLocation:(CGPoint)location;
- (id)initAtLocation:(CGPoint)location target:(id)aTarget startSelector:(SEL)aStartSelector stopSelector:(SEL)aStopSelector;

- (BOOL)isAlive;
- (int)countLiveParticles;

- (BOOL)timeStep:(NSTimeInterval)time;

- (BOOL)animate:(NSTimeInterval)time;
- (void)draw;

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
