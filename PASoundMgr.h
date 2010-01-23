/* cocos2d for iPhone
 *
 * http://www.cocos2d-iphone.org
 *
 * Copyright (C) 2009 by Florin Dumitrescu. Some changes by Ben Copsey.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the 'cocos2d for iPhone' license.
 *
 * You will find a copy of this license within the cocos2d for iPhone
 * distribution inside the "LICENSE" file.
 *
 */

#import <UIKit/UIKit.h>
#import "cocos2d.h"

@class PASoundListener, PASound, PASoundSource;

@interface PASoundMgr : NSObject {
    NSMutableDictionary *sounds;
    PASoundListener *listener;
    float soundsMasterGain;
	NSMutableArray *playingSounds;
	int maximumConcurrentSoundsForSoundGroup[4];
	int playingSoundsForSoundGroup[4];
}

@property (readwrite, retain, nonatomic) PASoundListener *listener;
@property (readwrite, assign, nonatomic) float soundsMasterGain;
@property (readwrite, retain, nonatomic) NSMutableArray *playingSounds;

+ (PASoundMgr *)sharedSoundManager;

- (void)setMaxSounds:(unsigned int)max forSoundGroup:(unsigned int)group;

- (PASound *)addSound:(NSString *)name;
- (PASound *)sound:(NSString *)name;
- (void)stopSound:(PASoundSource *)sound;
- (PASoundSource *)playSound:(NSString *)name inGroup:(unsigned int)group atPosition:(CGPoint)p looped:(BOOL)looped withGain:(float)g fadeIn:(BOOL)fadeIn;
- (PASoundSource *)playSound:(NSString *)name inGroup:(unsigned int)group;
- (void)fadeOutAllSounds;
- (void)stopAllSoundsWithGroup:(unsigned int)group;
- (void)performFading;
- (void)initOpenAL;
- (void)initListener;

@end
