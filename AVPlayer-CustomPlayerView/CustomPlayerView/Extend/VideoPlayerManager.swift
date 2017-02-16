//
//  AVPlayerManager.swift
//  SwiftToutiao
//
//  Created by haogaoming on 2016/11/18.
//  Copyright © 2016年 votee. All rights reserved.
//

import UIKit
import AVFoundation

protocol VideoPlayerManagerDelegate: NSObjectProtocol {
    
    /// 播放视频--播放完毕/自动播放下一集
    ///
    /// - Parameters:
    ///   - manger: 管理类
    ///   - playerFinshed: 是否播放完成，true：播放完成，false：播放下一集
    func videoPlayerManager(manger:NSObject,playerFinshed:Bool)
    
    /// 切换视频---切换视频响应UI操作
    ///
    /// - Parameters:
    ///   - manger: 管理类
    ///   - rewindHidden:  是否显示上一个按钮
    ///   - forwardHidden: 是否显示下一个按钮
    func videoPlayerManager(manger:NSObject,player: AVPlayer,rewindHidden:Bool,forwardHidden:Bool)
    
    /// 改变暂停和播放按钮的状态
    ///
    /// - Parameters:
    ///   - manger: 管理类
    ///   - playOrPauseButtonSelected: 暂停/播放按钮
    func videoPlayerManager(manger:NSObject,playOrPauseButtonSelected:Bool)
    
    /// 播放成功/失败 的事件
    ///
    /// - Parameters:
    ///   - manger: 管理类
    ///   - playerSuccess: 播放是否成功，true：成功   false：失败
    func videoPlayerManager(manger:NSObject,playerSuccess:Bool)
    
    /// 播放缓存的进度
    ///
    /// - Parameters:
    ///   - manger: 管理类
    ///   - loadeProgress: 缓存进度值
    func videoPlayerManager(manger:NSObject,loadeProgress:Float)
    
    /// 每秒钟改变时间和进度条的值
    ///
    /// - Parameters:
    ///   - manger: 管理类
    ///   - totalSeconds: 总时间
    ///   - currentSeconds: 当前播放的时间
    ///   - sliderValue: 进度条的值
    func videoPlayerManager(manger:NSObject,totalSeconds:String?,currentSeconds:String,sliderValue:Float)
}

class VideoPlayerManager: NSObject
{
    /// 播放视频AVPlayer
    var player: AVPlayer!
    /// 是否正在播放视频
    var isPlaying = false
    /// 当前播放视频的index
    var playerIndex = 0
    /// 当前播放视频的总时间
    var totalSeconds:Double = 0.0
    /// 监听视频每秒的动态
    var playbackObserver: Any?
    /// 视频链接URL数组
    var urlStringArray: [String?] = []
    /// 当应用进入前台的时候，是否自动播放视频
    var becomeActivieTrue:Bool = true
    /// 管理类代理
    weak var delegate: VideoPlayerManagerDelegate?
    
    /// 添加视频播放器
    ///
    /// - Parameter urlStringArr: 视频的URL地址
    /// - Returns: 返回AVPlaer
    func addPlayerManager(_ urlStringArr:[String?]) -> AVPlayer {
        urlStringArray = urlStringArr
        
//        let videoUrlString = urlStringArr[playerIndex]?.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
        let videoUrlString = urlStringArr[playerIndex]
        var palyerItem: AVPlayerItem?
        if let  url  = URL(string: videoUrlString!) {
            palyerItem = AVPlayerItem(url: url)
        }else {
            palyerItem = AVPlayerItem(url: URL(string:"http://artron.net")!)
        }
        
        player = AVPlayer(playerItem: palyerItem)
        player.play()
        
        //移除通知
        NotificationCenter.default.removeObserver(self)
        
        //添加通知
        NotificationCenter.default.addObserver(self, selector: #selector(playFinish), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: player.currentItem)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(stopvideoBecomeActiveNotifition(_:)), name: NSNotification.Name("stopvideoBecomeActive"), object: nil)
        
        //播放器添加进度监测
        addProgressObserver()
        
        //给playerItem添加监测
        addPlayerItemObserverToPlayerItem(plyerItem: player.currentItem!)
        
        return player
    }
    
    /// 给播放器添加进度监测
    func addProgressObserver() {
        if player == nil {
            return
        }
        //每一秒执行一次，在设定的时间间隔内定时更新播放进度，通过time参数通知客户端
        playbackObserver = player.addPeriodicTimeObserver(forInterval: CMTime(value: CMTimeValue(1.0), timescale: CMTimeScale(1.0)), queue: DispatchQueue.main, using: {[unowned self] (time) in
            DispatchQueue.main.async {
                [weak self] in
                self?.showVideoTimeLable()
            }
        })
    }
    
    /// 播放完成
    func playFinish() {
        if player == nil {
            return
        }
        isPlaying = false
        //判断是否有下一个视频，如果有，则自动播放下一个视频，如果没有，则关闭
        if playerIndex == urlStringArray.count-1 {
            //播放暂停
            player.pause()
            self.delegate?.videoPlayerManager(manger: self, playerFinshed: true)
            return
        }
        //继续播放下一个视频
        changeVidwoPlayer(forward:true)
    }
    
    /// 更改当前播放的视频/切换视频
    ///
    /// - Parameters:
    ///   - rewind: 播放上一个视频
    ///   - forward: 播放下一个视频
    func changeVidwoPlayer(rewind:Bool?=nil,forward:Bool?=nil) {
        if playerIndex > urlStringArray.count-1 || player == nil {
            return
        }
        closePlayer()
        removePlayerItemObserverToPlayerItem(plyerItem: player.currentItem!)
        if rewind != nil && rewind! {
            playerIndex -= 1
        }else if(forward != nil && forward!){
            playerIndex += 1
        }
        totalSeconds = 0   //总时间置0

        //切换视频
        let newAvplayer = addPlayerManager(urlStringArray)
        
        //添加下一个或上一个按钮
        var rewindHidden = false
        var forwardHidden = false
        
        if playerIndex == 0 {
            //不显示上一个按钮
            rewindHidden = true
        }
        if playerIndex == urlStringArray.count-1 {
            //不显示下一个按钮
            forwardHidden = true
        }
        self.delegate?.videoPlayerManager(manger: self, player: newAvplayer, rewindHidden: rewindHidden, forwardHidden: forwardHidden)
    }
    
    /// 进入后台/前台
    func applicationWillChangedActive(_ play:Bool?=nil) {
        if player == nil {
            return
        }
        if play == nil {
            if isPlaying {
                isPlaying = false
                player.pause()
            }else{
                isPlaying = true
                player.play()
            }
        }else if play == true {
            isPlaying = true
            player.play()
        }else if play == false {
            isPlaying = false
            player.pause()
        }
        
        self.delegate?.videoPlayerManager(manger: self, playOrPauseButtonSelected: !isPlaying)
    }
    
    /// 进入后台
    func applicationWillResignActive() {
        applicationWillChangedActive(false)
    }
    /// 进入前台
    func applicationDidBecomeActive() {
        if !becomeActivieTrue {
            //应用从前台进入的时候，不需要自动播放
            return
        }
        applicationWillChangedActive(true)
    }
    
    /// 每秒钟更改时间lable
    private func showVideoTimeLable() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.timeZone = TimeZone(secondsFromGMT: 8)
        //判断总时间，只计算一次
        var totalStr: String?
        if totalSeconds == 0 || totalSeconds.isNaN{
            let totalTime = player.currentItem?.duration
            totalSeconds = Double(CMTimeGetSeconds(totalTime!))
            totalStr = formatter.string(from: Date(timeIntervalSinceReferenceDate: TimeInterval(totalSeconds)))
        }
        //播放的当前时间
        let currentTime = player.currentItem?.currentTime()
        let currentSeconds = Double(CMTimeGetSeconds(currentTime!))
        let currentStr = formatter.string(from: Date(timeIntervalSinceReferenceDate: TimeInterval(currentSeconds)))
        
        //进度条的位置
        let value = Float(currentSeconds / totalSeconds)
        self.delegate?.videoPlayerManager(manger: self, totalSeconds: totalStr, currentSeconds: currentStr, sliderValue: value)
    }
    
    /// 快退/快进的滑动事件
    ///
    /// - Parameter sliderChangeTime: 快退快进时间
    func playerChangeBySliderChanged(sliderChangeTime:Float) {
        if player == nil {
            return
        }
        //取消上一次的查找
        player.currentItem?.cancelPendingSeeks()
        let newCMTime = CMTimeMake(Int64(Double(sliderChangeTime) * totalSeconds), 1)
        player.seek(to: newCMTime, completionHandler: {[weak self] (finished) in
            if finished {
                if self != nil && (self?.isPlaying)! {
                    //如果正在播放，则播放
                    self?.player.play()
                }
            }
        })
    }
    
    /// 给playerItem添加监测
    ///
    /// - Parameter plyerItem: 当前播放的视频
    func addPlayerItemObserverToPlayerItem(plyerItem:AVPlayerItem) {
        //用kvo监测plyerItem的播放状态，监控状态属性，注意AVPlayer也有一个status属性，通过监控它的status也可以获得播放状态
        plyerItem.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
        //监控网络加载情况属性
        plyerItem.addObserver(self, forKeyPath: "loadedTimeRanges", options: NSKeyValueObservingOptions.new, context: nil)
    }
    
    /// 移除playerItem的监测
    ///
    /// - Parameter plyerItem: 当前播放的视频
    func removePlayerItemObserverToPlayerItem(plyerItem:AVPlayerItem) {
        plyerItem.removeObserver(self, forKeyPath: "status")
        plyerItem.removeObserver(self, forKeyPath: "loadedTimeRanges")
    }
    
    //MAKE-----视频KVO监测处理
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?)
    {
        if keyPath == "status" {
            //获取改变状态
            let statusNum:NSNumber = (change?[NSKeyValueChangeKey.newKey] as? NSNumber)!
            let status = AVPlayerStatus(rawValue: statusNum.intValue)!
            
            switch status {
            case .unknown,.failed:
                print("加载失败")
                closePlayer()
                self.delegate?.videoPlayerManager(manger: self, playerSuccess: false)
               
            case .readyToPlay:
                print("停止加载")
                isPlaying = true
                showVideoTimeLable()
                self.delegate?.videoPlayerManager(manger: self, playerSuccess: true)
            }
        }else if keyPath == "loadedTimeRanges" {
            let playerItem = object as! AVPlayerItem
            let loadedTimeRanges = playerItem.loadedTimeRanges
            let first = loadedTimeRanges.first
            let timeRange = first?.timeRangeValue
            let startSeconds = CMTimeGetSeconds((timeRange?.start)!)
            let durationSecound = CMTimeGetSeconds((timeRange?.duration)!)
            //已经加载的时间
            let loadedTime = startSeconds + durationSecound
            //总时间
            let totalTime = CMTimeGetSeconds(playerItem.duration)
            //缓存比例
            let percent = loadedTime/totalTime
            
            //设置缓存进度条
            self.delegate?.videoPlayerManager(manger: self, loadeProgress: Float(percent))
        }
    }
    
    /// 取消player的操作
    func closePlayer()  {
        if player != nil {
            player.pause()
            player.currentItem?.cancelPendingSeeks()
            player.currentItem?.asset.cancelLoading()
            if playbackObserver != nil {
                player.removeTimeObserver(playbackObserver!)
                playbackObserver = nil
            }
        }
    }
    
    /// 视频底层页，播放完成之后，再重新播放
    func finshVideoPlaye() {
        if player != nil {
            player.seek(to: kCMTimeZero)
            player.pause()
        }
    }
    
    /// 应用进入前台，是否自动播放视频
    ///
    /// - Parameter notifition: 消息
    func stopvideoBecomeActiveNotifition(_ notifition:NSNotification) {
        let result = notifition.object as? Bool
        if  result != nil {
            becomeActivieTrue = result!
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        removePlayerItemObserverToPlayerItem(plyerItem: player.currentItem!)
    }
    
}
