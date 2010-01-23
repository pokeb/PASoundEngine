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
 */

#import <UIKit/UIKit.h>
#import <OpenAL/al.h>
#import <OpenAL/alc.h>
#import <AudioToolbox/AudioToolbox.h>

#import "cocos2d.h"


@class PASound;

@interface PASoundSource : NSObject {
	PASound *sound;
    CGPoint position;
    float orientation;
    BOOL looped;
    float gain;
	float targetGain;
    ALuint source;
	unsigned int group;
	float fadeAmount;
	unsigned char fadeCount;
}

@property (readwrite, retain, nonatomic) PASound *sound;
@property (readwrite, assign, nonatomic) CGPoint position;
@property (readwrite, assign, nonatomic) float orientation;
@property (readwrite, assign, nonatomic) BOOL looped;
@property (readwrite, assign, nonatomic) float gain; 
@property (readwrite, assign, nonatomic) float targetGain; 
@property (readwrite, assign, nonatomic) unsigned int group;
@property (readwrite, assign, nonatomic) float fadeAmount;
@property (readwrite, assign, nonatomic) unsigned char fadeCount;

- (id)initWithSound:(PASound *)s position:(CGPoint)pos looped:(BOOL)yn;
- (id)initWithSound:(PASound *)s looped:(BOOL)yn;
- (void)initSource;

- (void)playAtPosition:(CGPoint)p restart:(BOOL)r;
- (void)playAtPosition:(CGPoint)p;
- (void)playAtPosition:(CGPoint)p withGain:(float)g;
- (void)playWithRestart:(BOOL)r;
- (void)play;
- (void)playAtListenerPositionWithRestart:(BOOL)r;
- (void)playAtListenerPosition;

- (void)stop;
- (BOOL)isPlaying;

- (void)setGain:(float)g;
- (void)setRolloff:(float)factor;
- (void)setPitch:(float)factor;
- (float)gain;

- (void)fadeOut;
@end
