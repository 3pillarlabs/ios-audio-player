# iOS Audio Player

iOSAudioPlayer is a Swift based iOS module that provides player control features. This module represents a wrapper over AVPlayer. It is available starting with iOS 8.

![](screenshots/AudioPlayerDemo.gif)

**Project Rationale**

The purpose of the framework is to provide a simple in app solution for player controls, by offering the following features:

*	Play & pause functionality
*	Player items management
*	Notifications triggered for main player states
*	Notifications triggered for each media item package load
*	Skip a certain time interval methods
* 	Seek to a certain offset method
*	Play in background and control from springboard when in sleep state

#Installation

iOSAudioPlayer framework works with iOS 8.0 or later. Make sure that the framework is added to 'Embedded Binaries' list. After this, you just import the framework in the file where you will use it.

#Usage
1. Import iOSAudioPlayer Framework
2. Use shared instance of TPGAudioPlayer class, by calling TPGAudioPlayer.sharedInstance().
4. Play a certain media file by calling method:
*		public func playPauseMediaFile(audioUrl: NSURL, springboardInfo: [String : AnyObject], startTime: Double, completion: (previousItem: String?, stopTime: Double) -> ()) 

5. Skip a certain time interval using method:
*		public func skipDirection(skipDirection: iOSAudioPlayer.SkipDirection, timeInterval: Double, offset: Double)

6. Seek the player to a certain offset:
*		public func seekPlayerToTime(value: Double, completion: (() -> Void)!)

7. Check the duration of the current player item:
*		public var durationInSeconds: Double { get }

8. Check current progress of the player on the current player item:
*    	public var currentTimeInSeconds: Double { get }

9. Listen to the notification which is triggered when a certain media file package is loaded:
* 		public let TPGMediaLoadedStateNotification: String

In the demo project you're able to see how the framework is used.        

## License

iOSAudioPlayer is released under MIT license. See [LICENSE](LICENSE) for details.  

## About this project

![3Pillar Global] (http://www.3pillarglobal.com/wp-content/themes/base/library/images/logo_3pg.png)

**iOSAudioPlayer** is developed and maintained by [3Pillar Global](http://www.3pillarglobal.com/).


