//
//  VideoLoadingView.swift
//  SwiftToutiao
//
//  Created by haogaoming on 2016/11/18.
//  Copyright © 2016年 votee. All rights reserved.
//

import UIKit

class VideoLoadingView: UIView
{
    /// 旋转的image
    var imageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView = UIImageView()
        
        var imagesArr = Array<UIImage>()
        for index in 4..<21 {
            let image = UIImage(named: "icon_loading_yellow_\(index)")
            imagesArr.append(image!)
        }
        imageView.contentMode = .center
        imageView.animationImages = imagesArr
        imageView.animationDuration = 1
        self.addSubview(imageView)
        imageView.snp.makeConstraints({ (make) in
            make.centerX.centerY.equalTo(self)
            make.width.equalTo(35)
            make.height.equalTo(20)
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 重写系统方法
    var _hidden = false
    override var isHidden: Bool {
        set{
            _hidden = newValue
            if newValue {
                //隐藏的时候停止转动
                imageView.stopAnimating()
            }else{
                //显示的时候开始转动
                imageView.startAnimating()
            }
            super.isHidden = newValue
        }
        get{
            return _hidden
        }
    }
    
}
