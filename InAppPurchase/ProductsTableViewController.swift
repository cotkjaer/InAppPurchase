//
//  ProductsTableViewController.swift
//  InAppPurchase
//
//  Created by Christian Otkjær on 16/03/16.
//  Copyright © 2016 Christian Otkjær. All rights reserved.
//

import Foundation
import StoreKit

// MARK: - Products Table View

// MARK: Cell

public class ProductsTableViewCell: UITableViewCell
{
    // MARK: - Init
    
    required public init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        setup()
    }
    
    override public func awakeFromNib()
    {
        super.awakeFromNib()
        setup()
    }
    
    func setup()
    {
        selectionStyle = .None
    }
    
    override public func setHighlighted(highlighted: Bool, animated: Bool)
    {
        
    }
}

// MARK: Controller

public class ProductsTableViewController: UITableViewController
{
    public var productIdentifiers = Set<String>() { didSet { updateData() } }
    
    public override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        refreshUI()
    }
    
    // MARK: - data
    
    var data = Array<Array<ProductInfo>>()
    
    func updateData()
    {
        data = [productIdentifiers.sort().flatMap{ SKProduct.localizedInfoForProdutWithIdentifier($0) }]
        tableView?.reloadData()
    }
    
    func infoForIndexPath(indexPath: NSIndexPath) -> ProductInfo?
    {
        return data.get(indexPath.section)?.get(indexPath.item)
    }
    
    // MARK: UITableViewDataSource
    
    override public func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }
    
    override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return data.count
    }
    
    private let CellReuseIdentifier = "Cell"
    
    func activityIndicator() -> UIActivityIndicatorView
    {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        activityIndicator.startAnimating()
        
        return activityIndicator
    }
    
    override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        guard let info = infoForIndexPath(indexPath) else { fatalError("could not get product info for indexPath \(indexPath)")}
        
        
        guard let cell = tableView.dequeueReusableCellWithIdentifier(CellReuseIdentifier, forIndexPath: indexPath) as? ProductsTableViewCell else { fatalError("could not get cell with identifier \(CellReuseIdentifier)") }
        
        cell.textLabel?.text = info.title
        cell.detailTextLabel?.text = info.description
        
        switch info.status
        {
        case .Deferred:
            cell.accessoryView = activityIndicator()
            
        case .Failed:
            cell.accessoryView = UILabel(text: NSLocalizedString("!", comment: "Purchase failed"), color: UIColor.redColor().darkerColor())
            
        case .Purchased:
            cell.accessoryType = .Checkmark
            
        case .Purchasing:
            cell.accessoryView = activityIndicator()
            
            /*
            case .PendingFetch:
            cell.accessoryView = activityIndicator()
            */
            
        case .None:
            cell.accessoryView = UILabel(text: info.price, color: UIColor.darkTextColor())
        }
        
        return cell
    }
    
    
    // MARK: UITableViewDelegate
    
    override public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        if let info = infoForIndexPath(indexPath)
        {
            if let product = SKProduct.productWithIdentifier(info.identifier)
            {
                product.purchase { ($0 as? NSError)?.presentAsAlert(); self.refreshUI(animated: true) }
            }
            else
            {
                SKProduct.fetchProducts(productIdentifiers)
                    { (products, error) -> () in
                        
                        self.presentErrorAsAlert(error as? NSError)
                        
                        if let product = products.find({ $0.productIdentifier == info.identifier })
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
    }
    
    // MARK: - Cancel Button
    
    @IBOutlet weak var cancelBarButton: UIBarButtonItem?
    @IBOutlet weak var cancelButton: UIButton?
    
    @IBAction func cancelButtonPressed()
    {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - Restore Button
    
    @IBOutlet weak var restorePurchasesBarButton: UIBarButtonItem?
    @IBOutlet weak var restorePurchasesButton: UIButton?
    
    @IBAction func restorePurchasesButtonPressed()
    {
        SKProduct.restoreProducts { (products, error) -> () in
            self.presentErrorAsAlert(error as? NSError)
            self.refreshUI(animated: true)
        }
    }
    
    // MARK: - UI
    
    func refreshUI(animated animated: Bool = false)
    {
        refreshTableView(animated: animated)
        refreshRestorePurchasesButton(animated: animated)
    }
    
    func refreshRestorePurchasesButton(animated animated: Bool = false)
    {
        let enabled = productIdentifiers.contains({ SKProduct.localizedInfoForProdutWithIdentifier($0).status != .Purchased })
        
        restorePurchasesButton?.enabled = enabled
        restorePurchasesBarButton?.enabled = enabled
    }
    
    // TODO: update animated
    func refreshTableView(animated animated: Bool = false)
    {
        self.tableView?.reloadData()
    }
}