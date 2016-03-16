//
//  UIViewController.swift
//  InAppPurchase
//
//  Created by Christian Otkjær on 16/03/16.
//  Copyright © 2016 Christian Otkjær. All rights reserved.
//

import UIKit
import UserInterface

extension UIViewController
{
    public func presentPurchaseAlert(productManager: ProductManager, productIdentifier: String, completion: (() -> ())?)
    {
        let alert : UIAlertController
        
        if let product = productManager.productWithIdentifier(productIdentifier)
        {
            alert = UIAlertController(title: product.localizedTitle, message: product.localizedDescription, preferredStyle: .Alert)
            
            alert.addAction(UIAlertAction(title: product.localizedPrice, style: .Default, handler: { (action) -> Void in
                
                do
                {
                    try product.purchase()
                }
                catch let e as NSError
                {
                    e.presentAsAlert()
                }
                
            }))
            
            alert.addAction(UIAlertAction(title: UIKitLocalizedString("Cancel"), style: .Cancel, handler: nil))
        }
        else
        {
            alert = UIAlertController(title: "Error?", message: "Unknown product \"\(productIdentifier)\"", preferredStyle: .Alert)
            
            alert.addAction(UIAlertAction(title: UIKitLocalizedString("Done"), style: .Cancel, handler: nil))
        }
        
        presentViewController(alert, animated: true, completion: completion)
    }
}

