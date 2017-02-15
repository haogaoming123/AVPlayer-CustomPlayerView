//
//  CustomVideoView.swift
//  SwiftToutiao
//
//  Created by haogaoming on 2016/11/8.
//  Copyright © 2016年 votee. All rights reserved.
//

import UIKit

enum customVideoViewType {
    case oldVideoType;      //一期的视频UI格式
    case newVideoType;      //二期公开课视频的UI格式
}
let VIDEOHEIGHT :CGFloat = 220 //视频高度
let PLAYER_SCREEN_WIDTH = UIScreen.main.bounds.width
/// 横屏的block
typealias screenHorizontalBlock = (_ horizontal:Bool) -> Void
/// 视频播放完成的block
typealias videoPlayerFinshBlock = (_ playerFinsh:Bool) -> Void

class CustomVideoView: UIView,VideoFailedReloadViewDelegate,VideoLayerViewDelegate,VideoPlayerManagerDelegate,videoStopLingViewDelegate
{
    /// 播放视频的layer层
    var playerLayer: AVPlayerLayer?
    /// 初始化本类view时候得frame
    var superViewFrame = CGRect.zero
    /// 视频的样式
    var videoType:customVideoViewType = .oldVideoType
    /// 记录视频是否播放成功
    var playSuccsee = false
    /// 横屏的block
    var block: screenHorizontalBlock?
    /// 视频播放完成的block
    var playerFinsh: videoPlayerFinshBlock?
    /// 是否播放的MP3类型
    var isMp3Type:Bool = false
    /// 视频播放数组
    var UrlStringArr:[String?] = []
    
    /// 所有按钮的UI，包括滚动条等
    lazy var videoLayerView: VideoLayerView = {
        let videoView = VideoLayerView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height), isMp3: self.isMp3Type)
        videoView.backgroundColor = UIColor.clear
        videoView.delegate = self
        return videoView
    }()
    
    /// 视频播放前的loading图
    lazy var playerLoadingView: VideoLoadingView = {
        var frame = CGRect(x: (self.frame.width-40)/2.0, y: (self.frame.height-30)/2.0, width: 40, height: 30)
        let imageView = VideoLoadingView(frame: frame)
        self.addSubview(imageView)
        return imageView
    }()
    
    /// 加载失败时候得view
    lazy var loadingFailView: VideoFailedReloadView = {
        let faileView = VideoFailedReloadView(frame: CGRect(x: 0, y: self.frame.height/2.0-25, width: self.frame.width, height: 50))
        faileView.delegate = self
        return faileView
    }()
    
    /// 在非WiFi情况下得view
    lazy var videoStopLingView: VideoStopLingView = {
        let stopLingView = VideoStopLingView(frame: CGRect(x: self.frame.width/2.0-22, y: self.frame.height/2.0-22, width: 44, height: 44))
        stopLingView.delegate = self
        return stopLingView
    }()
    
    /// 视频管理类
    lazy var playerManager: VideoPlayerManager = {
        let manager = VideoPlayerManager()
        manager.delegate = self
        return manager
    }()
    
    /// 初始化页面
    ///
    /// - Parameters:
    ///   - urlStringArr: URL链接数组
    ///   - type: 页面类型：加在keywindow上/加在SuperView上
    ///   - superView: superView
    ///   - loadingImageUrl: 视频的默认图片
    init(urlStringArr:[String?],
                 type:customVideoViewType = .oldVideoType,
            superView:UIView,
      loadingImageUrl:String?=nil,
      horizontalBlock:screenHorizontalBlock?=nil,
     playerFinshBlock:videoPlayerFinshBlock?=nil,
              mp3Type:Bool?=nil)
    {
        var frame = CGRect(x: 0, y: 0, width: PLAYER_SCREEN_WIDTH, height: VIDEOHEIGHT)
        //音频
        if mp3Type != nil && mp3Type! == true {
            frame.size.height = 100
            isMp3Type = true
        }
        super.init(frame: frame)
        videoType = type
        superView.addSubview(self)

        
        block = horizontalBlock
        playerFinsh = playerFinshBlock
        superViewFrame = frame
        backgroundColor = UIColor.black
        UIApplication.shared.setStatusBarHidden(true, with: .none)
        
        /// UI操作
        self.addSubview(videoLayerView)
        if type == .newVideoType {
            //如果是视频底层页，去掉关闭按钮
            videoLayerView.closeButton.isHidden = true
        }
        if loadingImageUrl != nil {
            //设置不隐藏 视频默认图
            videoLayerView.videoDefalueImageHiddden(hidden: false, imageurl: loadingImageUrl)
        }
    
        //旋转loading
        addLoadingImageview()
        
        UrlStringArr = urlStringArr
        if NetCheck.netCheckInstance().check3G() {
            //是非wifi情况下
            _ = LXActionAlert(title: "温馨提示", message: "您正在非WiFi环境下，可能会产生流量费用", cacnleTitle: "取消", otherTitles: ["继续"], cancleBtnBlock: {[unowned self] in
                if self.videoType == .oldVideoType {
                    self.dismissAlperView()
                    return
                }
                //添加停止加载view
                self.playerLoadingView.isHidden = true
                self.addSubview(self.videoStopLingView) //添加重新加载页面
                }, otherBtnBlock: {[weak self] (index) in
                    self?.addAVplayerManger()
            })
        }else{
            //加载avplayer
            addAVplayerManger()
        }
        
        if isMp3Type == false {
            //视频格式的时候，添加旋转通知
            NotificationCenter.default.addObserver(self, selector: #selector(orientChange), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        }
   
        //添加下一个视频按钮
        if urlStringArr.count > 1 {
            addViodeoRewind(rewind: true, forward: false)
        }
        
        //添加tap点击事件，用于显示播放按钮等操作
        _ = addGestureRecognizer(style: .tap, target: self, selector: #selector(hiddenSliderTapClick))
    }
    
    /// 添加播放器avplayer
    func addAVplayerManger() {
        //添加播放AVPlayer
        let player = playerManager.addPlayerManager(UrlStringArr)
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = self.layer.bounds
        playerLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.layer.insertSublayer(playerLayer!, at: 0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MAKE--AVPlayerManger-代理
    func videoPlayerManager(manger: NSObject, playerFinshed: Bool) {
        if videoType == .oldVideoType {
            dismissAlperView()
        }else{
            //如果是视频底层页，播放完成之后，重新播放
            playerManager.finshVideoPlaye()
            //改变播放按钮状态
            videoLayerView.setVideoLayerView(playOrPauseBtnSelected: true)
            //显示一下黑色遮罩
            hiddenSliderTapClick()
            
            //设置竖屏
            setScreenOrientation(leftOrientation: false)
            //自动 播放下一集
            if playerFinsh != nil {
                playerFinsh!(true)
            }
        }
    }
    
    func videoPlayerManager(manger: NSObject, playerSuccess: Bool) {
        playSuccsee = playerSuccess
        if playerSuccess == false {
            //播放失败,点击重新加载
            playerLoadingView.isHidden = true
            loadingFailView.removeFromSuperview()
            self.addSubview(loadingFailView) //添加重新加载页面
        }else {
            if isMp3Type == false {
                //隐藏视频默认图片
                videoLayerView.videoDefalueImageHiddden(hidden: true)
            }else {
                //音频格式
            }
            //隐藏loading图
            playerLoadingView.isHidden = true
        }
        //设置播放和暂停按钮的状态
        videoPlayerManager(manger: manger, playOrPauseButtonSelected: !playerSuccess)
        //设置隐藏按钮
        hiddenSliderTapClick()
    }
    
    func videoPlayerManager(manger: NSObject, loadeProgress: Float) {
        videoLayerView.setVideoLayerView(progressValue: loadeProgress)
    }
    
    /// 切换视频---切换视频响应UI操作
    ///
    /// - Parameters:
    ///   - manger: 管理类
    ///   - rewindHidden:  是否显示上一个按钮
    ///   - forwardHidden: 是否显示下一个按钮
    func videoPlayerManager(manger:NSObject,player: AVPlayer,rewindHidden:Bool,forwardHidden:Bool) {
        
        if playerLayer == nil {
            return
        }
        
        addViodeoRewind(rewind: rewindHidden, forward: forwardHidden)
        //旋转loading
        addLoadingImageview()
        
        //更换视频layer
        playerLayer?.player = player
    }
    
    func videoPlayerManager(manger: NSObject, playOrPauseButtonSelected: Bool) {
        if isMp3Type {
            //是音频格式
            videoLayerView.setVideoLayerView(screenBtnHidden: playOrPauseButtonSelected)
            return
        }
        videoLayerView.setVideoLayerView(playOrPauseBtnSelected: playOrPauseButtonSelected)
    }
    
    func videoPlayerManager(manger: NSObject, totalSeconds: String?, currentSeconds: String, sliderValue: Float) {
        videoLayerView.setVideoLayerView(totalTime: totalSeconds, currentTime: currentSeconds, sliderVaule: sliderValue)
    }
    //END--
    
    /// 添加上一个视频和下一个视频
    ///
    /// - Parameters:
    ///   - rewind: 显示上一个播放按钮
    ///   - forward: 显示下一个播放按钮
    func addViodeoRewind(rewind:Bool,forward:Bool) {
        videoLayerView.setVideoLayerView(rewindBtnHidden: rewind, forwardBtnHidden: forward)
    }
    
    /// 加载失败，重新加载
    ///
    /// - Parameters:
    ///   - view: 失败view
    ///   - reloadBtn: 重新加载button
    func failReloadView(view: UIView, reloadBtn: UIButton) {
        if playerLayer == nil {
            return
        }
        view.removeFromSuperview()
        //changeVidwoPlayer(index: playerIndex)
        //重新播放视频
        playerManager.changeVidwoPlayer()
    }
    
    /// 在非WiFi的情况下，加载视频
    ///
    /// - Parameters:
    ///   - view: view
    ///   - btn: 加载button
    func videoStopLingView(view:UIView, LoadingVideoNoWifi btn:UIButton)
    {
        view.removeFromSuperview()
        //加载player
        addAVplayerManger()
    }
    
    /// 每次切换视频的时候，加载loading图
    private func addLoadingImageview() {
        //旋转loading
        if isMp3Type == false {
            //不是音频格式的时候，隐藏button
            videoLayerView.buttonHidden(true) //隐藏button
        }
        playerLoadingView.isHidden = false
    }
    
    /// 隐藏按钮的操作
    ///
    /// - Parameter playerFinshed: 是否播放完成，如果播放完成，则不需要自动消失
    func hiddenSliderTapClick() {
        if isMp3Type {
            //是音频格式，不隐藏
            return
        }
        //每次点击都显示一下，然后过5秒自动消除
        if !videoLayerView.screenButton.isHidden {
            //防止重复点击
            return
        }
        videoLayerView.buttonHidden(false)
        
        if playSuccsee == false {
            //视频没有播放成功，关闭点击不出来
            if videoType == .oldVideoType {
                videoLayerView.setVideoLayerView(closeButtonHidden: false,playOrPauseBtnHidden: true)
            }else {
                videoLayerView.setVideoLayerView(closeButtonHidden: true,playOrPauseBtnHidden: true)
            }
        }else {
            //如果是公开课，关闭点击不出来
            if videoType == .newVideoType {
                //如果是视频底层页，去掉关闭按钮
                videoLayerView.closeButton.isHidden = true
            }
        }
        
        weak var weak: VideoLayerView? = self.videoLayerView
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5) {
            weak?.buttonHidden(true)
        }
    }
    
    //  MAKE--------------------点击事件---------------
    /// 点击按钮的点击事件
    ///
    /// - Parameters:
    ///   - view: 本类
    ///   - buttonTag: 按钮的tag，从0开始
    func videoLayerView(view: UIView, button: UIButton, buttonTag: Int) {
        
        switch buttonTag {
        case 0:
            /// 暂停or开始按钮
            playerManager.applicationWillChangedActive()
            break
        case 1:
            /// 播放上一个按钮
           playerManager.changeVidwoPlayer(rewind: true)
            break
        case 2:
            /// 播放下一个按钮
            playerManager.changeVidwoPlayer(forward: true)
            break
        case 3:
            /// 全屏按钮
            button.isSelected = !button.isSelected
            
            //如果是音频格式，则暂停和开始
            if isMp3Type {
                playerManager.applicationWillChangedActive()
                return
            }
            
            if button.isSelected {
                self.frame = CGRect(x: 0, y: 0, width: SCREEN_HEIGHT, height: SCREEN_WIDTH)
                if playerLoadingView.superview != nil {
                    //添加了loading页面，才改变frame
                    playerLoadingView.frame = CGRect(x: (SCREEN_HEIGHT-40)/2.0, y: (SCREEN_WIDTH-30)/2.0, width: 40, height: 30)
                }
                if loadingFailView.superview != nil {
                    //添加了失败页面，才改变frame
                    loadingFailView.frame = CGRect(x: 0, y: self.height/2.0-25, width: SCREEN_HEIGHT, height: 50)
                }
                if videoStopLingView.superview != nil {
                    //添加停止加载的页面，才改变frame
                    videoStopLingView.frame = CGRect(x: self.width/2.0-22, y: self.height/2.0-22, width: 44, height: 44)
                }
                videoLayerView.frame = CGRect(x: 0, y: 0, width: SCREEN_HEIGHT, height: SCREEN_WIDTH)
                if playerLayer != nil {
                    playerLayer?.frame = self.frame
                }
                
                //如果正在显示全屏按钮等，则显示返回按钮
                if videoLayerView.screenButton.isHidden == false {
                    videoLayerView.setVideoLayerView(backButtonHidden: false)
                }
            }else{
                //返回竖屏显示的时候，隐藏返回按钮
                videoLayerView.setVideoLayerView(backButtonHidden: true)
            }
            
            //视频的偏移量
            let contentofSet = SCREEN_HEIGHT/2.0-SCREEN_WIDTH/2.0
            UIView.animate(withDuration: 0.25, animations: {[unowned self] in
                if button.isSelected {
                    //选中，横屏旋转屏幕
                    self.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI_2)).translatedBy(x: contentofSet, y: contentofSet)
                }else{
                    //再次点击，回复原装
                    self.transform = CGAffineTransform.identity
                    if self.playerLayer != nil {
                        self.playerLayer?.frame = self.superViewFrame
                    }
                    self.frame = self.superViewFrame
                    self.videoLayerView.frame = self.superViewFrame
                    if self.playerLoadingView.superview != nil {
                        //添加了loading页面，才改变frame
                        self.playerLoadingView.frame = CGRect(x: (self.width-40)/2.0, y: (self.height-30)/2.0, width: 40, height: 30)
                    }
                    if self.videoStopLingView.superview != nil {
                        //添加停止加载的页面，才改变frame
                        self.videoStopLingView.frame = CGRect(x: (self.width-44)/2.0, y: (self.height-44)/2.0, width: 44, height: 44)
                    }
                    if self.loadingFailView.superview != nil {
                        //添加了失败页面，才改变frame
                        self.loadingFailView.frame = CGRect(x: 0, y: self.height/2.0-25, width: SCREEN_WIDTH, height: 50)
                    }
                }
            })
            //发送横屏的通知
            if block != nil {
                block!(button.isSelected)
            }
            break
        case 4:
            /// 关闭按钮
            dismissAlperView()
            break
        case 5:
            //点击返回竖屏
            let button = videoLayerView.viewWithTag(BUTTONTAG+3) as! UIButton
            button.isSelected = true
            videoLayerView(view: videoLayerView, button: button, buttonTag: 3)
            break
        default:
            break
        }
    }
    
    /// 改变slider的播放时间
    ///
    /// - Parameter sliderChangeTime: 进度条的值
    func videoLayerView(view: UIView, sliderChangeTime: Float) {
        if playSuccsee == false {
            //播放失败的时候，不可以滑动滑块
            return
        }
        playerManager.playerChangeBySliderChanged(sliderChangeTime: sliderChangeTime)
    }
    
    /// 屏幕旋转通知
    ///
    func orientChange() {
        let orient: UIDeviceOrientation = UIDevice.current.orientation

        switch orient {
        case .landscapeLeft:
            setScreenOrientation(leftOrientation: true)
        case .portrait:
            setScreenOrientation(leftOrientation: false)
        default:
            break
        }
    }
    
    /// 设置屏幕旋转
    func setScreenOrientation(leftOrientation:Bool) {
        let button = videoLayerView.viewWithTag(BUTTONTAG+3) as! UIButton
        
        if leftOrientation {
            //横屏
            if button.isSelected {
                return
            }
            button.isSelected = false
            videoLayerView(view: videoLayerView, button: button, buttonTag: 3)
        }else {
            //竖屏
            button.isSelected = true
            videoLayerView(view: videoLayerView, button: button, buttonTag: 3)
        }
    }
    
    /// 取消播放的层
    func dismissAlperView() {
        if playerLayer != nil {
            playerManager.closePlayer()
        }
        videoLayerView.setVideoLayerView(playOrPauseBtnSelected: false)
        self.removeFromSuperview()
    }
    
    /// 视频OR音频暂停和播放
    ///
    /// - Parameter play: 是否播放状态
    func playerPauseOrPlay(play:Bool=true) {
        if playerLayer == nil {
            //如果没有播放，则点击无效果
            return
        }
        if play == true && !playerManager.isPlaying {
            //外部设置播放，并且音频OR视频暂停的时候，播放
            playerManager.player.play()
            playerManager.isPlaying = true
            videoLayerView.setVideoLayerView(playOrPauseBtnSelected: false)
        }else if play == false && playerManager.isPlaying {
            //外部设置暂停，并且音频OR视频正在播放的时候，暂停
            playerManager.player.pause()
            playerManager.isPlaying = false
            videoLayerView.setVideoLayerView(playOrPauseBtnSelected: true)
        }
    }
    
    deinit {
        if playerLayer != nil {
            playerLayer?.removeFromSuperlayer()
        }
        NotificationCenter.default.removeObserver(self)
        UIApplication.shared.setStatusBarHidden(false, with: .none)
    }
}
