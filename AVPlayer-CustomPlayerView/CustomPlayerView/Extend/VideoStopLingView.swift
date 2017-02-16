//
//  VideoStopLingView.swift
//  SwiftToutiao
//
//  Created by haogaoming on 2017/1/12.
//  Copyright © 2017年 votee. All rights reserved.
//  在4G情况下，不看视频的view

import UIKit

protocol videoStopLingViewDelegate:NSObjectProtocol {
    
    /// 在非WiFi的情况下，加载视频
    ///
    /// - Parameters:
    ///   - view: view
    ///   - btn: 加载button
    func videoStopLingView(view:UIView, LoadingVideoNoWifi btn:UIButton)
}

class VideoStopLingView: UIView
{
    weak var delegate: videoStopLingViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        //重新加载的button
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(LoadingVideoNoWifiClick(_:)), for: .touchUpInside)
        button.setImage(UIImage(named: "icon_viedio_play"), for: .normal)
        self.addSubview(button)
        
        button.setTitleColor(UIColor.white, for: .normal)
        button.snp.makeConstraints({ (make) in
            make.centerX.centerY.equalTo(self)
            make.width.height.equalTo(44)
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 点击重新加载---点击事件
    ///
    /// - Parameter btn: 冲洗加载按钮
    @objc private func LoadingVideoNoWifiClick(_ btn:UIButton) {
        self.delegate?.videoStopLingView(view: self, LoadingVideoNoWifi: btn)
    }
}
