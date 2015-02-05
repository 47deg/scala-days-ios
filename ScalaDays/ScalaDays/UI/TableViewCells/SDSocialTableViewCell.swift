//
//  SDSocialTableViewCell.swift
//  ScalaDays
//
//  Created by Javier de Silóniz Sandino on 02/02/15.
//  Copyright (c) 2015 Ana. All rights reserved.
//

import UIKit

class SDSocialTableViewCell: UITableViewCell {
    @IBOutlet var imgView : UIImageView?
    @IBOutlet var lblFullName : UILabel?
    @IBOutlet var lblUsername : UILabel?
    @IBOutlet var lblContent : UILabel?
    @IBOutlet var lblDate : UILabel?
    @IBOutlet var lblContentBottomConstraint : NSLayoutConstraint?
    
    let kPaddingLeftForLblContent : CGFloat = 15.0
    let kPaddingRightForLblContent : CGFloat = 15.0
    let kPaddingLeftForImgView : CGFloat = 15.0
    let kWidthForImgView : CGFloat = 40.0
    
    override func awakeFromNib() {
        imgView?.circularImage()
        lblContent?.numberOfLines = 0
        /*lblContent?.textColor = UIColor.appColor()
        lblFullName?.textColor = UIColor.appColor()
        lblDate?.textColor = UIColor.appColor()
        lblUsername?.textColor = UIColor.appRedColor()*/
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        lblContent?.preferredMaxLayoutWidth = self.frame.size.width - kWidthForImgView - kPaddingLeftForImgView - kPaddingLeftForLblContent - kPaddingRightForLblContent
    }
}
