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

#import "PASoundMgr.h"
#import "MyOpenALSupport.h"
#import "PASoundListener.h"
#import "PASoundSource.h"
#import "PASound.h"

@implementation PASoundMgr

@synthesize listener, soundsMasterGain, playingSounds;

static PASoundMgr *sharedSoundManager = nil;

+ (PASoundMgr *)sharedSoundManager {
	@synchronized(self)	{
		if (!sharedSoundManager){
			sharedSoundManager = [[PASoundMgr alloc] init];  
			[sharedSoundManager setPlayingSounds:[NSMutableArray array]];
        }
		return sharedSoundManager;
	}
	// to avoid compiler warning
	return nil;
}

+ (id)alloc {
	@synchronized(self)
	{
		NSAssert(sharedSoundManager == nil, @"Attempted to allocate a second instance of a singleton.");
		sharedSoundManager = [super alloc];
		return sharedSoundManager;
	}
	// to avoid compiler warning
	return nil;
}

- (id)init {
    if ((self = [super init])) {
        sounds = [[NSMutableDictionary alloc] initWithCapacity:3];
        soundsMasterGain = 1.0f;
        // setup our audio session
		OSStatus result = AudioSessionInitialize(NULL, NULL, NULL, self);
		if (result) printf("Error initializing audio session! %d\n", (int)result);
		else {
			UInt32 category = kAudioSessionCategory_AmbientSound;
			result = AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(category), &category);
			if (result) printf("Error setting audio session category! %d\n", (int)result);
			else {
				result = AudioSessionSetActive(true);
				if (result) printf("Error setting audio session active! %d\n", (int)result);
			}
		}
		
		// Initialize our OpenAL environment
		[self initOpenAL];
    }
	return self;
}

- (void)initOpenAL {
	ALCcontext		*newContext = NULL;
	ALCdevice		*newDevice = NULL;
	
	// Create a new OpenAL Device
	// Pass NULL to specify the system’s default output device
	newDevice = alcOpenDevice(NULL);
	if (newDevice != NULL) {
		// Create a new OpenAL Context
		// The new context will render to the OpenAL Device just created 
		newContext = alcCreateContext(newDevice, 0);
		if (newContext != NULL) {
			// Make the new context the Current OpenAL Context
			alcMakeContextCurrent(newContext);
        }
	}
	
	atexit(TeardownOpenAL);
	alGetError();
    [self initListener];
}

- (void)initListener {
    listener = [[PASoundListener alloc] init];
}

- (PASound *)addSound:(NSString *)name
{
    PASound *sound = [[PASound alloc] initWithFile:name];
    if (sound) {
        [sounds setObject:sound forKey:name];
        [sound release];
    }
    return sound;
}
- (PASound *)sound:(NSString *)name {
    return [sounds objectForKey:name];
}

- (PASoundSource *)playSound:(NSString *)name inGroup:(unsigned int)group atPosition:(CGPoint)p looped:(BOOL)looped withGain:(float)g fadeIn:(BOOL)fadeIn 
{
	// Clean up any sounds that have finished
	unsigned int i;
	unsigned int count = [playingSounds count];
	for (i=0; i<count; i++) {
		PASoundSource *source = [playingSounds objectAtIndex:i];
		if ([source targetGain] && ![source looped] && ![source isPlaying]) {
			unsigned int group = [source group];
			if (group) {
				playingSoundsForSoundGroup[group]--;
				[source setGroup:0];
			}
			//NSLog(@"Remove %@ sound %@ because it finished",source,[[source sound] file]);
			[playingSounds removeObjectAtIndex:i];
			i--;
			count--;
		}
	}
	
	// Check there is a spare slot available to play this sound
	if (group && maximumConcurrentSoundsForSoundGroup[group] <= playingSoundsForSoundGroup[group]) {
		//NSLog(@"Wont play %@,%hi",name,playingSoundsForSoundGroup[group]);
		return nil;
	}
    PASound *sound = [sounds objectForKey:name];
    if (sound) {
		
		// I manage the fading of sounds myself based on their position myself
		p = [listener position];
		PASoundSource *source = [[[PASoundSource alloc] initWithSound:sound position:p looped:looped] autorelease];
		//NSLog(@"Play %@ sound %@",source,[[source sound] file]);
		if (fadeIn) {
			[source setFadeCount:1];
			[source setFadeAmount:g/10.0f];
			[source setGain:0.0f];
		} else {
			[source setGain:g];
		}
		[source setTargetGain:g];
		[playingSounds addObject:source];
		if (group) {
			[source setGroup:group];
			playingSoundsForSoundGroup[group]++;
		}
        [source play];
        return source;
    }
    return nil;	
}

- (void)fadeOutAllSounds
{
	for (PASoundSource *sound in playingSounds) {
		[sound fadeOut];
	}
}

- (void)stopAllSoundsWithGroup:(unsigned int)group
{
	unsigned int i;
	unsigned int  count = [playingSounds count];
	for (i=0; i<count; i++) {
		PASoundSource *sound = [playingSounds objectAtIndex:i];
		if ([sound group] == group) {
			[self stopSound:sound];
			count--;
			i--;
		}
	}
}

- (PASoundSource *)playSound:(NSString *)name inGroup:(unsigned int)group
{
	return [self playSound:name inGroup:group atPosition:[listener position] looped:NO withGain:1.0f fadeIn:NO];
}

- (void)stopSound:(PASoundSource *)sound
{
	if ([sound group]) {
		playingSoundsForSoundGroup[[sound group]]--;
		[sound setGroup:0];
	}
	//NSLog(@"stop %@ sound %@",sound,[[sound sound] file]);
	[sound stop];
	[playingSounds removeObject:sound];


}


- (void)performFading
{
	unsigned int i;
	unsigned int  count = [playingSounds count];
	for (i=0; i<count; i++) {
		PASoundSource *source = [playingSounds objectAtIndex:i];
		float fadeCount = [source fadeCount];
		unsigned int group = [source group];
		if (fadeCount) {
			float gain = [source gain];
			float targetGain = [source targetGain];
			if (gain < targetGain) {
				[source setGain:gain+[source fadeAmount]];
			} else {
				[source setGain:gain-[source fadeAmount]];
			}
			fadeCount++;
			if (fadeCount == 10) {
				[source setGain:targetGain];
				[source setFadeCount:0];
				
				if (targetGain == 0.0f) {
					[source stop];
					if (group) {
						playingSoundsForSoundGroup[group]--;
						[source setGroup:0];
					}
					//NSLog(@"Remove %@ sound %@ after fade out",source,[[source sound] file]);
					[playingSounds removeObjectAtIndex:i];
					
					i--;
					count--;	
				}
			} else {
				[source setFadeCount:fadeCount];
			}
		}
	}
}

- (void)setMaxSounds:(unsigned int)max forSoundGroup:(unsigned int)group
{
	maximumConcurrentSoundsForSoundGroup[group] = max;
}


- (void)dealloc {
	[playingSounds release];
    [sounds release];
    [listener release];
	[super dealloc];
}

@end
