//
//  ProductsPurchaser.swift
//  InAppPurchase
//
//  Created by Christian Otkjær on 17/03/16.
//  Copyright © 2016 Christian Otkjær. All rights reserved.
//

import StoreKit

private var purchasersByProductIdentifier = Dictionary<String, ProductPurchaser>()


internal class ProductPurchaser: NSObject, PaymentQueueHandlerObserver
{
    // MARK: - Public
    
    internal static func purchase(product: SKProduct, completion: (ErrorType?->())?)
    {
        if product.purchaseStatus == .Purchased
        {
            completion?(nil)
        }
        else if purchasersByProductIdentifier[product.productIdentifier] == nil
        {
            let purchaser = ProductPurchaser(product: product)
                {
                    purchasersByProductIdentifier[$0.productIdentifier] = nil
                    completion?($1)
            }
            
            purchasersByProductIdentifier[product.productIdentifier] = purchaser
            purchaser.start()
        }
        else
        {
            completion?(NSError(domain: "In-App Purchase", code: 11, description: "Purchase already in progress"))
        }
    }
    
    internal func start()
    {
        if SKPaymentQueue.canMakePayments()
        {
            queueHandler.addObserver(self)
            queueHandler.queue.addPayment(SKPayment(product: product))
        }
        else
        {
            product.updatePurchaseStatus(SKPaymentTransactionState.Failed)
            completion(product, NSError(domain: "In-App Purchase", code: 1, description: "Cannot make payment", reason: "Payments are disables in Settings"))
        }
    }
    
    // MARK: - Private
    
    private let product : SKProduct
    
    private let completion : ((SKProduct, ErrorType?)->())
    private let queueHandler = PaymentQueueHandler.defaultHandler()
    
    private var bestTransaction : SKPaymentTransaction? = nil
    
    private init(product: SKProduct, completion: (SKProduct, ErrorType?)->())
    {
        self.product = product
        self.completion = completion
    }
    
    //MARK: - Transaction handling
    
    func handlerWillUpdateTransactions(handler: PaymentQueueHandler)
    {
        bestTransaction = nil
    }
    
    func handleTransaction(transaction: SKPaymentTransaction) -> Bool
    {
        guard transaction.payment.productIdentifier == product.productIdentifier else { return false }
        
        if bestTransaction == nil || bestTransaction?.transactionState < transaction.transactionState
        {
            bestTransaction = transaction
        }
        
        return true
    }
    
    func handlerDidUpdateTransactions(handler: PaymentQueueHandler)
    {
        var error : NSError?
        
        switch product.purchaseStatus
        {
        case .Deferred:
            error = NSError(domain: "In-App Purchase", code: 12, description: "Waiting for purchase to be approved")
            
        case .Failed, .None:
            error = bestTransaction?.error ?? NSError(domain: "In-App Purchase", code: 10, description: "Purchase failed inexplically")

        case .Purchasing:
            error = NSError(domain: "In-App Purchase", code: 11, description: "Purchase is still ongoing")

        case .Purchased:
            error = nil
        }
        
        completion(product, error)
    }
}

