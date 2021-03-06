 //
//  PaymentVaultViewController.swift
//  MercadoPagoSDK
//
//  Created by Maria cristina rodriguez on 15/1/16.
//  Copyright © 2016 MercadoPago. All rights reserved.
//

import UIKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


open class PaymentVaultViewController: MercadoPagoUIScrollViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout{
    
    @IBOutlet weak var collectionSearch: UICollectionView!

    static public var maxCustomerPaymentMethods = 3
    
    
    override open var screenName : String { get { return "PAYMENT_METHOD_SEARCH" } }
    
    
    static let VIEW_CONTROLLER_NIB_NAME : String = "PaymentVaultViewController"
    
    var merchantBaseUrl : String!
    var merchantAccessToken : String!
    var publicKey : String!
    var currency : Currency!
    
    
    
    var defaultInstallments : Int?
    var installments : Int?
    var viewModel : PaymentVaultViewModel!
    
    var bundle = MercadoPago.getBundle()
    
    var titleSectionReference : PaymentVaultTitleCollectionViewCell!
    
    fileprivate var tintColor = true
    fileprivate var loadingGroups = true
    
    fileprivate let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
    
    fileprivate var defaultOptionSelected = false;
    
    
    public init(amount : Double, paymentPreference : PaymentPreference?, callback: @escaping (_ paymentMethod: PaymentMethod, _ token: Token?, _ issuer: Issuer?, _ payerCost: PayerCost?) -> Void, callbackCancel : ((Void) -> Void)? = nil) {
        super.init(nibName: PaymentVaultViewController.VIEW_CONTROLLER_NIB_NAME, bundle: bundle)
        self.initCommon()
        self.initViewModel(amount, paymentPreference : paymentPreference, callback: callback)
        
        self.callbackCancel = callbackCancel
        
    }
    
    public init(amount : Double, paymentPreference : PaymentPreference? = nil, paymentMethodSearch : PaymentMethodSearch, tintColor : Bool = false,
                callback: @escaping (_ paymentMethod: PaymentMethod, _ token: Token?, _ issuer: Issuer?, _ payerCost: PayerCost?) -> Void,
                callbackCancel : ((Void) -> Void)? = nil) {
        super.init(nibName: PaymentVaultViewController.VIEW_CONTROLLER_NIB_NAME, bundle: bundle)
        self.initCommon()
        self.initViewModel(amount, paymentPreference: paymentPreference, customerPaymentMethods: paymentMethodSearch.customerPaymentMethods, paymentMethodSearchItem : paymentMethodSearch.groups, paymentMethods: paymentMethodSearch.paymentMethods, callback: callback)
        
        self.callbackCancel = callbackCancel
        
    }
    
    internal init(amount: Double, paymentPreference : PaymentPreference?, paymentMethodSearchItem : [PaymentMethodSearchItem]? = nil, paymentMethods: [PaymentMethod], title: String? = "", tintColor : Bool = false, callback: @escaping (_ paymentMethod: PaymentMethod, _ token: Token?, _ issuer: Issuer?, _ payerCost: PayerCost?) -> Void, callbackCancel : ((Void) -> Void)? = nil) {
        
        super.init(nibName: PaymentVaultViewController.VIEW_CONTROLLER_NIB_NAME, bundle: bundle)
        
        self.initCommon()
        self.initViewModel(amount, paymentPreference: paymentPreference, paymentMethodSearchItem: paymentMethodSearchItem, paymentMethods: paymentMethods, callback : callback)
        
        self.title = title
        self.tintColor = tintColor
        
        self.callbackCancel = callbackCancel
        
        
    }
    
    fileprivate func initCommon(){
        
        self.merchantBaseUrl = MercadoPagoContext.baseURL()
        self.merchantAccessToken = MercadoPagoContext.merchantAccessToken()
        self.publicKey = MercadoPagoContext.publicKey()
        self.currency = MercadoPagoContext.getCurrency()
    }
    

    
    fileprivate func initViewModel(_ amount : Double, paymentPreference : PaymentPreference?, customerPaymentMethods: [CardInformation]? = nil, paymentMethodSearchItem : [PaymentMethodSearchItem]? = nil, paymentMethods: [PaymentMethod]? = nil, callback: @escaping (_ paymentMethod: PaymentMethod, _ token: Token?, _ issuer: Issuer?, _ payerCost: PayerCost?) -> Void){
        self.viewModel = PaymentVaultViewModel(amount: amount, paymentPrefence: paymentPreference)
        self.viewModel.controller = self
        self.viewModel.setPaymentMethodSearch(paymentMethods: paymentMethods, paymentMethodSearchItems: paymentMethodSearchItem, customerPaymentMethods : customerPaymentMethods)
        self.viewModel.callback = callback
    }
    
    
    required  public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        var upperFrame = self.collectionSearch.bounds
        upperFrame.origin.y = -upperFrame.size.height + 10;
        upperFrame.size.width = UIScreen.main.bounds.width
        let upperView = UIView(frame: upperFrame)
        upperView.backgroundColor = UIColor.primaryColor()
        collectionSearch.addSubview(upperView)
        
        if self.title == nil || self.title!.isEmpty {
            self.title = "¿Cómo quiéres pagar?".localized
        }
        
        self.registerAllCells()
        
        if callbackCancel == nil {
            self.callbackCancel = {(Void) -> Void in
                if self.navigationController?.viewControllers[0] == self {
                    self.dismiss(animated: true, completion: {
                        
                    })
                } else {
                    self.navigationController!.popViewController(animated: true)
                }
            }
        } else {
            self.callbackCancel = callbackCancel
        }

       self.collectionSearch.backgroundColor = UIColor.px_white()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.hideNavBar()
        
        self.navigationItem.leftBarButtonItem!.action = #selector(invokeCallbackCancel)
        self.navigationController!.navigationBar.shadowImage = nil
        self.extendedLayoutIncludesOpaqueBars = true
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.getCustomerCards()
        self.hideNavBarCallback = self.hideNavBarCallbackDisplayTitle()
        if self.loadingGroups {
            let temporalView = UIView.init(frame: CGRect(x: 0, y: navBarHeigth + statusBarHeigth, width: self.view.frame.size.width, height: self.view.frame.size.height))
            temporalView.backgroundColor?.withAlphaComponent(0)
            temporalView.isUserInteractionEnabled = false
            self.view.addSubview(temporalView)
            self.loadingInstance = LoadingOverlay.shared.showOverlay(temporalView, backgroundColor: UIColor.primaryColor())
            self.view.bringSubview(toFront: self.loadingInstance!)
        }
        
    }



    fileprivate func cardFormCallbackCancel() -> ((Void) -> (Void)) {
        return { Void -> (Void) in
            if self.viewModel.getDisplayedPaymentMethodsCount() > 1 {
                self.navigationController!.popToViewController(self, animated: true)
            } else {
                self.loadingGroups = false
              //  self.navigationController!.popToViewController(self, animated: true)
                self.callbackCancel!()
            }
        }
    }
    
    fileprivate func getCustomerCards(){
       
        if self.viewModel!.shouldGetCustomerCardsInfo() {
            MerchantServer.getCustomer({ (customer: Customer) -> Void in
                self.viewModel.customerId = customer._id
                self.viewModel.customerCards = customer.cards
                self.loadPaymentMethodSearch()
                
            }, failure: { (error: NSError?) -> Void in
                // It a Grupos igual
                self.loadPaymentMethodSearch()
            })
        } else {
            self.loadPaymentMethodSearch()
        }
    }
    
    fileprivate func hideNavBarCallbackDisplayTitle() -> ((Void) -> (Void)) {
        return { Void -> (Void) in
            if self.titleSectionReference != nil {
                self.titleSectionReference.fillCell()
            }
        }
    }

    
    fileprivate func loadPaymentMethodSearch(){
        
        if self.viewModel.currentPaymentMethodSearch == nil {
            MPServicesBuilder.searchPaymentMethods(self.viewModel.amount, defaultPaymenMethodId: self.viewModel.getPaymentPreferenceDefaultPaymentMethodId(), excludedPaymentTypeIds: viewModel.getExcludedPaymentTypeIds(), excludedPaymentMethodIds: viewModel.getExcludedPaymentMethodIds(), success: { (paymentMethodSearchResponse: PaymentMethodSearch) -> Void in
                if paymentMethodSearchResponse.customerPaymentMethods?.count == 0 && paymentMethodSearchResponse.groups.count == 0{
                    let error = MPSDKError(message: "Ha ocurrido un error".localized, messageDetail: "No se ha podido obtener los métodos de pago con esta preferencia".localized, retry: false)
                    self.displayFailure(error)
                }
                self.viewModel.setPaymentMethodSearchResponse(paymentMethodSearchResponse)
                
                self.loadPaymentMethodSearch()
                
            }, failure: { (error) -> Void in
                self.hideLoading()
                self.requestFailure(error, callback: {
                    self.navigationController!.dismiss(animated: true, completion: {})
                }, callbackCancel: {
                    self.invokeCallbackCancel()
                })
            })
            
        } else {
            self.hideLoading()
            if self.viewModel.currentPaymentMethodSearch.count == 1 && self.viewModel.currentPaymentMethodSearch[0].children.count > 0 {
                self.viewModel.currentPaymentMethodSearch = self.viewModel.currentPaymentMethodSearch[0].children
            }
            
            if  self.viewModel.hasOnlyGroupsPaymentMethodAvailable() {
                self.viewModel.optionSelected(self.viewModel.currentPaymentMethodSearch[0],navigationController: self.navigationController!, cancelPaymentCallback: self.cardFormCallbackCancel(), animated: false)
            } else if self.viewModel.hasOnlyCustomerPaymentMethodAvailable() {
                let customerCardSelected = self.viewModel.customerCards![0] as CardInformation
                if let nav = self.navigationController { self.viewModel.customerOptionSelected(customerCardSelected: customerCardSelected, navigationController: nav, visibleViewController: self) }
            } else {
                self.collectionSearch.delegate = self
                self.collectionSearch.dataSource = self
                self.collectionSearch.reloadData()
                self.loadingGroups = false
            }
        }
    }
    


    fileprivate func registerAllCells(){
   
        let collectionSearchCell = UINib(nibName: "PaymentSearchCollectionViewCell", bundle: self.bundle)
        self.collectionSearch.register(collectionSearchCell, forCellWithReuseIdentifier: "searchCollectionCell")
        
        let paymentVaultTitleCollectionViewCell = UINib(nibName: "PaymentVaultTitleCollectionViewCell", bundle: self.bundle)
        self.collectionSearch.register(paymentVaultTitleCollectionViewCell, forCellWithReuseIdentifier: "paymentVaultTitleCollectionViewCell")
        
    }
    
    override func getNavigationBarTitle() -> String {
        if self.titleSectionReference != nil {
            self.titleSectionReference.title.text = ""
        }
        return "¿Cómo quiéres pagar?".localized
    }
    
    open override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    open override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        //En caso de que el vc no sea root
        if (navigationController != nil && navigationController!.viewControllers.count > 1 && navigationController!.viewControllers[0] != self) || (navigationController != nil && navigationController!.viewControllers.count == 1) {
            if self.viewModel!.isRoot {
                self.callbackCancel!()
            }
            return true
        }
        return false
    }
   

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        if self.loadingGroups {
            return 0
        }
        return 2
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if indexPath.section == 1 {
         
            if self.viewModel.isCustomerPaymentMethodOptionSelected(indexPath.row) {
                let customerCardSelected = self.viewModel.customerCards![indexPath.row] as CardInformation
                CheckoutViewModel.CUSTOMER_ID = self.viewModel!.customerId ?? ""
                self.viewModel.customerOptionSelected(customerCardSelected: customerCardSelected, navigationController: self.navigationController!, visibleViewController: self)
            } else {
                let paymentSearchItemSelected = self.viewModel.getPaymentMethodOption(row: indexPath.row) as! PaymentMethodSearchItem
                collectionView.deselectItem(at: indexPath, animated: true)
                if (paymentSearchItemSelected.children.count > 0) {
                    let paymentVault = PaymentVaultViewController(amount: self.viewModel.amount, paymentPreference: self.viewModel.paymentPreference, paymentMethodSearchItem: paymentSearchItemSelected.children, paymentMethods : self.viewModel.paymentMethods, title:paymentSearchItemSelected.childrenHeader, callback: { (paymentMethod: PaymentMethod, token: Token?, issuer: Issuer?, payerCost: PayerCost?) -> Void in
                        self.viewModel.callback!(paymentMethod, token, issuer, payerCost)
                    })
                    paymentVault.viewModel!.isRoot = false
                    self.navigationController!.pushViewController(paymentVault, animated: true)
                } else {
                    self.showLoading()
                    self.viewModel.optionSelected(paymentSearchItemSelected, navigationController: self.navigationController!, cancelPaymentCallback: cardFormCallbackCancel())
                }
            }
        }
    
    }
    

    public func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        
        if (loadingGroups) {
            return 0
        }
        
        if (section == 0){
            return 1
        }
        
        return self.viewModel.getDisplayedPaymentMethodsCount()
        
    }
    

    public func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "searchCollectionCell",
                 
                                                      for: indexPath) as! PaymentSearchCollectionViewCell

        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "paymentVaultTitleCollectionViewCell",
                                                          
                                                          for: indexPath) as! PaymentVaultTitleCollectionViewCell
            self.titleSectionReference = cell
            titleCell = cell
            return cell
        } else {
            let paymentMethodToDisplay = self.viewModel.getPaymentMethodOption(row: indexPath.row)
            cell.fillCell(drawablePaymentOption: paymentMethodToDisplay)
        }
        return cell

    }
    
    fileprivate let itemsPerRow: CGFloat = 2
    
    var sectionHeight : CGSize?
    
    override func scrollPositionToShowNavBar () -> CGFloat {
        return titleCellHeight - navBarHeigth - statusBarHeigth
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        let paddingSpace = CGFloat(32.0)
        let availableWidth = view.frame.width - paddingSpace
        
        titleCellHeight = 82
        if indexPath.section == 0 {
            return CGSize(width : view.frame.width, height : titleCellHeight)
        }
        
       
        
        let widthPerItem = availableWidth / itemsPerRow
        return CGSize(width: widthPerItem, height: maxHegithRow(indexPath:indexPath)  )
    }
    
    private func maxHegithRow(indexPath: IndexPath) -> CGFloat{
        return self.calculateHeight(indexPath: indexPath, numberOfCells: self.viewModel.getDisplayedPaymentMethodsCount())
    }
    
    private func calculateHeight(indexPath : IndexPath, numberOfCells : Int) -> CGFloat {
        if numberOfCells == 0 {
            return 0
        }
        
        let section : Int
        let row = indexPath.row
        if row % 2 == 1{
            section = (row - 1) / 2
        }else{
            section = row / 2
        }
        let index1 = (section  * 2)
        let index2 = (section  * 2) + 1
        
        if index1 + 1 > numberOfCells {
            return 0
        }
        
        let height1 = heightOfItem(indexItem: index1)
        
        if index2 + 1 > numberOfCells {
            return height1
        }
        
        let height2 = heightOfItem(indexItem: index2)
        
        
        return height1 > height2 ? height1 : height2

    }
    
    func heightOfItem(indexItem : Int) -> CGFloat {
        return PaymentSearchCollectionViewCell.totalHeight(drawablePaymentOption : self.viewModel.getPaymentMethodOption(row: indexItem))
    }
    

    public func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        if section == 0 {
           return UIEdgeInsetsMake(8, 8, 0, 8)
        } else {
            return UIEdgeInsetsMake(0, 8, 8, 8)
        }
    }

    public func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView){
        self.didScrollInTable(scrollView)
    }
    
    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.hideLoading()
    }
    
 }



class PaymentVaultViewModel : NSObject {

    var amount : Double
    var paymentPreference : PaymentPreference?
    
    var customerCards : [CardInformation]?
    var paymentMethods : [PaymentMethod]!
    var currentPaymentMethodSearch : [PaymentMethodSearchItem]!
    var defaultPaymentOption : PaymentMethodSearchItem?
    var cards : [Card]?
    weak var controller : PaymentVaultViewController?
    
    var customerId : String?
    
    var callback : ((_ paymentMethod: PaymentMethod, _ token:Token?, _ issuer: Issuer?, _ payerCost: PayerCost?) -> Void)!
    
    internal var isRoot = true
    
    init(amount : Double, paymentPrefence : PaymentPreference?){
        self.amount = amount
        self.paymentPreference = paymentPrefence
    }
    
    func shouldGetCustomerCardsInfo() -> Bool {
        return MercadoPagoContext.isCustomerInfoAvailable() && self.isRoot && (self.customerCards == nil || self.customerCards?.count == 0)
    }
    
    func getCustomerPaymentMethodsToDisplayCount() -> Int {
        if (self.customerCards != nil && self.customerCards?.count > 0) {
            return (self.customerCards!.count <= PaymentVaultViewController.maxCustomerPaymentMethods ? self.customerCards!.count : PaymentVaultViewController.maxCustomerPaymentMethods)
        }
        return 0
        
    }
    
    func getPaymentMethodOption(row : Int) -> PaymentOptionDrawable {
        
        if (self.getCustomerPaymentMethodsToDisplayCount() > row) {
            return self.customerCards![row]
        }
        let indexInPaymentMethods = Array.isNullOrEmpty(self.customerCards) ? row : (row - self.getCustomerPaymentMethodsToDisplayCount())
        return self.currentPaymentMethodSearch[indexInPaymentMethods]
    }
 
    func getDisplayedPaymentMethodsCount() -> Int {
        let currentPaymentMethodSearchConunt = self.currentPaymentMethodSearch != nil ? self.currentPaymentMethodSearch.count : 0
        return self.getCustomerPaymentMethodsToDisplayCount() + currentPaymentMethodSearchConunt
    }
    
    func getCustomerCardRowHeight() -> CGFloat {
        return self.getCustomerPaymentMethodsToDisplayCount() > 0 ? CustomerPaymentMethodCell.ROW_HEIGHT : 0
    }
    
    func getExcludedPaymentTypeIds() -> Set<String>? {
        return (self.paymentPreference != nil) ? self.paymentPreference!.excludedPaymentTypeIds : nil
    }
    
    func getExcludedPaymentMethodIds() -> Set<String>? {
        return (self.paymentPreference != nil) ? self.paymentPreference!.excludedPaymentMethodIds : nil
    }
    
    func getPaymentPreferenceDefaultPaymentMethodId() -> String?{
        return (self.paymentPreference != nil) ? self.paymentPreference!.defaultPaymentMethodId : nil
    }
    
    func setPaymentMethodSearchResponse(_ paymentMethodSearchResponse : PaymentMethodSearch){
        self.setPaymentMethodSearch(paymentMethods: paymentMethodSearchResponse.paymentMethods, paymentMethodSearchItems: paymentMethodSearchResponse.groups, customerPaymentMethods : paymentMethodSearchResponse.customerPaymentMethods, defaultPaymentOption: paymentMethodSearchResponse.defaultOption)
    }
    

    func isCustomerPaymentMethodOptionSelected(_ row : Int) -> Bool {
        if (Array.isNullOrEmpty(self.customerCards)) {
            return false;
        }
        return (row < self.getCustomerPaymentMethodsToDisplayCount())
    }
    
    func setPaymentMethodSearch(paymentMethods : [PaymentMethod]? = nil, paymentMethodSearchItems : [PaymentMethodSearchItem]? = nil, customerPaymentMethods : [CardInformation]? = nil, defaultPaymentOption : PaymentMethodSearchItem? = nil) {

        self.paymentMethods = paymentMethods
        self.currentPaymentMethodSearch = paymentMethodSearchItems
        
        if let defaultPaymentOption = defaultPaymentOption {
            self.defaultPaymentOption = defaultPaymentOption
        }
        
        var currentCustomerCards = customerPaymentMethods
        if customerPaymentMethods != nil && customerPaymentMethods!.count > 0 {
            let accountMoneyAvailable = MercadoPagoContext.accountMoneyAvailable()
            if !accountMoneyAvailable {
                currentCustomerCards = customerPaymentMethods!.filter({ (element : CardInformation) -> Bool in
                    return element.getPaymentMethodId() != PaymentTypeId.ACCOUNT_MONEY.rawValue
                })
            }
            self.customerCards = currentCustomerCards
        }
        
        
    }
    
    func hasOnlyGroupsPaymentMethodAvailable() -> Bool {
        return (self.currentPaymentMethodSearch != nil && self.currentPaymentMethodSearch.count == 1 && Array.isNullOrEmpty(self.customerCards))
    }
    
    func hasOnlyCustomerPaymentMethodAvailable() -> Bool {
        return Array.isNullOrEmpty(self.currentPaymentMethodSearch) && !Array.isNullOrEmpty(self.customerCards) && self.customerCards?.count == 1
    }
    
    internal func optionSelected(_ paymentSearchItemSelected : PaymentMethodSearchItem, navigationController : UINavigationController, cancelPaymentCallback : @escaping ((Void) -> (Void)),animated: Bool = true) {
        
        switch paymentSearchItemSelected.type.rawValue {
        case PaymentMethodSearchItemType.PAYMENT_TYPE.rawValue:
            let paymentTypeId = PaymentTypeId(rawValue: paymentSearchItemSelected.idPaymentMethodSearchItem)
            
            if paymentTypeId!.isCard() {
                self.paymentPreference?.defaultPaymentTypeId = paymentTypeId.map { $0.rawValue }
                let cardFlow = MPFlowBuilder.startCardFlow(self.paymentPreference, amount: self.amount, paymentMethods : self.paymentMethods, callback: { (paymentMethod, token, issuer, payerCost) in
                    self.callback!(paymentMethod, token, issuer, payerCost)
                }, callbackCancel: {
                    cancelPaymentCallback()
                })
                
                navigationController.pushViewController(cardFlow.viewControllers[0], animated: true)
            } else {
                navigationController.pushViewController(MPStepBuilder.startPaymentMethodsStep(callback: {    (paymentMethod : PaymentMethod) -> Void in
                    self.callback!(paymentMethod, nil, nil, nil)
                }), animated: true)
            }
            break
        case PaymentMethodSearchItemType.PAYMENT_METHOD.rawValue:
            if paymentSearchItemSelected.idPaymentMethodSearchItem == PaymentTypeId.BITCOIN.rawValue {
                
            } else {
                // Offline Payment Method
                let offlinePaymentMethodSelected = Utils.findPaymentMethod(self.paymentMethods, paymentMethodId: paymentSearchItemSelected.idPaymentMethodSearchItem)
                self.callback!(offlinePaymentMethodSelected, nil, nil, nil)
            }
            break
        default:
            //TODO : HANDLE ERROR
            break
        }
    }
    
    internal func customerOptionSelected(customerCardSelected : CardInformation, navigationController : UINavigationController, visibleViewController : UIViewController){
        let paymentMethodSelected = Utils.findPaymentMethod(self.paymentMethods, paymentMethodId: customerCardSelected.getPaymentMethodId())
        if paymentMethodSelected.isAccountMoney() {
            self.callback!(paymentMethodSelected, nil, nil, nil)
        } else {
            customerCardSelected.setupPaymentMethod(paymentMethodSelected)
            customerCardSelected.setupPaymentMethodSettings(paymentMethodSelected.settings)
            if let controller = controller {
                controller.showLoading()
            }
            MPServicesBuilder.getInstallments(customerCardSelected.getFirstSixDigits(), amount: amount, issuer: customerCardSelected.getIssuer(), paymentMethodId: customerCardSelected.getPaymentMethodId(), success: { (installments) in
                self.controller?.hideLoading()
                let payerCostSelected = self.paymentPreference?.autoSelectPayerCost(installments![0].payerCosts)
                if(payerCostSelected == nil){
                    let cardFlow = MPFlowBuilder.startCardFlow(amount: self.amount, cardInformation : customerCardSelected, callback: { (paymentMethod,   token, issuer, payerCost) in
                        self.callback!(paymentMethod, token, issuer, payerCost)
                        }, callbackCancel: {
                            navigationController.popToViewController(visibleViewController, animated: true)
                    })
                    navigationController.pushViewController(cardFlow.viewControllers[0], animated: true)
                }else{
                    let secCode = MPStepBuilder.startSecurityCodeForm(paymentMethod: customerCardSelected.getPaymentMethod(), cardInfo: customerCardSelected) { (token) in
                        if String.isNullOrEmpty(token!.lastFourDigits) {
                            token!.lastFourDigits = customerCardSelected.getCardLastForDigits()
                        }
                        self.callback(customerCardSelected.getPaymentMethod(),token,customerCardSelected.getIssuer(),installments![0].payerCosts[0] as PayerCost)
                    }
                    navigationController.pushViewController(secCode, animated: false)
                }
                
                }, failure: { (error) in
                    self.controller?.hideLoading()
            })

        }

    }
    
}

