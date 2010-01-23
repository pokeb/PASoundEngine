/* cocos2d for iPhone
 *
 * http://www.cocos2d-iphone.org
 *
 * This class by Ben Copsey, based on work Copyright (C) 2009 by Florin Dumitrescu
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the 'cocos2d for iPhone' license.
 *
 * You will find a copy of this license within the cocos2d for iPhone
 * distribution inside the "LICENSE" file.
 *
 */


#import <OpenAL/al.h>
#import <OpenAL/alc.h>

@interface PASound : NSObject {
	ALuint buffer;
    NSString *file;

}

- (id)initWithFile:(NSString *)f;
- (ALuint)buffer;

@property (readwrite, copy, nonatomic) NSString *file;
@end
