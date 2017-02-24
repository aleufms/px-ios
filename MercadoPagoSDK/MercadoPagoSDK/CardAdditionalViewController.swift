//
//  CardAdditionalStep.swift
//  MercadoPagoSDK
//
//  Created by Eden Torres on 10/13/16.
//  Copyright © 2016 MercadoPago. All rights reserved.
//

import UIKit

open class CardAdditionalViewController: MercadoPagoUIScrollViewController, UITableViewDelegate,UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var bundle : Bundle? = MercadoPago.getBundle()
    let viewModel : CardAdditionalStepViewModel!
    
    
     override open var screenName : String { get{
        if viewModel.hasIssuer() {
            return "PAYER_COST"
        } else if viewModel.hasPaymentMethod(){
            return "ISSUER"
        } else {
            return "CARD_TYPE"
        }
        } }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .none
        loadMPStyles()
        
        var upperFrame = UIScreen.main.bounds
        upperFrame.origin.y = -upperFrame.size.height;
        let upperView = UIView(frame: upperFrame)
        upperView.backgroundColor = UIColor.primaryColor()
        tableView.addSubview(upperView)
        
        self.showNavBar()
        
        let titleNib = UINib(nibName: "PayerCostTitleTableViewCell", bundle: self.bundle)
        self.tableView.register(titleNib, forCellReuseIdentifier: "titleNib")
        let cardNib = UINib(nibName: "PayerCostCardTableViewCell", bundle: self.bundle)
        self.tableView.register(cardNib, forCellReuseIdentifier: "cardNib")
        let rowInstallmentNib = UINib(nibName: "PayerCostRowTableViewCell", bundle: self.bundle)
        self.tableView.register(rowInstallmentNib, forCellReuseIdentifier: "rowInstallmentNib")
        let rowIssuerNib = UINib(nibName: "IssuerRowTableViewCell", bundle: self.bundle)
        self.tableView.register(rowIssuerNib, forCellReuseIdentifier: "rowIssuerNib")
        let cardTypeNib = UINib(nibName: "CardTypeTableViewCell", bundle: self.bundle)
        self.tableView.register(cardTypeNib, forCellReuseIdentifier: "cardTypeNib")
        
    }
    
    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.hideNavBar()

    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.title = ""
        self.showLoading()
        
        if !self.viewModel.hasIssuer() {
            self.getIssuers()
        } else if self.viewModel.hasPaymentMethod(){
            if self.viewModel.installment == nil {
                self.getInstallments()
            } else {
                self.viewModel.payerCosts = self.viewModel.installment!.payerCosts
                self.hideLoading()
            }
        }
        self.extendedLayoutIncludesOpaqueBars = true
        self.titleCellHeight = 44

    }
    
    override func loadMPStyles(){
        if self.navigationController != nil {
            self.navigationController!.interactivePopGestureRecognizer?.delegate = self
            self.navigationController?.navigationBar.tintColor = UIColor(red: 255, green: 255, blue: 255)
            self.navigationController?.navigationBar.barTintColor = UIColor.primaryColor()
            self.navigationController?.navigationBar.removeBottomLine()
            self.navigationController?.navigationBar.isTranslucent = false
            
            displayBackButton()
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    public init(viewModel : CardAdditionalStepViewModel, collectPayerCostCallback: @escaping ((_ payerCost: PayerCost?)->Void) ) {
        self.viewModel = viewModel
        self.viewModel.callbackPayerCost = collectPayerCostCallback
        super.init(nibName: "CardAdditionalViewController", bundle: self.bundle)
    }
    
    public init(viewModel : CardAdditionalStepViewModel, collectPaymentMethodCallback: @escaping ((_ paymentMethod: PaymentMethod?)->Void) ) {
        self.viewModel = viewModel
        self.viewModel.callbackPaymentMethod = collectPaymentMethodCallback
        super.init(nibName: "CardAdditionalViewController", bundle: self.bundle)
    }
    
    public init(viewModel : CardAdditionalStepViewModel,  collectIssuerCallback: @escaping ((_ issuer: Issuer?)->Void) ) {
        self.viewModel = viewModel
        self.viewModel.callbackIssuer = collectIssuerCallback
        super.init(nibName: "CardAdditionalViewController", bundle: self.bundle)
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        switch indexPath.section {
        case 0:
            return self.titleCellHeight
        case 1:
            return self.viewModel.getCardCellHeight()
        case 2:
            return self.viewModel.gerRowCellHeight()
            
        default:
            return 60
        }
        
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (section == 0 || section == 1){
            return 1
        } else {
            return self.viewModel.numberOfPayerCost()
        }
    }
    
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if (indexPath.section == 0){
            
            let titleCell = tableView.dequeueReusableCell(withIdentifier: "titleNib", for: indexPath as IndexPath) as! PayerCostTitleTableViewCell
            titleCell.selectionStyle = .none
            titleCell.setTitle(string: self.getNavigationBarTitle())
            titleCell.backgroundColor = UIColor.primaryColor()
            self.titleCell = titleCell
            
            return titleCell
            
        } else if (indexPath.section == 1){
            let cardCell = tableView.dequeueReusableCell(withIdentifier: "cardNib", for: indexPath as IndexPath) as! PayerCostCardTableViewCell
            cardCell.selectionStyle = .none
            cardCell.loadCard()
            cardCell.updateCardSkin(token: self.viewModel.token, paymentMethod: self.viewModel.paymentMethods[0], cardInformation: self.viewModel.cardInformation)
            cardCell.backgroundColor = UIColor.primaryColor()
            
            return cardCell
            
        } else {
            if self.viewModel.hasIssuer(){
                let payerCost : PayerCost = self.viewModel.payerCosts![indexPath.row]
                let installmentCell = tableView.dequeueReusableCell(withIdentifier: "rowInstallmentNib", for: indexPath as IndexPath) as! PayerCostRowTableViewCell
                installmentCell.fillCell(payerCost: payerCost)
                installmentCell.selectionStyle = .none
                installmentCell.addSeparatorLineToTop(width: Double(installmentCell.contentView.frame.width), y:Float(installmentCell.contentView.bounds.maxY))
                
                return installmentCell
            } else  if self.viewModel.hasPaymentMethod(){
                let issuer : Issuer = self.viewModel.issuersList![indexPath.row]
                let issuerCell = tableView.dequeueReusableCell(withIdentifier: "rowIssuerNib", for: indexPath as IndexPath) as! IssuerRowTableViewCell
                issuerCell.fillCell(issuer: issuer, bundle: self.bundle!)
                issuerCell.selectionStyle = .none
                issuerCell.addSeparatorLineToTop(width: Double(issuerCell.contentView.frame.width), y:Float(issuerCell.contentView.bounds.maxY))
                
                return issuerCell
            } else{
                let cardType = tableView.dequeueReusableCell(withIdentifier: "cardTypeNib", for: indexPath as IndexPath) as! CardTypeTableViewCell
                cardType.setPaymentMethod(paymentMethod: self.viewModel.paymentMethods[indexPath.row])
                cardType.addSeparatorLineToTop(width: Double(cardType.contentView.frame.width), y:Float(cardType.contentView.bounds.maxY))
                return cardType
            }
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if (indexPath.section == 2){
            self.showLoading()
            if self.viewModel.hasIssuer(){
                let payerCost : PayerCost = self.viewModel.payerCosts![(indexPath as NSIndexPath).row]
                self.viewModel.callbackPayerCost!(payerCost)
            } else if self.viewModel.hasPaymentMethod(){
                let issuer : Issuer = self.viewModel.issuersList![(indexPath as NSIndexPath).row]
                self.viewModel.callbackIssuer!(issuer)
            } else {
                let paymentMethod : PaymentMethod = self.viewModel.paymentMethods[(indexPath as NSIndexPath).row]
                self.viewModel.callbackPaymentMethod!(paymentMethod)
            }
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView){
        self.didScrollInTable(scrollView)
        let visibleIndexPaths = tableView.indexPathsForVisibleRows!
        for index in visibleIndexPaths {
            if index.section == 1  {
                if let card = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? PayerCostCardTableViewCell{
                    if tableView.contentOffset.y > 0{
                        if 44/tableView.contentOffset.y < 0.265 && !scrollingDown{
                            card.fadeCard()
                        } else{
                            card.cardView.alpha = 44/tableView.contentOffset.y;
                        }
                    }
                }
            }
        }
        
    }
    
    fileprivate func getInstallments(){
        let bin = self.viewModel.token?.getCardBin() ?? ""
        MPServicesBuilder.getInstallments(bin, amount: self.viewModel.amount, issuer: self.viewModel.issuer, paymentMethodId: self.viewModel.paymentMethods[0]._id, baseURL: MercadoPagoCheckoutViewModel.servicePreference.getDefaultBaseURL(),success: { (installments) -> Void in
            self.viewModel.installment = installments?[0]
            self.viewModel.payerCosts = installments![0].payerCosts
            if let payerCost = installments![0].payerCosts {
                let defaultPayerCost = self.viewModel.paymentPreference?.autoSelectPayerCost(payerCost)
                if defaultPayerCost != nil {
                    self.viewModel.callbackPayerCost!(defaultPayerCost)
                }
            }
            self.tableView.reloadData()
            self.hideLoading()
        }) { (error) -> Void in
            self.requestFailure(error)
        }
    }
    fileprivate func getIssuers(){
        MPServicesBuilder.getIssuers(self.viewModel.paymentMethods[0], bin: self.viewModel.token?.getCardBin(), baseURL: MercadoPagoCheckoutViewModel.servicePreference.getDefaultBaseURL(), success: { (issuers) -> Void in
            self.viewModel.issuersList = issuers
            if issuers.count == 1 {
                self.viewModel.callbackIssuer!(issuers[0])
                self.hideLoading()
            } else {
                self.tableView.reloadData()
                self.hideLoading()
            }
            
            
        }) { (error) -> Void in
            self.requestFailure(error)
        }
    }
    
    override func getNavigationBarTitle() -> String {
        return self.viewModel.getTitle()
    }
    
    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.hideLoading()
    }
    
}
open class CardAdditionalStepViewModel : NSObject {
    
    var payerCosts : [PayerCost]?
    var installment : Installment?
    var paymentMethods : [PaymentMethod]
    var token : CardInformationForm?
    var issuer: Issuer?
    var amount: Double!
    var paymentPreference: PaymentPreference?
    var issuersList:[Issuer]?
    var cardInformation : CardInformation?
    var callback : ((_ result: NSObject?) -> Void)?
    
    var callbackIssuer : ((_ issuer: Issuer?) -> Void)?
    var callbackPayerCost : ((_ payerCost: PayerCost?) -> Void)?
    var callbackPaymentMethod : ((_ paymentMethod: PaymentMethod?) -> Void)?
    
    init(cardInformation : CardInformation? = nil, paymentMethods : [PaymentMethod] ,issuer : Issuer?, token : CardInformationForm?, amount: Double?, paymentPreference: PaymentPreference?,installment: Installment?, callback: ((_ payerCost: NSObject?)->Void)? ){
        self.paymentMethods = paymentMethods
        self.payerCosts = installment?.payerCosts
        self.installment = installment
        self.token = token
        self.amount = amount
        self.issuer = issuer
        self.paymentPreference = paymentPreference
        self.cardInformation = cardInformation
        self.callback = callback
    }
    func numberOfPayerCost() -> Int{
        if hasIssuer(){
            return (self.installment?.numberOfPayerCostToShow(self.paymentPreference?.maxAcceptedInstallments)) ?? 0
        }else if hasPaymentMethod(){
            return (issuersList?.count) ?? 0
        } else {
            return paymentMethods.count
        }
    }
    func getTitle() -> String{
        if hasIssuer() {
            return "¿En cuántas cuotas?".localized
        } else if hasPaymentMethod(){
            return "¿Quién emitió tu tarjeta?".localized
        } else {
            return "¿Qué tipo de tarjeta es?".localized
        }
    }
    func hasIssuer()-> Bool{
        if (self.cardInformation != nil) {
            return !self.cardInformation!.isIssuerRequired()
        }
        return (issuer != nil || (token != nil && !token!.isIssuerRequired()))
    }
    func hasPaymentMethod()->Bool{
        if (paymentMethods.count)>1{
            return false
        } else {
            return true
        }
    }
    func getCardCellHeight() -> CGFloat {
        return UIScreen.main.bounds.width*0.50
    }
    func gerRowCellHeight() -> CGFloat {
        if hasIssuer() {
            return 60
        } else {
            return 80
        }
    }

}
