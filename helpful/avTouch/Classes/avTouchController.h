#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class CALevelMeter;

@interface avTouchController : NSObject <UIPickerViewDelegate, AVAudioPlayerDelegate> {

	IBOutlet UILabel					*_fileName;
	IBOutlet UIButton					*_playButton;
	IBOutlet UIButton					*_ffwButton;
	IBOutlet UIButton					*_rewButton;
	IBOutlet UISlider					*_volumeSlider;
	IBOutlet UISlider					*_progressBar;
	IBOutlet UILabel					*_currentTime;
	IBOutlet UILabel					*_duration;
	IBOutlet CALevelMeter				*_lvlMeter_in;
	
	AVAudioPlayer						*_player;
	UIImage								*_playBtnBG, *_pauseBtnBG;
	NSTimer								*_updateTimer;
	NSTimer								*_rewTimer;
	NSTimer								*_ffwTimer;
	NSMutableArray						*_soundFiles;
}

- (IBAction)playButtonPressed:(UIButton *)sender;
- (IBAction)rewButtonPressed:(UIButton *)sender;
- (IBAction)rewButtonReleased:(UIButton *)sender;
- (IBAction)ffwButtonPressed:(UIButton *)sender;
- (IBAction)ffwButtonReleased:(UIButton *)sender;
- (IBAction)volumeSliderMoved:(UISlider *)sender;
- (IBAction)progressSliderMoved:(UISlider *)sender;

@property (nonatomic, retain) UILabel*			_fileName;
@property (nonatomic, retain) UIButton*			_playButton;
@property (nonatomic, retain) UIButton*			_ffwButton;
@property (nonatomic, retain) UIButton*			_rewButton;
@property (nonatomic, retain) UISlider*			_volumeSlider;
@property (nonatomic, retain) UISlider*			_progressBar;
@property (nonatomic, retain) UILabel*			_currentTime;
@property (nonatomic, retain) UILabel*			_duration;
@property (nonatomic, retain) CALevelMeter*		_lvlMeter_in;

@property (nonatomic, retain)	NSTimer*		_updateTimer;
@property (nonatomic, assign)	AVAudioPlayer*	_player;
@end