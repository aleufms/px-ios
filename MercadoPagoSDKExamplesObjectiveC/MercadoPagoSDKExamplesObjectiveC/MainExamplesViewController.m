//
//  MainExamplesViewController.m
//  MercadoPagoSDKExamplesObjectiveC
//
//  Created by Maria cristina rodriguez on 1/7/16.
//  Copyright © 2016 MercadoPago. All rights reserved.
//

#import "MainExamplesViewController.h"
#import "ExampleUtils.h"
#import "CustomTableViewCell.h"
#import "SubeTableViewCell.h"
#import "DineroEnCuentaTableViewCell.h"
#import "CustomItemTableViewCell.h"

@import MercadoPagoSDK;


@implementation MainExamplesViewController



- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)checkoutFlow:(id)sender {
    
    // Setear DecorationPreference
    DecorationPreference *decorationPreference = [[DecorationPreference alloc] initWithBaseColor:[UIColor greenColor] fontName:@"fontName" fontLightName:@"fontName"];
    [MercadoPagoCheckout setDecorationPreference:decorationPreference];
    
    // Setear ServicePreference
    
    ServicePreference * servicePreference = [[ServicePreference alloc] init];
    
    //    NSDictionary *extraParams = @{
    //                              @"merchant_access_token" : @"mla-cards-data" };
    //    [servicePreference setCreatePaymentWithBaseURL:@"https://private-0d59c-mercadopagoexamples.apiary-mock.com" URI:@"/create_payment" additionalInfo:extraParams];
    //
    //    [servicePreference setGetCustomerWithBaseURL:@"https://www.mercadopago.com" URI:@"/checkout/examples/getCustomer" additionalInfo:extraParams];
    
    [MercadoPagoCheckout setServicePreference:servicePreference];
    
    
    // Setear el idioma de la aplicación
    [MercadoPagoContext setLanguageWithLanguage:"es"];
    
    
    // Setear una preferencia hecha a mano
    Item *item = [[Item alloc] initWith_id:@"itemId" title:@"item title" quantity:100 unitPrice:10 description:nil currencyId:@"ARS"];
    Item *item2 = [[Item alloc] initWith_id:@"itemId2" title:@"item title 2" quantity:2 unitPrice:2 description:@"item description" currencyId:@"ARS"];
    Payer *payer = [[Payer alloc] initWith_id:@"payerId" email:@"payer@email.com" type:nil identification:nil];
    
    NSArray *items = [NSArray arrayWithObjects:item2, item2, nil];
    
    PaymentPreference *paymentExclusions = [[PaymentPreference alloc] init];
    paymentExclusions.excludedPaymentTypeIds = [NSSet setWithObjects:@"atm", @"ticket", nil];
    paymentExclusions.defaultInstallments = 1;
    
    self.pref = [[CheckoutPreference alloc] initWithItems:items payer:payer paymentMethods:nil];
    
    self.pref.paymentPreference = paymentExclusions;
    
    
    // Setear celdas custom para RyC
    
    CustomTableViewCell *cargaSubeCell = [[[NSBundle mainBundle] loadNibNamed:@"CustomTableViewCell" owner:self options:nil] firstObject];
    cargaSubeCell.label.text = @"Carga SUBE";
    [cargaSubeCell.button setTitle:@"Cambiar" forState:UIControlStateNormal];
    [cargaSubeCell.button addTarget:self action:@selector(invokeCallback:) forControlEvents:UIControlEventTouchUpInside];
    MPCustomCell *customCargaSube = [[MPCustomCell alloc] initWithCell:cargaSubeCell];
    self.customCell = customCargaSube;
    
    // Setear Revisa y confima Preference
    
    ReviewScreenPreference *reviewPreference = [[ReviewScreenPreference alloc] init];
    [reviewPreference setTitleWithTitle:@"Recarga tu SUBE"];
    [reviewPreference setProductsDetailWithProductsTitle:@"Carga SUBE"];
    [reviewPreference setConfirmButtonTextWithConfirmButtonText:@"Confirmar recarga"];
    [reviewPreference setCancelButtonTextWithCancelButtonText:@"Cancelar recarga"];
    //[ReviewScreenPreference addCustomItemCellWithCustomCell:customCargaSube];
    
    [ReviewScreenPreference setAddionalInfoCellsWithCustomCells:[NSArray arrayWithObjects:customCargaSube, nil]];
    
    [MercadoPagoCheckout setReviewScreenPreference:reviewPreference];
    
    
    // Celdas custom de Payment Result
    
    SubeTableViewCell *subeCell = [[[NSBundle mainBundle] loadNibNamed:@"SubeTableViewCell" owner:self options:nil] firstObject];
    MPCustomCell *subeCongrats = [[MPCustomCell alloc] initWithCell:subeCell];
    
    DineroEnCuentaTableViewCell *dineroEnCuenta = [[[NSBundle mainBundle] loadNibNamed:@"DineroEnCuentaTableViewCell" owner:self options:nil] firstObject];
    [dineroEnCuenta.button addTarget:self action:@selector(invokeCallbackPaymentResult:) forControlEvents:UIControlEventTouchUpInside];
    MPCustomCell *dineroEnCuentaCustom = [[MPCustomCell alloc] initWithCell:dineroEnCuenta];
    self.dineroEnCuentaCell = dineroEnCuentaCustom;
    
    // Setear la paymentResultPreference
    PaymentResultScreenPreference *resultPreference = [[PaymentResultScreenPreference alloc]init];
    [resultPreference setPendingTitleWithTitle:@"¡Pagaste la recarga de SUBE de $50!"];
    [resultPreference setExitButtonTitleWithTitle:@"Ir a Actividad"];
    [resultPreference setPendingContentTextWithText:@"Se acreditará en un momento"];
    [resultPreference setPendingHeaderIconWithName:@"iconoPagoOffline" bundle:[NSBundle mainBundle]];
    [resultPreference setApprovedTitleWithTitle:@"¡Listo, recargaste el celular"];
    [resultPreference setPendingContentTitleWithTitle:@"Para acreditar tu recarga"];
    //[resultPreference disableRejectdSecondaryExitButton];
    [resultPreference setRejectedTitleWithTitle:@"No pudimos hacer la recarga"];
    [resultPreference setRejectedSubtitleWithSubtitle:@"Movistar no esta disponible ahora"];
    [resultPreference setRejectedIconSubtextWithText:@"Uppss..."];
    [resultPreference setRejectedContentTextWithText:@"Vuelve más tarde"];
    [resultPreference setRejectedContentTitleWithTitle:@"¿Qué hago?"];
    //    [resultPreference disableRejectedContentTitle];
    //    [resultPreference disableRejectedContentText];
    //    [resultPreference setRejectedSecondaryExitButtonWithCallback:^(PaymentResult * paymentResult) {
    //        NSLog(@"%@", paymentResult.status);
    //    } text:@"Ir a mi activdad"];
    //    [resultPreference disablePendingContentText];
    //    [resultPreference disableChangePaymentMethodOptionButton];
    //    [resultPreference setPendingSecondaryExitButtonWithCallback:^(PaymentResult * paymentResult) {
    //        NSLog(@"%@", paymentResult.status);
    //        [self.navigationController popToRootViewControllerAnimated:NO];
    //    } text:@"Ir a mi actividad"];
    //    [resultPreference setApprovedSecondaryExitButtonWithCallback:^(PaymentResult * paymentResult) {
    //        NSLog(@"%@", paymentResult.status);
    //        [self.navigationController popToRootViewControllerAnimated:NO];
    //    } text:@"Ir a mi actividad"];
    
    
    // Agregar celdas custom
    
    [PaymentResultScreenPreference setCustomPendingCellsWithCustomCells:[NSArray arrayWithObjects:subeCongrats, nil]];
    [PaymentResultScreenPreference setCustomsApprovedCellWithCustomCells:[NSArray arrayWithObjects:dineroEnCuentaCustom, nil]];

    [MercadoPagoCheckout setPaymentResultScreenPreference:resultPreference];
    
    
    //Agregar un paymentDataCallBack que recarge RyC
    
    //    [MercadoPagoCheckout setPaymentDataCallbackWithPaymentDataCallback: ^(PaymentData *paymentData) {
    //        NSLog(@"%@", paymentData.paymentMethod._id);
    //        NSLog(@"%@", paymentData.token._id);
    //        NSLog(@"%ld", paymentData.payerCost.installments);
    //
    //        ReviewScreenPreference *reviewPreferenceUpdated = [[ReviewScreenPreference alloc] init];
    //        [reviewPreferenceUpdated setTitleWithTitle:@"Updated"];
    //        //[ReviewScreenPreference addCustomItemCellWithCustomCell:customCargaSube];
    //        //[ReviewScreenPreference addAddionalInfoCellWithCustomCell:customCargaSube];
    //        [MercadoPagoCheckout setReviewScreenPreference:reviewPreferenceUpdated];
    //        UIViewController *vc = [[[MercadoPagoCheckout alloc] initWithCheckoutPreference:self.pref paymentData:paymentData navigationController:self.navigationController] getRootViewController];
    //        //[self.navigationController popToRootViewControllerAnimated:NO];
    //    }];
    
    
    //Entrar a RyC directo
    
    /*PaymentMethod *pm = [[PaymentMethod alloc] init];
     pm._id = @"visa";
     pm.paymentTypeId = @"credit_card";
     pm.name = @"visa";
     
     
     PaymentData *pd = [[PaymentData alloc] init];
     pd.paymentMethod = pm;
     
     pd.token = [[Token alloc] initWith_id:@"id" publicKey:@"pk" cardId:@"card" luhnValidation:nil status:nil usedDate:nil cardNumberLength:nil creationDate:nil lastFourDigits:nil firstSixDigit:@"123456" securityCodeLength:3 expirationMonth:11 expirationYear:2012 lastModifiedDate:nil dueDate:nil cardHolder:nil];
     pd.token.lastFourDigits = @"7890";
     pd.payerCost = [[PayerCost alloc] initWithInstallments:3 installmentRate:10 labels:nil minAllowedAmount:10 maxAllowedAmount:200 recommendedMessage:@"sarsa" installmentAmount:100 totalAmount:200];
     
     pd.issuer = [[Issuer alloc] init];
     pd.issuer._id = [NSNumber numberWithInt:200];;
     
     
     PaymentResult *paymentResult = [[PaymentResult alloc] initWithStatus:@"approved" statusDetail:@"approved" paymentData:pd siteId:@"MLA" payerEmail:nil id:nil amount:50.0 statementDescription:nil];*/
    
    //Callback que devuelve un payment
    
//    [MercadoPagoCheckout setPaymentCallbackWithPaymentCallback:^(Payment * payment) {
//        NSLog(@"%@", payment._id);
//    }];
    
    // Callback que no devuelve nada
    
//    [MercadoPagoCheckout setCallbackWithCallback:^{
//        NSLog(@"Se termino el flujo");
//    }];
    
    
    CheckoutPreference * pref = [[CheckoutPreference alloc] initWith_id: @"150216849-68645cbb-dfe6-4410-bfd6-6e5aa33d8a33"];
    //    UIViewController *vc = [[[MercadoPagoCheckout alloc] initWithCheckoutPreference:pref paymentData:pd navigationController:self.navigationController] getRootViewController];
    

    [[[MercadoPagoCheckout alloc] initWithCheckoutPreference:pref paymentData:nil navigationController:self.navigationController paymentResult:nil] start];

    //NSLog(vc);
    
    
    
    
    //[[[MercadoPagoCheckout alloc] initWithCheckoutPreference:pref paymentData:pd navigationController:self.navigationController] start];
    //[[MercadoPagoCheckout alloc] initWithCheckoutPrefence:<#(CheckoutPreference * _Nonnull)#> navigationController:<#(UINavigationController * _Nonnull)#>
    //[servicePreference setCreatePaymentWithBaseURL:@"baseUrl" URI:@"paymentUri" additionalInfo:extraParams];
    // [MercadoPagoCheckout setServicePreference:servicePreference];
    
}

-(void)invokeCallback:(MPCustomCell *)button {
    
    [[self.customCell getDelegate] invokeCallbackWithPaymentDataWithRowCallback:^(PaymentData *paymentData) {
        NSLog(@"%@", paymentData.paymentMethod._id);
        NSLog(@"%@", paymentData.token._id);
        NSLog(@"%ld", paymentData.payerCost.installments);
        
        // Mostrar modal
        NSArray *currentViewControllers = self.navigationController.viewControllers;
        
        // Cuando retorna de modal
        ReviewScreenPreference *reviewPreferenceUpdated = [[ReviewScreenPreference alloc] init];
        [reviewPreferenceUpdated setTitleWithTitle:@"Updated"];
        [MercadoPagoCheckout setReviewScreenPreference:reviewPreferenceUpdated];
        
        //        UIViewController *vc = [[[MercadoPagoCheckout alloc] initWithCheckoutPreference:self.pref paymentData:paymentData navigationController:self.navigationController] getRootViewController];
        //
        [self.mpCheckout updateReviewAndConfirm];
        
    }];
}

-(void)invokeCallbackPaymentResult:(MPCustomCell *)button {
    
    [[self.dineroEnCuentaCell getDelegate] invokeCallbackWithPaymentResultWithRowCallback:^(PaymentResult *paymentResult) {
        NSLog(@"%@", paymentResult.status);
        [self.navigationController popToRootViewControllerAnimated:NO];
    }];
}

@end
