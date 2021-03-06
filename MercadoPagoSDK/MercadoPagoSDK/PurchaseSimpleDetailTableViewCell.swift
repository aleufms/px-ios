//
//  PurchaseItemAmountTableViewCell.swift
//  MercadoPagoSDK
//
//  Created by Maria cristina rodriguez on 11/2/16.
//  Copyright © 2016 MercadoPago. All rights reserved.
//

import UIKit

class PurchaseSimpleDetailTableViewCell: UITableViewCell {

    static let ROW_HEIGHT = CGFloat(58)
    static let SEPARATOR_LINE_HEIGHT = PurchaseSimpleDetailTableViewCell.ROW_HEIGHT - 1
    
    @IBOutlet weak var titleLabel: MPLabel!
    @IBOutlet weak var unitPrice: MPLabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    internal func fillCell(_ title : String, amount : Double, currency : Currency, payerCost : PayerCost? = nil, addSeparatorLine : Bool = true){
        
        //Deafult values for cells
        self.titleLabel.text = title
        self.titleLabel.font = Utils.getFont(size: titleLabel.font.pointSize)
        self.removeFromSuperview()
        if payerCost != nil {
            let purchaseAmount = getInstallmentsAmount(payerCost: payerCost!)
            self.unitPrice.attributedText = purchaseAmount
        } else {
            self.unitPrice.attributedText = Utils.getAttributedAmount(amount, thousandSeparator: currency.thousandsSeparator, decimalSeparator: currency.decimalSeparator, currencySymbol: currency.symbol, color : UIColor.px_grayDark(), fontSize : 18, baselineOffset : 5)
        }
        if addSeparatorLine {
            let separatorLine = ViewUtils.getTableCellSeparatorLineView(21, y: PurchaseSimpleDetailTableViewCell.SEPARATOR_LINE_HEIGHT, width: self.frame.width - 42, height: 1)
            self.addSubview(separatorLine)
        }
    }
    
    private func getInstallmentsAmount(payerCost : PayerCost) -> NSAttributedString {
        return Utils.getTransactionInstallmentsDescription(payerCost.installments.description, installmentAmount: payerCost.installmentAmount, color: UIColor.px_grayBaseText(), fontSize : 24, baselineOffset : 8)
        
    }
    
}
