//
//  FailReloadView.swift
//  SwiftToutiao
//
//  Created by haogaoming on 2016/11/18.
//  Copyright © 2016年 votee. All rights reserved.
//

import UIKit
import SnapKit

protocol VideoFailedReloadViewDelegate: NSObjectProtocol {
    
    /// 代理方法---点击重新加载
    ///
    /// - Parameters:
    ///   - view: 本类
    ///   - reloadBtn: 重新加载的button
    func failReloadView(view:UIView,reloadBtn:UIButton)
}

class VideoFailedReloadView: UIView
{
    weak var delegate: VideoFailedReloadViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        //重新加载的button
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(reloadVideoPlayer(_:)), for: .touchUpInside)
        button.setTitle("加载失败,点击重试", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.snp.makeConstraints({ (make) in
            make.centerX.centerY.equalTo(self)
            make.width.equalTo(self.snp.width)
            make.height.equalTo(50)
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 点击重新加载---点击事件
    ///
    /// - Parameter btn: 冲洗加载按钮
    @objc private func reloadVideoPlayer(_ btn:UIButton) {
        self.delegate?.failReloadView(view: self, reloadBtn: btn)
    }
}
