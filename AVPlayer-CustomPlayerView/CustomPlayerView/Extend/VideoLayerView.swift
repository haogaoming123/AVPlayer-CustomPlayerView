//
//  VideoLayerView.swift
//  SwiftToutiao
//
//  Created by haogaoming on 2016/11/18.
//  Copyright © 2016年 votee. All rights reserved.
//

import UIKit

let BUTTONTAG  =  201629        /// 按钮的tag值

protocol VideoLayerViewDelegate: NSObjectProtocol {
    
    /// 点击按钮的点击事件
    ///
    /// - Parameters:
    ///   - view: 本类
    ///   - buttonTag: 按钮的tag，从0开始
    func videoLayerView(view: UIView,button:UIButton,buttonTag:Int)
    
    /// 改变slider的值，快进/快退
    ///
    /// - Parameters:
    ///   - view: 本类
    ///   - sliderChangeTime: slider的值
    func videoLayerView(view: UIView,sliderChangeTime:Float)
}

class VideoLayerView: UIView
{
    /// 页面的代理
    weak var delegate: VideoLayerViewDelegate?
    
    /// 加载视频的默认图
    var videoDefaultImageview:UIImageView?
    
    /// 上一个按钮是否显示
    var rewindBtnHidden: Bool = true
    
    /// 下一个按钮是否显示
    var forwardBtnHidden: Bool = true
    
    /// 灰色背景图
    lazy var topViewAlpha: UIView = {
        let view = UIView()
        view.alpha = 0.4
        view.backgroundColor = UIColor.black
        self.addSubview(view)
        return view
    }()
    
    /// 暂停or开始按钮
    lazy var playOrPauseButton: UIButton = {
        let button = UIButton(superView: self, target: self, selector: #selector(buttonAction(_:)), imageName: "icon_viedio_stop", selectedImageName: "icon_viedio_play")
        button.tag = BUTTONTAG
        button.backgroundColor = UIColor.clear
        return button
    }()
    
    /// 播放上一个按钮
    lazy var rewindButton: UIButton = {
        let button = UIButton(superView: self, target: self, selector: #selector(buttonAction(_:)), imageName: "icon_viedio_rewind")
        button.tag = BUTTONTAG+1
        button.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.playOrPauseButton.snp.centerY)
            make.right.equalTo(self.playOrPauseButton.snp.left).offset(-20)
            make.width.height.equalTo(35)
        }
        return button
    }()
    
    /// 播放下一个按钮
    lazy var forwardButton: UIButton = {
        let button = UIButton(superView: self, target: self, selector: #selector(buttonAction(_:)), imageName: "icon_viedio_forward")
        button.tag = BUTTONTAG+2
        button.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.playOrPauseButton.snp.centerY)
            make.left.equalTo(self.playOrPauseButton.snp.right).offset(20)
            make.width.height.equalTo(35)
        }
        return button
    }()
    
    /// 全屏按钮
    lazy var screenButton: UIButton = {
        let button = UIButton(superView: self, target: self, selector: #selector(buttonAction(_:)), imageName: "btn_viedio_fullscreen")
        button.tag = BUTTONTAG+3
        button.backgroundColor = UIColor.clear
        return button
    }()
    
    /// 关闭按钮
    lazy var closeButton: UIButton = {
        let button = UIButton(superView: self, target: self, selector: #selector(buttonAction(_:)), imageName: "icon_closevideo")
        button.tag = BUTTONTAG+4
        button.backgroundColor = UIColor.clear
        return button
    }()
    
    /// 返回按钮
    lazy var backButton: UIButton = {
        let button = UIButton(superView: self, target: self, selector: #selector(buttonAction(_:)), imageName: "icon_back_video")
        button.tag = BUTTONTAG+5
        button.backgroundColor = UIColor.clear
        return button
    }()
    
    /// 当前播放时间lable
    lazy var currentTimeLable: UILabel = {
        let lable = UILabel(superView: self, font: FONTSYS10, textColor: UIColor.white, alignment: .right)
        lable.backgroundColor = UIColor.clear
        lable.text = "00:00:00"
        return lable
    }()
    
    /// 播放的总时间
    lazy var totalTimeLable: UILabel = {
        let lable = UILabel(superView: self, font: FONTSYS10, textColor: UIColor.white, alignment: .left)
        lable.backgroundColor = UIColor.clear
        lable.text = "00:00:00"
        return lable
    }()
    
    /// 播放的进度条
    lazy var controlSlider: UISlider = {
        let slider = UISlider()
        //slider.setMaximumTrackImage(UIImage(named: "icon_progressbar_black"), for: .normal)
        slider.maximumTrackTintColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        slider.setMinimumTrackImage(UIImage(named: "icon_progressbar_yellow"), for: .normal)
        slider.setThumbImage(UIImage(named: "icon_progressbar_yellow"), for: .normal)
        slider.addTarget(self, action: #selector(sliderChangePlayTime(_:)), for: .valueChanged)
        self.addSubview(slider)
        return slider
    }()
    
    /// 视频缓冲时间view
    lazy var progressView: UIProgressView = {
        let progress = UIProgressView()
        progress.backgroundColor = UIColor.lightGray
        progress.tintColor = UIColor.black
        progress.progress = 0
        return progress
    }()
    
    init(frame: CGRect,isMp3:Bool=false) {
        super.init(frame: frame)
        
        topViewAlpha.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }
        //如果是视频格式的话，添加两个按钮
        if isMp3 == false {
            //视频格式
            /// 暂停or开始按钮
            playOrPauseButton.snp.makeConstraints { (make) in
                make.center.equalTo(self)
                make.width.height.equalTo(44)
            }
            /// 返回按钮
            backButton.isHidden = true
            backButton.snp.makeConstraints { (make) in
                make.top.equalTo(self.snp.top).offset(5)
                make.left.equalTo(self.snp.left)
                make.width.height.equalTo(44)
            }
        }else {
            //视音频格式，则显示暂停/开始按钮
            screenButton.setImage(UIImage(named: "icon_audio_play"), for: .selected)
            screenButton.setImage(UIImage(named: "icon_audio_stop"), for: .normal)
        }
        
        /// 全屏按钮
        screenButton.snp.makeConstraints { (make) in
            make.bottom.equalTo(self.snp.bottom)
            make.right.equalTo(self.snp.right)
            make.width.height.equalTo(44)
        }
        /// 关闭按钮
        closeButton.snp.makeConstraints { (make) in
            make.top.equalTo(self.snp.top).offset(5)
            make.right.equalTo(self.snp.right)
            make.width.height.equalTo(44)
        }
        
        /// 当前播放时间lable
        currentTimeLable.snp.makeConstraints { (make) in
            make.left.equalTo(self.snp.left).offset(5)
            make.bottom.equalTo(self.snp.bottom).offset(-12)
            make.width.equalTo(45)
            make.height.equalTo(15)
        }
        /// 播放的总时间
        totalTimeLable.snp.makeConstraints { (make) in
            make.right.equalTo(screenButton.snp.left)
            make.bottom.equalTo(self.snp.bottom).offset(-12)
            make.height.equalTo(15)
            make.width.equalTo(45)
        }
        /// 播放的进度条
        controlSlider.snp.makeConstraints { (make) in
            make.left.equalTo(currentTimeLable.snp.right).offset(5)
            make.right.equalTo(totalTimeLable.snp.left).offset(-5)
            make.bottom.equalTo(self.snp.bottom).offset(-10)
            make.height.equalTo(20)
        }
        /// 缓存进度条
        self.insertSubview(progressView, belowSubview: controlSlider)
        progressView.snp.makeConstraints { (make) in
            make.left.right.equalTo(controlSlider)
            make.height.equalTo(2)
            make.centerY.equalTo(controlSlider.snp.centerY).offset(1)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 按钮点击事件
    ///
    /// - Parameter btn: 按钮
    func buttonAction(_ btn:UIButton) {
        let tag = btn.tag
        self.delegate?.videoLayerView(view: self, button: btn, buttonTag: tag-BUTTONTAG)
    }
    
    /// 隐藏button的操作---私有方法
    ///
    /// - Parameter hidden: hidden
    func buttonHidden(_ hidden:Bool) {
        topViewAlpha.isHidden = hidden
        playOrPauseButton.isHidden = hidden
        closeButton.isHidden = hidden
        currentTimeLable.isHidden = hidden
        controlSlider.isHidden = hidden
        progressView.isHidden = hidden
        totalTimeLable.isHidden = hidden
        screenButton.isHidden = hidden
        /// 当横屏显示的时候，显示返回按钮
        if screenButton.isSelected == true {
            backButton.isHidden = hidden
        }else{
            backButton.isHidden = true
        }
        /// 上一个/下一个按钮
        if rewindBtnHidden == false {
            rewindButton.isHidden = hidden
        }else{
            rewindButton.isHidden = true
        }
        if forwardBtnHidden == false {
            forwardButton.isHidden = hidden
        }else{
            forwardButton.isHidden = true
        }
    }
    
    /// 改变slider的播放时间
    ///
    /// - Parameter slider: 进度条
    func sliderChangePlayTime(_ slider:UISlider) {
        self.delegate?.videoLayerView(view: self, sliderChangeTime: slider.value)
    }
    
    /// 改变UI的状态
    ///
    /// - Parameters:
    ///   - totalTime: 视频的总时间
    ///   - currentTime: 当前的播放时间
    ///   - sliderVaule: 进度条的值
    ///   - rewindBtnHidden: 上一个按钮隐藏状态
    ///   - forwardBtn: 下一个按钮的隐藏状态
    ///   - progressValue: 缓存进度的值
    ///   - playOrPauseBtnSelected: 播放/暂停按钮选中状态
    func setVideoLayerView(totalTime:String?=nil,currentTime:String?=nil,sliderVaule:Float?=nil,rewindBtnHidden:Bool?=nil,forwardBtnHidden:Bool?=nil,progressValue:Float?=nil,playOrPauseBtnSelected:Bool?=nil,backButtonHidden:Bool?=nil,closeButtonHidden:Bool?=nil,playOrPauseBtnHidden:Bool?=nil,screenBtnHidden:Bool?=nil)
    {
        if totalTime != nil {
            totalTimeLable.text = totalTime
        }
        if currentTime != nil {
            currentTimeLable.text = currentTime
        }
        if sliderVaule != nil {
            controlSlider.value = sliderVaule!
        }
        if rewindBtnHidden != nil {
//            rewindButton.isHidden = rewindBtnHidden!
            self.rewindBtnHidden = rewindBtnHidden!
        }
        if forwardBtnHidden != nil {
//            forwardButton.isHidden = forwardBtnHidden!
            self.forwardBtnHidden = forwardBtnHidden!
        }
        if progressValue != nil {
            progressView.progress  = progressValue!
        }
        if playOrPauseBtnSelected != nil {
            playOrPauseButton.isSelected  = playOrPauseBtnSelected!
        }
        if backButtonHidden != nil {
            backButton.isHidden = backButtonHidden!
        }
        if closeButtonHidden != nil {
            closeButton.isHidden = closeButtonHidden!
        }
        if playOrPauseBtnHidden != nil {
            playOrPauseButton.isHidden = playOrPauseBtnHidden!
        }
        if screenBtnHidden != nil {
            screenButton.isSelected = screenBtnHidden!
        }
    }
    
    /// 视频加载的默认图片
    ///
    /// - Parameter hidden: 是否隐藏
    func videoDefalueImageHiddden(hidden:Bool,imageurl:String?=nil) {
        if hidden == false && imageurl != nil {
            videoDefaultImageview = UIImageView()
            videoDefaultImageview?
                .setImage(withUrlString: imageurl!)
            self.addSubview(videoDefaultImageview!)
            self.sendSubview(toBack: videoDefaultImageview!)
            videoDefaultImageview?.snp.makeConstraints { (make) in
                make.edges.equalTo(self)
            }
        }else {
            videoDefaultImageview?.removeFromSuperview()
        }
    }
}
