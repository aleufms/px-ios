//
//  HeaderCongratsTableViewCell.swift
//  MercadoPagoSDK
//
//  Created by Eden Torres on 10/25/16.
//  Copyright © 2016 MercadoPago. All rights reserved.
//

import UIKit

class HeaderCongratsTableViewCell: UITableViewCell, TimerDelegate {

    @IBOutlet weak var messageError: UILabel!
    @IBOutlet weak var view: UIView!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var title: UILabel!
    var timerLabel: MPLabel?

    @IBOutlet weak var subtitle: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        // Initialization code

        title.font = Utils.getFont(size: title.font.pointSize)
        messageError.text = ""
        messageError.font = Utils.getFont(size: messageError.font.pointSize)
        subtitle.text = ""
    }

    func fillCell(paymentResult: PaymentResult, paymentMethod: PaymentMethod?, color: UIColor, paymentResultScreenPreference: PaymentResultScreenPreference) {

        view.backgroundColor = color

        if paymentResult.status == "approved" {
            icon.image = paymentResultScreenPreference.getHeaderApprovedIcon()
            title.text = paymentResultScreenPreference.getApprovedTitle()
            subtitle.text = paymentResultScreenPreference.getApprovedSubtitle()

        } else if paymentResult.status == "in_process" {
            icon.image = paymentResultScreenPreference.getHeaderPendingIcon()
            title.text = paymentResultScreenPreference.getPendingTitle()
            subtitle.text = paymentResultScreenPreference.getPendingSubtitle()

        } else if paymentResult.statusDetail == "cc_rejected_call_for_authorize" {
            icon.image = MercadoPago.getImage("MPSDK_payment_result_c4a")
            var titleWithParams: String = ""
            if let paymentMethodName = paymentMethod?.name {
                titleWithParams = ("Debes autorizar ante %p el pago de %t a MercadoPago".localized as NSString).replacingOccurrences(of: "%p", with: "\(paymentMethodName)")
            }
            let currency = MercadoPagoContext.getCurrency()
            let currencySymbol = currency.getCurrencySymbolOrDefault()
            let thousandSeparator = currency.getThousandsSeparatorOrDefault()
            let decimalSeparator = currency.getDecimalSeparatorOrDefault()

            let amountRange = titleWithParams.range(of: "%t")

            if amountRange != nil {
                let attributedTitle = NSMutableAttributedString(string: (titleWithParams.substring(to: (amountRange?.lowerBound)!)), attributes: [NSFontAttributeName: Utils.getFont(size: 22)])
                let attributedAmount = Utils.getAttributedAmount(paymentResult.paymentData!.payerCost!.totalAmount, thousandSeparator: thousandSeparator, decimalSeparator: decimalSeparator, currencySymbol: currencySymbol, color: UIColor.px_white())
                attributedTitle.append(attributedAmount)
                let endingTitle = NSAttributedString(string: (titleWithParams.substring(from: (amountRange?.upperBound)!)), attributes: [NSFontAttributeName: Utils.getFont(size: 22)])
                attributedTitle.append(endingTitle)
                self.title.attributedText = attributedTitle
            }
        } else {
            icon.image = paymentResultScreenPreference.getHeaderRejectedIcon()
            var title = (paymentResult.statusDetail + "_title")
            if !title.existsLocalized() {
                if !String.isNullOrEmpty(paymentResultScreenPreference.getRejectedTitle()) {
                    self.title.text = paymentResultScreenPreference.getRejectedTitle()
                    subtitle.text = paymentResultScreenPreference.getRejectedSubtitle()
                } else {
                    self.title.text = "Uy, no pudimos procesar el pago".localized
                }
            } else {
                if let paymentMethodName = paymentMethod?.name {
                    let titleWithParams = (title.localized as NSString).replacingOccurrences(of: "%0", with: "\(paymentMethodName)")
                    self.title.text = titleWithParams
                }
            }

            if CountdownTimer.getInstance().hasTimer() {
                self.timerLabel = MPLabel(frame: CGRect(x: UIScreen.main.bounds.size.width - 66, y: 10, width: 56, height: 20))
                self.timerLabel!.backgroundColor = color
                self.timerLabel!.textColor = UIColor.px_white()
                self.timerLabel!.textAlignment = .right
                CountdownTimer.getInstance().delegate = self
                self.addSubview(timerLabel!)
            }

            messageError.text = paymentResultScreenPreference.getRejectedIconSubtext()
        }
    }

    func fillCell(instructionsInfo: InstructionsInfo, color: UIColor) {

        view.backgroundColor = color

        icon.image = MercadoPago.getImage("MPSDK_payment_result_off")
        let currency = MercadoPagoContext.getCurrency()
        let currencySymbol = currency.getCurrencySymbolOrDefault()
        let thousandSeparator = currency.getThousandsSeparatorOrDefault()
        let decimalSeparator = currency.getDecimalSeparatorOrDefault()

        let arr = String(instructionsInfo.amountInfo.amount).characters.split(separator: ".").map(String.init)
        let amountStr = Utils.getAmountFormatted(arr[0], thousandSeparator: thousandSeparator, decimalSeparator: decimalSeparator)
        let centsStr = Utils.getCentsFormatted(String(instructionsInfo.amountInfo.amount), decimalSeparator: decimalSeparator)
        let amountRange = instructionsInfo.instructions[0].title.range(of: currencySymbol + " " + amountStr + decimalSeparator + centsStr)

        if amountRange != nil {
            let attributedTitle = NSMutableAttributedString(string: (instructionsInfo.instructions[0].title.substring(to: (amountRange?.lowerBound)!)), attributes: [NSFontAttributeName: Utils.getFont(size: 22)])
            let attributedAmount = Utils.getAttributedAmount(instructionsInfo.amountInfo.amount, thousandSeparator: thousandSeparator, decimalSeparator: decimalSeparator, currencySymbol: currencySymbol, color: UIColor.px_white())
            attributedTitle.append(attributedAmount)
            let endingTitle = NSAttributedString(string: (instructionsInfo.instructions[0].title.substring(from: (amountRange?.upperBound)!)), attributes: [NSFontAttributeName: Utils.getFont(size: 22)])
            attributedTitle.append(endingTitle)

            self.title.attributedText = attributedTitle
        } else {
            let attributedTitle = NSMutableAttributedString(string: (instructionsInfo.instructions[0].title), attributes: [NSFontAttributeName: Utils.getFont(size: 22)])
            self.title.attributedText = attributedTitle
        }

    }

    func updateTimer() {
        if self.timerLabel != nil {
            self.timerLabel!.text = CountdownTimer.getInstance().getCurrentTiming()
        }

    }
}

class PaymentResultHeaderView: UIView, TimerDelegate {
    var timerLabel: MPLabel?
    var viewModel: PaymentResultHeaderViewModel!
    var icon: UIImageView!
    var title: UILabel!
    var messageError: UILabel!

    var rect =  CGRect(x: 0, y: 0, width : UIScreen.main.bounds.width, height : 0)
    var height: CGFloat = 0

    init (paymentResult: PaymentResult, paymentMethod: PaymentMethod?, color: UIColor, paymentResultScreenPreference: PaymentResultScreenPreference) {
        super.init(frame: rect)
        self.backgroundColor = color
        self.viewModel = PaymentResultHeaderViewModel(paymentResult: paymentResult, paymentMethod: paymentMethod, paymentResultScreenPreference: paymentResultScreenPreference)

        height = self.viewModel.topMargin

        let icon = UIImageView()
        icon.image = self.viewModel.getIcon().withRenderingMode(.automatic)

        let frameLabel = CGRect(x: frame.width/2 - icon.image!.size.width/2, y: height, width: icon.image!.size.width, height: icon.image!.size.height)
        height += icon.image!.size.height
        icon.frame = frameLabel
        self.addSubview(icon)

        if self.viewModel.isPaymentRejected() {
            height += 10
            makeLabel(attributedText: self.viewModel.getIconDescription())
        }

        height += self.viewModel.iconTitleMargin

        makeLabel(attributedText: self.viewModel.getTitle())

        height += self.viewModel.titleSubtitleMargin

        makeLabel(attributedText: self.viewModel.getSubtitle())

        self.frame = CGRect(x: 0, y: 0, width : UIScreen.main.bounds.width, height : height + self.viewModel.topMargin)
    }

    func makeLabel(attributedText: NSAttributedString, color: UIColor = UIColor.px_white(), leftMargin: CGFloat = PaymentResultHeaderViewModel.leftMargin) {
        let label = MPLabel()
        label.attributedText = attributedText
        label.textColor = color
        label.textAlignment = .center
        label.frame = CGRect(x: leftMargin, y: height, width: frame.size.width - (2 * leftMargin), height: 0)
        let frameLabel = CGRect(x: leftMargin, y: height, width: frame.size.width - (2 * leftMargin), height: label.requiredHeight())
        label.frame = frameLabel
        label.numberOfLines = 0
        height += label.requiredHeight()
        self.addSubview(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateTimer() {
        if self.timerLabel != nil {
            self.timerLabel!.text = CountdownTimer.getInstance().getCurrentTiming()
        }

    }
}

class PaymentResultHeaderViewModel: NSObject {
    let topMargin: CGFloat = 50
    static let leftMargin: CGFloat = 22
    let iconTitleMargin: CGFloat = 30
    let titleSubtitleMargin: CGFloat = 15

    let titleFontSize: CGFloat = 22
    let iconDescriptionFontSize: CGFloat = 16
    let subtitleFontSize: CGFloat = 18

    let paymentResult: PaymentResult
    let paymentMethod: PaymentMethod?
    let paymentResultScreenPreference: PaymentResultScreenPreference

    let currencySymbol = MercadoPagoContext.getCurrency().getCurrencySymbolOrDefault()
    let thousandSeparator = MercadoPagoContext.getCurrency().getThousandsSeparatorOrDefault()
    let decimalSeparator = MercadoPagoContext.getCurrency().getDecimalSeparatorOrDefault()

    init (paymentResult: PaymentResult, paymentMethod: PaymentMethod?, paymentResultScreenPreference: PaymentResultScreenPreference) {
        self.paymentMethod = paymentMethod
        self.paymentResult = paymentResult
        self.paymentResultScreenPreference = paymentResultScreenPreference
    }

    func getFontAttribute(fontSize: CGFloat) -> [String : Any] {
        return [NSFontAttributeName: Utils.getFont(size: fontSize)]
    }

    func getTitle() -> NSAttributedString {
        if isPaymentApproved() {
            return NSAttributedString(string: paymentResultScreenPreference.getApprovedTitle(), attributes: getFontAttribute(fontSize: titleFontSize))
        } else if isPaymentPending() {
            return NSAttributedString(string: paymentResultScreenPreference.getPendingTitle(), attributes: getFontAttribute(fontSize: titleFontSize))
        } else if isPaymentRejected() {
            return getRejectedTitle()
        } else if isPaymentCalledForAuth() {
            return getCallForAuthTitle()
        }
        return NSAttributedString(string: "")
    }

    func getRejectedTitle() -> NSAttributedString {
        let title = (paymentResult.statusDetail + "_title")
        if title.existsLocalized() {
            if let paymentMethodName = paymentMethod?.name {
                let titleWithParams = (title.localized as NSString).replacingOccurrences(of: "%0", with: "\(paymentMethodName)")
                return NSAttributedString(string: titleWithParams, attributes: getFontAttribute(fontSize: titleFontSize))
            }

        } else {
            if !String.isNullOrEmpty(paymentResultScreenPreference.getRejectedTitle()) {
                return NSAttributedString(string: paymentResultScreenPreference.getRejectedTitle(), attributes: getFontAttribute(fontSize: titleFontSize))
            }
        }
        return NSAttributedString(string:"Uy, no pudimos procesar el pago".localized, attributes: getFontAttribute(fontSize: titleFontSize))
    }

    func getCallForAuthTitle() -> NSAttributedString {
        var titleWithParams: String = ""
        if let paymentMethodName = paymentMethod?.name {
            titleWithParams = ("Debes autorizar ante %p el pago de %t a MercadoPago".localized as NSString).replacingOccurrences(of: "%p", with: "\(paymentMethodName)")
        }

        let amountRange = titleWithParams.range(of: "%t")

        if amountRange != nil {
            let attributedTitle = NSMutableAttributedString(string: (titleWithParams.substring(to: (amountRange?.lowerBound)!)), attributes: [NSFontAttributeName: Utils.getFont(size: 22)])
            let attributedAmount = Utils.getAttributedAmount(paymentResult.paymentData!.payerCost!.totalAmount, thousandSeparator: thousandSeparator, decimalSeparator: decimalSeparator, currencySymbol: currencySymbol, color: UIColor.px_white())
            attributedTitle.append(attributedAmount)
            let endingTitle = NSAttributedString(string: (titleWithParams.substring(from: (amountRange?.upperBound)!)), attributes: [NSFontAttributeName: Utils.getFont(size: 22)])
            attributedTitle.append(endingTitle)
            return attributedTitle
        }
        return NSAttributedString(string: titleWithParams)
    }

    func isPaymentApproved() -> Bool {
        return paymentResult.status == PaymentStatus.APPROVED.rawValue
    }

    func isPaymentRejected() -> Bool {
        return paymentResult.status == PaymentStatus.REJECTED.rawValue && paymentResult.statusDetail != "cc_rejected_call_for_authorize"
    }
    func isPaymentCalledForAuth() -> Bool {
        return paymentResult.status == PaymentStatus.REJECTED.rawValue && paymentResult.statusDetail == "cc_rejected_call_for_authorize"
    }

    func isPaymentPending() -> Bool {
        return paymentResult.status == PaymentStatus.IN_PROCESS.rawValue
    }

    func getIcon() -> UIImage {
        if isPaymentApproved() {
            return paymentResultScreenPreference.getHeaderApprovedIcon()
        } else if isPaymentPending() {
            return paymentResultScreenPreference.getHeaderPendingIcon()
        } else if isPaymentRejected() {
            return paymentResultScreenPreference.getHeaderRejectedIcon()
        } else if isPaymentCalledForAuth() {
            return MercadoPago.getImage("MPSDK_payment_result_c4a")!
        }
        return MercadoPago.getImage("MPSDK_payment_result_error", bundle: MercadoPago.getBundle()!)!
    }

    func getIconDescription() -> NSAttributedString {
        return NSAttributedString(string: paymentResultScreenPreference.getRejectedIconSubtext(), attributes: getFontAttribute(fontSize: iconDescriptionFontSize))
    }

    func getSubtitle() -> NSAttributedString {
        if isPaymentApproved() {
            return NSAttributedString(string: paymentResultScreenPreference.getApprovedSubtitle(), attributes: getFontAttribute(fontSize: subtitleFontSize))
        } else if isPaymentRejected() {
            return NSAttributedString(string: paymentResultScreenPreference.getRejectedSubtitle(), attributes: getFontAttribute(fontSize: subtitleFontSize))
        } else if isPaymentPending() {
            return NSAttributedString(string: paymentResultScreenPreference.getPendingSubtitle(), attributes: getFontAttribute(fontSize: subtitleFontSize))

        }
        return NSAttributedString(string: "")

    }

    func hasSubtitle() -> Bool {
        let caseApproved = isPaymentApproved() && !String.isNullOrEmpty(paymentResultScreenPreference.getApprovedSubtitle())
        let casePending = isPaymentPending() && !String.isNullOrEmpty(paymentResultScreenPreference.getPendingSubtitle())
        let caseRejected = isPaymentRejected() && !String.isNullOrEmpty(paymentResultScreenPreference.getRejectedSubtitle())

        return caseApproved || casePending || caseRejected
    }

}
