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
            MPMediaItemPropertyTitle: unwrapString( string: infoDictionary[kTitleKey] as? String),
            MPMediaItemPropertyArtist: unwrapString( string: infoDictionary[kAuthorKey] as? String),
            MPMediaItemPropertyPlaybackDuration: infoDictionary[kDurationKey] as! NSNumber,
            MPMediaItemPropertyPodcastTitle: unwrapString( string: infoDictionary[kListScreenTitleKey] as? String)
        ] as [String : Any]
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        
        self.updateLockScreenImage( imagePath: unwrapString( string: infoDictionary[kImagePathKey] as? String) )
    }
    
    /*
        Method that returns a dictionary to be used for settings the screen infomation when the player plays in background and device goes to sleep
    */
    
    public class func springboardDictionary( title: String, artist: String, duration: Int, listScreenTitle: String, imagePath: String) -> Dictionary <String, AnyObject> {
            var dictionary = Dictionary <String,  AnyObject>()
        
            dictionary[kTitleKey] = title as AnyObject?
            dictionary[kAuthorKey] = artist as AnyObject?
            dictionary[kDurationKey] = NSNumber(value: duration)
            dictionary[kImagePathKey] = imagePath as AnyObject?

        return dictionary
    }
    
    public func updateLockScreenCurrentTime(currentTime: Double) {
        if var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo {
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: currentTime)
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }
    
    private func updateLockScreenImage(imagePath: String) {
        if var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo {
            DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
                let image = UIImage(contentsOfFile: imagePath)
                nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: image!)
                
                DispatchQueue.main.async(execute: {
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                })
            }
        }
    }
}
