# About PASoundEngine

This is my fork of the 'experimental' sound engine (for positional sound using Open AL) that comes with [cocos2d for iPhone](http://code.google.com/p/cocos2d-iphone/). [It was originally written by Florin Dumitrescu](http://code.google.com/p/cocos2d-iphone/source/browse/trunk/experimental/sound-engine/PASoundMgr.m). This is the sound engine used by my [Space Harvest](http://spaceharvest.com) game.

This code is licensed under the [cocos2d for iPhone license](http://www.cocos2d-iphone.org/wiki/doku.php/license).

The main change I've made is to split PASoundSource into two classes, PASoundSource, and PASound. A PASound instance handles the buffer for a particular sound, while a PASoundSource lets you create a source at a particular position and play it. Splitting the class in two means it is possible for two sound sources playing at once to share the same buffer.

I've also added miscellaneous stuff that was useful for Space Harvest, possibly it will be useful for you:

* Added a grouping system for sounds. When creating a sound source, you can optionally specify a group for it to play in. In Space Harvest, many sounds can play at once, but the device is only capable of playing a certain number of sounds (32?) concurrently. By specifying a group for a particular sound, PASoundMgr prevents certain types of sounds taking all the 'slots' for playing sounds. For example, in Space Harvest, only a maximum of 10 background driving sounds can be played concurrently, which means when many units are on the screen, firing sounds or destroy sounds still get a chance to play.

* Added basic fade in / fade out for sounds. Stopping long or looping sounds abruptly sounds terrible, so if you have a reference to the playing sound source, you can tell it to fade out [myPASoundSource fadeOut]. Once a sound source has finished fading out, it is stopped, freeing up a slot for other sound sources to play. Additionally, when starting a sound source, you can tell the sound manager to fade it in. The fading is controlled by the sound manager in performFading. Call this method in your main loop to allow the sound manager to fade sound sources in and out.

* I removed ogg support since I don't use it in Space Harvest, and it makes it easier to build as you don't need to use the Tremor library. It should be fairly easy to add it back in.

If other people are interested in my fork, I'd be happy to spend a bit more time cleaning it up, making the fading a bit more flexible, and potentially submitting a patch to cocos2d, but please let me know -> ben@allseeing-i.com