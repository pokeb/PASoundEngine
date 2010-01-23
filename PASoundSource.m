/* cocos2d for iPhone
 *
 * http://www.cocos2d-iphone.org
 *
 * Copyright (C) 2009 by Florin Dumitrescu.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the 'cocos2d for iPhone' license.
 *
 * You will find a copy of this license within the cocos2d for iPhone
 * distribution inside the "LICENSE" file.
 *
 *
 ***********************************************************************
 *
 * Part of the source code in this class has been provided by Apple.
 * For full distribution terms, see the top of MyOpenALSupport.h header file.
 *
 */

#import "PASoundSource.h"
#import "PASound.h"
#import "PASoundMgr.h"
#import "PASoundListener.h"

#define kSoundReferenceDistance 20.0f

@implementation PASoundSource

@synthesize sound, looped, gain, targetGain, group, fadeCount, fadeAmount;

- (id)init {
    return nil;
}

// initializers with position
- (id)initWithSound:(PASound *)s position:(CGPoint)pos looped:(BOOL)yn
{
    if ((self = [super init])) {
		[self setSound:s];
		[self setLooped:yn];
        [self initSource];
		[self setPosition:pos];
		[self setOrientation:0.0f];
		[self setGain:1.0f];
    }
    return self;
}
- (id)initWithSound:(PASound *)s looped:(BOOL)yn {
    return [self initWithSound:s position:CGPointZero looped:yn];
}

- (void)fadeOut
{
	[self setFadeAmount:gain/10];
	[self setFadeCount:1];
	[self setTargetGain:0.0f];
}


- (void)initSource
{
    ALenum error = AL_NO_ERROR;
	alGetError(); // Clear the error
    
    alGenSources(1, &source);
    
	// Turn Looping ON?
    if ([self looped]) {
        alSourcei(source, AL_LOOPING, AL_TRUE);        
    }
	
	// Set Source Reference Distance
	alSourcef(source, AL_REFERENCE_DISTANCE, kSoundReferenceDistance);
    
	// attach OpenAL Buffer to OpenAL Source
	alSourcei(source, AL_BUFFER, [[self sound] buffer]);
	
	if((error = alGetError()) != AL_NO_ERROR) {
		NSLog(@"PASoundEngine: Error attaching buffer to source: %x", error);
		[NSException raise:@"PASoundEngine:AttachingToBuffer" format:@"AttachingToBuffer"];

	}    
}

- (void)setGain:(float)g {
    gain = g;
    alSourcef(source, AL_GAIN, g * [[PASoundMgr sharedSoundManager] soundsMasterGain]);
}
- (void)setRolloff:(float)factor{
    alSourcef(source, AL_ROLLOFF_FACTOR, factor);
}
- (void)setPitch:(float)factor {
    alSourcef(source, AL_PITCH, factor);
}

- (BOOL)isPlaying
{
    ALint playingState;
    alGetSourcei(source, AL_SOURCE_STATE, &playingState);
    return (playingState == AL_PLAYING);
}

// play messages
- (void)playAtPosition:(CGPoint)p restart:(BOOL)r
{
    CGPoint currentPos = [self position];
    ALint playingState;
    if ((p.x != currentPos.x) || (p.y != currentPos.y)) {
        [self setPosition:p];
    }
    alGetSourcei(source, AL_SOURCE_STATE, &playingState);
    if ((playingState == AL_PLAYING) && r) {
        // stop it before replaying
        [self stop];
        // get current state
        alGetSourcei(source, AL_SOURCE_STATE, &playingState);
    }
    if (playingState != AL_PLAYING) {
        alGetError();
        ALenum error;
        [self setGain:gain];
        alSourcePlay(source);
        if((error = alGetError()) != AL_NO_ERROR) {
            NSLog(@"PASoundEngine: Error starting source: %x", error);
        }        
    }  
}
- (void)playAtPosition:(CGPoint)p {
    return [self playAtPosition:p restart:NO];
}
- (void)playAtPosition:(CGPoint)p withGain:(float)g
{
	[self setGain:g];
	[self playAtPosition:p];
}
- (void)playWithRestart:(BOOL)r {
    return [self playAtPosition:self.position restart:r];
}
- (void)play {
    return [self playAtPosition:self.position restart:NO];    
}
- (void)playAtListenerPositionWithRestart:(BOOL)r {
    return [self playAtPosition:[[[PASoundMgr sharedSoundManager] listener] position] restart:r];
}
- (void)playAtListenerPosition {
    return [self playAtListenerPositionWithRestart:NO];
}


- (CGPoint)position {
    return position;
}
- (void)setPosition:(CGPoint)pos
{
    position = pos;
    float sourcePosAL[] = {pos.x - 240.0f, 160.0f - pos.y, 0.0f};
	alSourcefv(source, AL_POSITION, sourcePosAL);
}

- (float)orientation {
    return orientation;
}
- (void)setOrientation:(float)o {
    orientation = o;
}

- (float)gain
{
	return gain;
}

- (void)stop
{
    alGetError();
    ALenum error;
	alSourceStop(source);
	if((error = alGetError()) != AL_NO_ERROR) {
		NSLog(@"PASoundEngine: Error stopping source: %x", error);
	}    
}


- (void)dealloc {
    [self stop];
    
    alGetError();
    alSourcei(source, AL_BUFFER, 0); // dissasociate buffer
    alDeleteSources(1, &source);
    
    [super dealloc];
}

@end
