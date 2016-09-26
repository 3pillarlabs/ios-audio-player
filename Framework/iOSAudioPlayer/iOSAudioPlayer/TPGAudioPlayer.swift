//
//  TPGAudioPlayer.swift
//  swiftAudioPlayer
//
//  Created by 3Pillar Global on 9/23/15.
//  Copyright © 2015 3PillarGlobal. All rights reserved.
//

import UIKit
import AVFoundation

/*
    TPGMediaLoadedStateNotification - triggered each time an media hunk was loaded in queue
*/

public let TPGMediaLoadedStateNotification = "com.3pillarglobal.medialoadedstate.notification"

/*
    TPGPlayerStalledNotification - indicates that the player has stalled
        -> object: NSNumber indicating the current player item
*/

public let TPGPlayerStalledNotification = "com.3pillarglobal.playerstalled.notification"

/*
    TPGPlayerDidReachEndNotification - player has reached end
*/

public let TPGPlayerDidReachEndNotification = "com.3pillarglobal.playerdidreachend.notification"

/*
    TPGPlayerTimeJumpedNotification - player has jumped to a different
        -> object: NSNumber indicating the current time the player has jumped to
*/

public let TPGPlayerTimeJumpedNotification = "com.3pillarglobal.playertimejumped.notification"

let kStartTimeZero                      = 0.0

public let kLoadedTimeRangesKeyPath    = "loadedTimeRanges"

/*
    SkipDirection type used in skipDirection: method
*/

public enum SkipDirection: Double {
    case Backward = -1, Forward = 1
}

public class TPGAudioPlayer: NSObject {
    static let internalInstance = TPGAudioPlayer()
    
    let player = AVPlayer()
    var playerDuration: Double?
    
    var currentPlayingItem: String?
    
    public var isPlaying: Bool {
        get {
            if player.rate == 0.0 {
                return false
            }
            return true
        }
        
        set {
            if newValue == true {
                player.play()
                
                if let _ = self.currentPlayingItem {
                    SpringboardData().updateLockScreenCurrentTime(currentTime: currentTimeInSeconds)
                }
            } else {
                player.pause()
            }
        }
    }
    
    /*************************************/
            // MARK: PUBLIC METHODS
    /*************************************/
     
    
    /*
        Method used to return the total duration of the player item
    */
    
    public var durationInSeconds: Double {
        get {
            return playerDuration ?? kCMTimeZero.seconds
        }
    }

    /*
        Method used to return the total duration of the player item
    */
    
    public class func sharedInstance() -> TPGAudioPlayer {
        return self.internalInstance
    }
    
    /*
        Returns the current time in seconds of the current player item
    */
        
    public var currentTimeInSeconds: Double {
        get {
            return player.currentTime().seconds
        }
    }
    
    public override init() {
        super.init()

     //   self.setupNotifications()
    }
    
    /*
        Method to be called whenever play or pause functionality is needed:
            -> audioUrl: the resource that need to be processed
            -> springboardInfo: dictionary that contains useful information to be displayed when device is in sleep mode
                + kTitleKey - holds value of title String object
                + kAuthorKey - key for holding the author information
                + kDurationKey - length of the certain player item
                + kListScreenTitleKey - secondary information to be displayed on springboard in sleep mode
                + kImagePathKey - key to be used for holding the path of image to be displayed
    
            -> startTime: offset from where the certain processing should start
            -> completion: completion block
    
        NOTE: springboardInfo is an optional parameter, it can be set to nil if the feature of playing in background while 
        the device is in sleep mode is desired to be ignored.
    */
    
    public func playPauseMediaFile(audioUrl: NSURL, springboardInfo: Dictionary <String, AnyObject>, startTime: Double, completion: @escaping (_ previousItem: String?, _ stopTime: Double) -> ()) {
        
        let stopTime = self.currentTimeInSeconds
        
        if audioUrl.absoluteString == self.currentPlayingItem {
            // Current episode playing
            self.isPlaying = !self.isPlaying
            completion(nil, stopTime)

            return
        }
            
        // Other episode to load
        // Load new episode
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            let options = [AVURLAssetReferenceRestrictionsKey : 0]
            let playerAsset = AVURLAsset(url: audioUrl as URL, options: options)
            self.playerDuration = playerAsset.duration.seconds
            
            DispatchQueue.main.async(execute: {
                //Episode Loaded
                self.prepareAndPlay(playerAsset: playerAsset, startTime: startTime, completion: { () -> Void in
                    //Ready to play
                    let previousPlayingItem = self.currentPlayingItem
                    self.currentPlayingItem = audioUrl.absoluteString
                    
                    completion(previousPlayingItem, stopTime)
                    
                    SpringboardData().setupLockScreenElementsWithDictionary( infoDictionary: springboardInfo as NSDictionary )
                })
            })
        }
    }
    
    /*
        Method used for skiping a certain time interval from an audio resourse
    */
    
    public func skipDirection(skipDirection: SkipDirection, timeInterval: Double, offset: Double) {
        let skipPercentage = timeInterval / self.durationInSeconds
        let newTime = CMTimeMakeWithSeconds(offset + ((skipDirection.rawValue * skipPercentage) * 2000.0), 100)
        
        player.seek(to: newTime) { (finished) -> Void in
            SpringboardData().updateLockScreenCurrentTime(currentTime: self.currentTimeInSeconds)
        }
    }
    
    /*
        Set the current player to a certain time from an input value
    */
    
    public func seekPlayerToTime(value: Double, completion: (() -> Void)!) {
        let newTime = CMTimeMakeWithSeconds(value, 100)
        
        player.seek(to: newTime, completionHandler: { (finished) -> Void in
            if completion != nil {
                DispatchQueue.main.async(execute: { () -> Void in
                    completion()
                })
            }
        })
    }
   
    /*
        Method used for showing the buffer bar (i.e. amount of the playable file that's been loaded)
    */
    
   override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == kLoadedTimeRangesKeyPath && object as? AVPlayerItem === self.player.currentItem {
            if let timeRanges = change?[NSKeyValueChangeKey.newKey] as? Array<AnyObject> {
                if timeRanges.count > 0 {
                    let timeRange = timeRanges[0].timeRangeValue
                    let loadedAmout = (timeRange?.start.seconds)! + (timeRange?.duration.seconds)!
                    let loadedPercentage = (loadedAmout * 100.0) / self.durationInSeconds
                    
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: TPGMediaLoadedStateNotification), object: NSNumber(value: loadedPercentage))
                }
            }
        }
    }
    
    /*************************************/
        // MARK: NOTIFICATION METHODS
    /*************************************/
    
    func playingStalled(notification: NSNotification) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: TPGPlayerStalledNotification), object: player.currentItem)
    }
    
    func playerDidReachEnd(notification: NSNotification) {
        self.player.seek(to: kCMTimeZero)
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: TPGPlayerDidReachEndNotification), object: nil)
    }
    
    func playerItemTimeJumpedNotification(notification: NSNotification) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: TPGPlayerTimeJumpedNotification), object: NSNumber(value: self.currentTimeInSeconds))
    }
    
    /*************************************/
            // MARK: PRIVATE METHODS
    /*************************************/
    
    func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: Selector(("playerDidReachEnd")), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(self, selector: Selector(("playingStalled")), name: NSNotification.Name.AVPlayerItemPlaybackStalled, object: player.currentItem)
        NotificationCenter.default.addObserver(self, selector: Selector(("playerItemTimeJumpedNotification")), name: NSNotification.Name.AVPlayerItemTimeJumped, object: nil)
    }
    
    func prepareAndPlay(playerAsset: AVURLAsset, startTime: Double, completion: @escaping (() -> Void)) {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            UIApplication.shared.beginReceivingRemoteControlEvents()
        } catch {
            // Code to be added in case of audio session setup error
            print(error)
        }
        
        self.player.pause()
        
        //remove kvo for current item
        let currentItem = self.player.currentItem
        currentItem?.removeObserver(self, forKeyPath: kLoadedTimeRangesKeyPath, context: nil)
        
        //load new asset
        let newPlayerItem = AVPlayerItem(asset: playerAsset)
        
        //replace current item with new player item
        self.player.replaceCurrentItem(with: newPlayerItem)
        
        if let _ = self.player.currentItem {
            self.player.currentItem!.addObserver(self, forKeyPath: kLoadedTimeRangesKeyPath, options: .new, context: nil)
        }
        
        //seek player to offset
        self.seekPlayerToTime(value: startTime, completion: { [unowned self] in
            self.player.play()
            
            completion()
            })
    }
}
