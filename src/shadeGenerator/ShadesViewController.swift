import UIKit
import Accelerate
import Foundation
import ColourUtils

private final class InsetTextField: UITextField {
    var insets: UIEdgeInsets

    init(insets: UIEdgeInsets) {
        self.insets = insets
        super.init(frame: .zero)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("not intended for use from a NIB")
    }

    // placeholder position
    override func textRect(forBounds bounds: CGRect) -> CGRect {
         return super.textRect(forBounds: bounds.inset(by: insets))
    }
 
    // text position
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
         return super.editingRect(forBounds: bounds.inset(by: insets))
    }
}

extension UITextField {
    class func textFieldWithInsets(insets: UIEdgeInsets) -> UITextField {
        return InsetTextField(insets: insets)
    }
}





final class ShadesViewController: UIViewController {
    @IBOutlet weak var coloursCollectionView: UICollectionView!
    @IBOutlet weak var colourField: UITextField!
    
    
    var leftView: UIView!
    var pound: UILabel!
    
    var hexString: String?
    var baseColour: UIColor?
    var outlineColour: UIColor?
    
    
    var colours: [UIColor]?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: colourField.frame.size.height))
        pound = UILabel(frame: CGRect(x: 12, y: 0, width: 16, height: colourField.frame.size.height))
        
        pound.layer.backgroundColor = CGColor(gray: 0, alpha: 0)
        pound.text = "#"
        pound.textAlignment = .right
        
        pound.font = UIFont.monospacedSystemFont(ofSize: 17, weight: .medium)
        
        leftView.backgroundColor = colourField.backgroundColor
        
        colourField.leftView = leftView
        colourField.leftViewMode = UITextField.ViewMode.always
        
        colourField.layer.borderWidth = 1.75
        colourField.layer.cornerCurve = .continuous
        colourField.layer.cornerRadius = 4
        colourField.layer.borderColor = UIColor.systemGray4.cgColor
        
        colourField.autocorrectionType = .no
        colourField.autocapitalizationType = .none
        
        colourField.font = UIFont.monospacedSystemFont(ofSize: 17, weight: .medium)
        
        
        setTitleAttributes(with: UIColor.label)
        
        
        let (h, s, b) = ColourUtils.generateRandomPleasingColour()
        var r: CGFloat=0, g: CGFloat=0, b: CGFloat=0, a: CGFloat=0
        initCol.getRed(&r, green: &g, blue: &b, alpha: &a)
        let hex = ColourUtils.getHex(r: r, g: g, b: b)
        self.setColours(text: hex)
        self.hexString = hex
        self.colourField.text = hex
        self.leftView.frame = CGRect(x: 0, y: 0, width: 24, height: colourField.frame.size.height)
        colourField.addSubview(pound)
    }
}

extension ShadesViewController {
    func setTitleAttributes(with colour: UIColor) {
        let font = UIFont(name: "Quicksand", size: 32)!
        
        self.navigationController?.navigationBar.largeTitleTextAttributes = [
            NSAttributedString.Key.foregroundColor: colour,
            NSAttributedString.Key.font: font
        ]
    }
}

extension ShadesViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colours == nil ? 0 : colours!.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
        cell.layer.cornerCurve = .continuous
        cell.layer.cornerRadius = 4
        
        if let colours = self.colours {
            cell.backgroundColor = colours[indexPath.item]
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let colour = self.colours![indexPath.item]
        let detailView = ColourDetailViewController(hex: self.hexString!, colour: colour, baseColour: self.baseColour!, outlineColour: self.outlineColour!, itemIdx: indexPath.item)
        
        #if targetEnvironment(macCatalyst)
        detailView.modalPresentationStyle = .popover
        detailView.popoverPresentationController?.sourceView = collectionView.cellForItem(at: indexPath)!.contentView
        #endif
        
        self.present(detailView, animated: true)
    }
}

extension ShadesViewController: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        textField.text = textField.text?.filter({ 0...0xf ~= ($0.hexDigitValue ?? -1) }).uppercased()
        
        if let text = textField.text {
            if (text.count == 0) {
                self.colours = nil
                self.baseColour = nil
                self.hexString = nil
                
                self.view.backgroundColor = UIColor.systemBackground
                self.coloursCollectionView.backgroundColor = UIColor.systemBackground
                
                setTitleAttributes(with: UIColor.label)
                
                
                self.coloursCollectionView.reloadData()
                
                self.leftView.frame = CGRect(x: 0, y: 0, width: 8, height: colourField.frame.size.height)
                self.pound.removeFromSuperview()
                
                return
            }
            
            if (text.count == 6) {
                setColours(text: textField.text)
                
                self.hexString = text
                
                #if !targetEnvironment(macCatalyst)
                textField.resignFirstResponder()
                #endif
            }
            
            if (text.count > 6) {
                textField.text = String(text.dropLast())
            }
            
            if (text.count > 0) {
                self.leftView.frame = CGRect(x: 0, y: 0, width: 24, height: colourField.frame.size.height)
                
                colourField.addSubview(pound)
            } else {
                self.leftView.frame = CGRect(x: 0, y: 0, width: 8, height: colourField.frame.size.height)
                self.pound.removeFromSuperview()
            }
        }
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        setColours(text: textField.text)
        
        textField.resignFirstResponder()
        
        return true
    }
    
    func setColours(text: String?) -> Void {
        if let hex = text, let rgb = ColourUtils.getRGB(hex: hex) {
            let colours = ColourUtils.getShadesFor(rgb: rgb, n: 18)
            
            let colour = UIColor(hex: hex)
            
            self.colours = colours
            self.baseColour = colour
            self.view.backgroundColor = colour
            self.coloursCollectionView.backgroundColor = colour
            self.coloursCollectionView.reloadData()
            
            self.outlineColour = colours[ColourUtils.isLight(r: rgb.x, g: rgb.y, b: rgb.z) ? 30 : 6]
            colourField.layer.borderColor = self.outlineColour?.cgColor
            
            setTitleAttributes(with: self.outlineColour ?? UIColor.red)
        }
    }
}
