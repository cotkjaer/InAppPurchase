//
//  ProductViewController.swift
//  InAppPurchase
//
//  Created by Christian Otkjær on 16/03/16.
//  Copyright © 2016 Christian Otkjær. All rights reserved.
//

import UIKit
import StoreKit

public class ProductViewController: UIViewController, ProductsViewController
{
    public var productIdentifier : String?
    
    public var productsDelegate : ProductsViewControllerDelegate?
    
    private var info : ProductInfo { return SKProduct.localizedInfoForProdutWithIdentifier(productIdentifier) }
    
    // MARK: - Lifecycle
    
    public override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        refreshUI()
    }
    
    // MARK: - UI

    // MARK: Purchase Button
    
    @IBOutlet weak var purchaseBarButton: UIBarButtonItem?
    @IBOutlet weak var purchaseButton: UIButton?
    
    @IBAction func purchaseButtonPressed()
    {
        if let product = SKProduct.productWithIdentifier(info.identifier)
        {
            product.purchase { ($0 as? NSError)?.presentAsAlert(); self.refreshUI(animated: true) }
        }
        else
        {
            SKProduct.fetchProduct(productIdentifier)
                { (products, error) -> () in
                    
                    self.presentErrorAsAlert(error as? NSError)
                    
                    if let product = products.find({ $0.productIdentifier == self.productIdentifier })
                    {
                        product.purchase {
                            self.presentErrorAsAlert($0 as? NSError)
                            self.refreshUI(animated: true)
                        }
                    }
                    
                    self.refreshUI(animated: true)
            }
        }
    }
    
    func refreshPurchaseButton(animated animated: Bool = false)
    {
        let enable : Bool
        
        switch info.status
        {
        case .Purchased, .Purchasing, .Deferred:
            enable = false
            
        case .None, .Failed:
            enable = true
        }
        
        let enabled = enable
        
        purchaseButton?.enabled = enabled
        purchaseBarButton?.enabled = enabled
    }

    // MARK: Cancel Button
    
    @IBOutlet weak var cancelBarButton: UIBarButtonItem?
    @IBOutlet weak var cancelButton: UIButton?
    
    @IBAction func cancelButtonPressed()
    {
        productsDelegate?.productsControllerCancelled(self)
    }
    
    // MARK: Restore Button
    
    @IBOutlet weak var restorePurchasesBarButton: UIBarButtonItem?
    @IBOutlet weak var restorePurchasesButton: UIButton?
    
    @IBAction func restorePurchasesButtonPressed()
    {
        SKProduct.restoreProducts { (productIndentifiers, error) -> () in
            self.presentErrorAsAlert(error as? NSError)
            self.refreshUI(animated: true)
        }
    }

    func refreshRestorePurchasesButton(animated animated: Bool = false)
    {
        let enabled = SKProduct.localizedInfoForProdutWithIdentifier(productIdentifier).status != .Purchased
        
        restorePurchasesButton?.enabled = enabled
        restorePurchasesBarButton?.enabled = enabled
    }
    
    // MARK: Refresh
    
    func refreshUI(animated animated: Bool = false)
    {
        refreshRestorePurchasesButton(animated: animated)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
}
