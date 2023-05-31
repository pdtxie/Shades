import UIKit
import Accelerate
import Foundation

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
        
        
        let initCol = getRandomPleasingColour()
        var r: CGFloat=0, g: CGFloat=0, b: CGFloat=0, a: CGFloat=0
        initCol.getRed(&r, green: &g, blue: &b, alpha: &a)
        let hex = getHEX(r: r, g: g, b: b)
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
        if let hex = text, let rgb = getRGB(hex: hex) {
            let colours = generateShadesTwo(for: rgb, n: 18)
            
            let colour = UIColor(hex: hex)
            
            self.colours = colours
            self.baseColour = colour
            self.view.backgroundColor = colour
            self.coloursCollectionView.backgroundColor = colour
            self.coloursCollectionView.reloadData()
            
            self.outlineColour = colours[(((rgb.x*0.299 + rgb.y*0.587 + rgb.z*0.114) > 150) ? 6 : 30)]
            colourField.layer.borderColor = self.outlineColour?.cgColor
            
            setTitleAttributes(with: self.outlineColour ?? UIColor.label)
        }
    }
}



extension UIColor {
    convenience init(hex: String) {
        if let rgb = getRGB(hex: hex) {
            self.init(red: rgb.x, green: rgb.y, blue: rgb.z, alpha: 1.0)
        } else {
            self.init(red: 0, green: 0, blue: 0, alpha: 1.0)
        }
    }
}


func getRGB(hex string: String) -> SIMD3<Double>? {
    var hex = string.trimmingCharacters(in: .whitespacesAndNewlines)
    hex = hex.replacingOccurrences(of: "#", with: "")
    
    var rgb: UInt64 = 0
    guard Scanner(string: hex).scanHexInt64(&rgb) else { return nil }
    
    if (string.count == 6) {
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0
        
        return SIMD3(r, g, b)
    } else {
        return nil
    }
}

func getHEX(r: CGFloat, g: CGFloat, b: CGFloat) -> String {
    var str = ""
    str += String(format:"%02X", (Int(r * 255)))
    str += String(format:"%02X", (Int(g * 255)))
    str += String(format:"%02X", (Int(b * 255)))

    return str
}

//func generateColour(rgb: (CGFloat, CGFloat, CGFloat)) -> [UIColor]? {
//    let hsl = getHSL(r: rgb.0, g: rgb.1, b: rgb.2)
//
//    let lStep1 = hsl.l/CGFloat(20)
//    let lStep2 = (1.0 - hsl.l)/CGFloat(20)
//
//    var colours: [UIColor] = []
//
//    for i in stride(from: 0, to: hsl.l, by: lStep1) {
//        colours.append(UIColor(hue: hsl.h, saturation: hsl.s, brightness: hsl.l + , alpha: 1.0))
//    }
//
//    for i in stride(from: hsl.l, to: 1.0, by: lStep2) {
//        colours.append(UIColor(hue: hsl.h, saturation: hsl.s, brightness: min(1.0, i+lStep2), alpha: 1.0))
//        print(i+lStep2)
//    }
//
//    return colours
//}

//func generateShades(for rgb: SIMD3<Double>, n: Int) -> [UIColor]? {
//    var tints = [UIColor]()
//    var shades = [UIColor]()
//    
//    let factor = 1.0/Double(n)
//    var s = rgb
//    var t = rgb
//    
//    for _ in 0..<n {
//        t += (SIMD3(1.0, 1.0, 1.0) - t) * factor
//        s *= (1.0 - factor)
//        
//        tints.append(UIColor(red: t.x, green: t.y, blue: t.z, alpha: 1.0))
//        shades.append(UIColor(red: s.x, green: s.y, blue: s.z, alpha: 1.0))
//        
//        print(getHSV(r: s.x, g: s.y, b: s.z).v)
//    }
//    
//    return tints.reversed() + shades
//}

func generateShadesTwo(for rgb: SIMD3<Double>, n: Int) -> [UIColor] {
    var tints = [UIColor]()
    var shades = [UIColor]()
    
    let factor = 1.0/Double(n)
    
    for o in stride(from: 0, to: 1.0, by: factor) {
        let t = o + factor + (1 - o - factor) * rgb
        let s = o * rgb
        
        tints.append(UIColor(red: t.x, green: t.y, blue: t.z, alpha: 1.0))
        shades.append(UIColor(red: s.x, green: s.y, blue: s.z, alpha: 1.0))
    }
    
    return (shades + tints).reversed()
}


func getHSV(r: CGFloat, g: CGFloat, b: CGFloat) -> (h: CGFloat, s: CGFloat, v: CGFloat) {
    let v = max(r, g, b)
    let c = v - min(r, g, b)
    
    var h: CGFloat = {
        if (c == 0) { return 0 }
        
        switch (v) {
        case r: return ((g - b)/c).truncatingRemainder(dividingBy: 6)
        case g: return (b - r)/c + 2.0
        case b: return (r - g)/c + 4.0
        
        default: return 0
        }
    }()
    
    h /= 6.0
    
    
    let s: CGFloat = v == 0 ? 0 : c / v
    
    return (h, s, v)
}

func getHSLfromHSV(h: CGFloat, s: CGFloat, v: CGFloat) -> (h: CGFloat, s: CGFloat, l: CGFloat) {
    var l = (2 - s) * v / 2
    var s_l = s
    
    if (l != 0) {
        if (l == 1) {
            s_l = 0
        } else if (l < 0.5) {
            s_l = s * v / (l * 2)
        } else {
            s_l = s * v / (2 - l * 2)
        }
    }

    return (h, s_l, l)
}



func getRandomPleasingColour() -> UIColor {
    let base = UIColor(red: CGFloat.random(in: 0...1), green: CGFloat.random(in: 0...1), blue: CGFloat.random(in: 0...1), alpha: 1.0)
    var (h, s, v, a): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
    
    base.getHue(&h, saturation: &s, brightness: &v, alpha: &a)
    
    return UIColor(hue: h, saturation: s/2, brightness: (1+s)/2, alpha: a)
}
