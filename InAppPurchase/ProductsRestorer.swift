//
//  ProductsRestorer.swift
//  InAppPurchase
//
//  Created by Christian Otkjær on 17/03/16.
//  Copyright © 2016 Christian Otkjær. All rights reserved.
//

import StoreKit
import Error

internal class ProductsRestorer: NSObject, PaymentQueueHandlerRestoreObserver
{
    // MARK: - Public
    
    internal static func restoreProducts(completion: ((Set<String>, ErrorType?)->())? = nil)
    {
        if restorer == nil
        {
            restorer = ProductsRestorer(completion: { restorer = nil; completion?($0,$1) } )
            restorer?.start()
        }
        else
        {
            completion?([], NSError(domain: "In-App Purchase", code: 2, description: "Already Restoring Products"))
        }
    }
    
    // MARK: - private
    
    private static var restorer : ProductsRestorer?
    
    private init(completion: ((Set<String>, ErrorType?) -> ()))
    {
        super.init()
        
        self.completionHandler = completion
    }

    private var completionHandler : ((Set<String>, ErrorType?) -> ()) = { _ in }

    private var restoredProductIdentifiers = Set<String>()
    
    private var queue : SKPaymentQueue?
    
    private var handler = PaymentQueueHandler.defaultHandler()
    
    internal func start()
    {
        handler.addObserver(self)
        handler.queue.restoreCompletedTransactions()
    }
    
    private func stop(error: ErrorType? = nil)
    {
        handler.removeObserver(self)
        completionHandler(restoredProductIdentifiers, error)
    }
    
    //MARK: - Observer

    func handlerDidUpdateTransactions(handler: PaymentQueueHandler)
    {
        
    }
    
    func handlerWillUpdateTransactions(handler: PaymentQueueHandler) {
        
    }
    
    func handleTransaction(transaction: SKPaymentTransaction) -> Bool
    {
        guard transaction.transactionState == .Restored else { return false }
        
        restoredProductIdentifiers.insert(transaction.payment.productIdentifier)
        
        return true
    }
    
    func handlerDidRestoreCompletedTransactions(error: ErrorType?)
    {
        stop(error)
    }
}
