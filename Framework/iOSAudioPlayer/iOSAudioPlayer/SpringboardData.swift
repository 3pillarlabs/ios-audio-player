//
//  SpringboardData.swift
//  TPGPodcastsPlayer
//
//  Created by 3Pillar Global on 27/11/15.
//  Copyright © 2015 3Pillar Global. All rights reserved.
//

import Foundation
import MediaPlayer

let kTitleKey                   = "TitleKey"
let kAuthorKey                  = "AuthorKey"
let kDurationKey                = "DurationKey"
let kListScreenTitleKey         = "ListScreenTitle"
let kImagePathKey               = "ImagePath"

public class SpringboardData {
    
    /*
        Method used for setting up the lock screen when player is playing in background
    */
    
    public func setupLockScreenElementsWithDictionary(infoDictionary: NSDictionary) {
        func unwrapString(string: String?) -> String {
            if let unwrappedString: String = string {
                return unwrappedString
            }
            
            return ""
        }
        
        let nowPlayingInfo = [
            MPMediaItemPropertyTitle: unwrapString( infoDictionary[kTitleKey] as? String),
            MPMediaItemPropertyArtist: unwrapString( infoDictionary[kAuthorKey] as? String),
            MPMediaItemPropertyPlaybackDuration: infoDictionary[kDurationKey] as! NSNumber,
            MPMediaItemPropertyPodcastTitle: unwrapString( infoDictionary[kListScreenTitleKey] as? String)
        ]
        
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = nowPlayingInfo
        
        self.updateLockScreenImage( unwrapString( infoDictionary[kImagePathKey] as? String) )
    }
    
    /*
        Method that returns a dictionary to be used for settings the screen infomation when the player plays in background and device goes to sleep
    */
    
    public class func springboardDictionary( title: String, artist: String, duration: Int, listScreenTitle: String, imagePath: String) -> Dictionary <String, AnyObject> {
        return Dictionary <String,  AnyObject> (dictionaryLiteral: (kTitleKey, title), (kAuthorKey, artist), (kDurationKey, NSNumber(integer: duration)), (kImagePathKey, imagePath))
    }
    
    public func updateLockScreenCurrentTime(currentTime: Double) {
        if var nowPlayingInfo = MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo {
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(double: currentTime)
            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = nowPlayingInfo
        }
    }
    
    private func updateLockScreenImage(imagePath: String) {
        if var nowPlayingInfo = MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
                let image = UIImage(contentsOfFile: imagePath)
                nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: image!)
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = nowPlayingInfo
                })
            }
        }
    }
}