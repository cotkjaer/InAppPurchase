//
//  UIViewController.swift
//  InAppPurchase
//
//  Created by Christian Otkjær on 16/03/16.
//  Copyright © 2016 Christian Otkjær. All rights reserved.
//

import UIKit
import UserInterface
import StoreKit

private let DefaultPurchaseCompletion : ((SKProduct, ErrorType?)->()) = { debugPrint("productIdentifier: \($0)", $1 == nil ? "" : " - \($1)") }

extension UIViewController
{
    public func presentPurchaseAlert(
        productIdentifier: String,
        presentCompletion: (() -> ())? = nil,
        purchaseCompletion: ((SKProduct, ErrorType?)->())? = DefaultPurchaseCompletion
        )
    {
        let alert : UIAlertController
        
        if let product = SKProduct.productWithIdentifier(productIdentifier)
        {
            guard product.purchaseStatus != .Purchased else { purchaseCompletion?(product, nil); return }
            
            alert = UIAlertController(title: product.localizedTitle, message: product.localizedDescription, preferredStyle: .Alert)
            
            alert.addAction(UIAlertAction(title: product.localizedPrice, style: .Default, handler: { (action) -> Void in
                
                product.purchase({ purchaseCompletion?(product, $0) })
                
            }))

            alert.addAction(UIAlertAction(title: UIKitLocalizedString("Cancel"), style: .Cancel, handler: nil))
        }
        else
        {
            alert = UIAlertController(title: "Error?", message: "Unknown product \"\(productIdentifier)\"", preferredStyle: .Alert)
            
            alert.addAction(UIAlertAction(title: UIKitLocalizedString("Done"), style: .Cancel, handler: nil))
        }
        
        presentViewController(alert, animated: true, completion: presentCompletion)
    }
}

