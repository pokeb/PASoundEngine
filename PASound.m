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

#import "PASound.h"
#import "PASoundSource.h"


#define kSoundReferenceDistance 20.0f

void* MyGetOpenALAudioData(CFURLRef inFileURL, ALsizei *outDataSize, ALenum *outDataFormat, ALsizei *outSampleRate)
{
	OSStatus						err = noErr;	
	UInt64							fileDataSize = 0;
	AudioStreamBasicDescription		theFileFormat;
	UInt32							thePropertySize = sizeof(theFileFormat);
	AudioFileID						afid = 0;
	void*							theData = NULL;
	
	// Open a file with ExtAudioFileOpen()
	err = AudioFileOpenURL(inFileURL, kAudioFileReadPermission, 0, &afid);
	if(err) {
		NSLog(@"MyGetOpenALAudioData: AudioFileOpenURL FAILED, Error = %ld", err);
		goto Exit;
	}
	
	// Get the audio data format
	err = AudioFileGetProperty(afid, kAudioFilePropertyDataFormat, &thePropertySize, &theFileFormat);
	if(err) {
		NSLog(@"PASoundEngine#MyGetOpenALAudioData: AudioFileGetProperty(kAudioFileProperty_DataFormat) FAILED, Error = %ld", err);
		goto Exit;
	}
	
	if (theFileFormat.mChannelsPerFrame > 2)  { 
		NSLog(@"PASoundEngine#MyGetOpenALAudioData - Unsupported Format, channel count is greater than stereo");
		goto Exit;
	}
	
	if ((theFileFormat.mFormatID != kAudioFormatLinearPCM) || (!TestAudioFormatNativeEndian(theFileFormat))) { 
		NSLog(@"PASoundEngine#MyGetOpenALAudioData - Unsupported Format, must be little-endian PCM");
		goto Exit;
	}
	
	if ((theFileFormat.mBitsPerChannel != 8) && (theFileFormat.mBitsPerChannel != 16)) { 
		NSLog(@"MyGetOpenALAudioData - Unsupported Format, must be 8 or 16 bit PCM\n");
		goto Exit;
	}
	
	
	thePropertySize = sizeof(fileDataSize);
	err = AudioFileGetProperty(afid, kAudioFilePropertyAudioDataByteCount, &thePropertySize, &fileDataSize);
	if(err) {
		NSLog(@"PASoundEngine#MyGetOpenALAudioData: AudioFileGetProperty(kAudioFilePropertyAudioDataByteCount) FAILED, Error = %ld", err);
		goto Exit;
	}
	
	// Read all the data into memory
	UInt32		dataSize = (UInt32) fileDataSize;
	theData = malloc(dataSize);
	if (theData)
	{
		AudioFileReadBytes(afid, false, 0, &dataSize, theData);
		if(err == noErr)
		{
			// success
			*outDataSize = (ALsizei)dataSize;
			*outDataFormat = (theFileFormat.mChannelsPerFrame > 1) ? AL_FORMAT_STEREO16 : AL_FORMAT_MONO16;
			*outSampleRate = (ALsizei)theFileFormat.mSampleRate;
		}
		else 
		{ 
			// failure
			free (theData);
			theData = NULL; // make sure to return NULL
			NSLog(@"PASoundEngine#MyGetOpenALAudioData: ExtAudioFileRead FAILED, Error = %ld", err);
			goto Exit;
		}	
	}
	
Exit:
	// Dispose the ExtAudioFileRef, it is no longer needed
	if (afid) AudioFileClose(afid);
	return theData;
}

@interface PASound ()
- (void)initBuffer;
@end

@implementation PASound

- (id)initWithFile:(NSString *)f {
    if ((self = [super init])) {
        [self setFile:f];
        [self initBuffer];
    }
    return self;
}

- (void)dealloc {
    ALenum error;
    alDeleteBuffers(1, &buffer);
	if((error = alGetError()) != AL_NO_ERROR) {
		printf("error deleting buffer: %x\n", error);
    }
    [super dealloc];
}


- (void)initBuffer
{
	ALenum  error = AL_NO_ERROR;
	ALenum  format = AL_FORMAT_STEREO16;
	ALvoid* data = NULL;
	ALsizei size = 0;
	ALsizei freq = 0;
	
	NSBundle*				bundle = [NSBundle mainBundle];
	
	// get some audio data from a wave file
	CFURLRef fileURL = (CFURLRef)[[NSURL fileURLWithPath:[bundle pathForResource:self.file ofType:@"wav"]] retain];
	
	if (fileURL) {
        
		data = MyGetOpenALAudioData(fileURL, &size, &format, &freq);
		
        CFRelease(fileURL);
        
        if((error = alGetError()) != AL_NO_ERROR) {
			NSLog(@"PASoundEngine: Error loading sound: %x", error);
			[NSException raise:@"PASoundEngine:ErrorLoadingSound" format:@"ErrorLoadingSound"];
			
		}
        
		alGenBuffers(1, &buffer);
		alBufferData(buffer, format, data, size, freq);
		free(data);
        
		if((error = alGetError()) != AL_NO_ERROR) {
			NSLog(@"PASoundEngine: Error attaching audio to buffer: %x", error);
		}
	}
	else {
		NSLog(@"Could not find file");
		[NSException raise:@"PASoundEngine:CouldNotFindfile" format:@"CouldNotFindFile"];
	}
}

- (ALuint)buffer
{
	return buffer;
}

@synthesize file;
@end
