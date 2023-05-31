//
//  ColourDetailViewController.swift
//  shadeGenerator
//
//  Created by Tim Xie on 22/03/23.
//

import UIKit
import Toast

class BlockView: UIView {
    var label: String = ""
    var info: String = ""
}

class ColourDetailViewController: UIViewController {
    private let infos: [String] = ["RGB [0-255]", "RGB [0.0-1.0]", "HEX", "HSB [360°]", "HSB [0.0-1.0]", "HSL [360°]", "HSL [0.0-1.0]", "SwiftUI Color", "UIColor", "CGColor", "CIColor", "NSColor"]
    
    let hex: String
    let colour: UIColor
    let baseColour: UIColor
    let outlineColour: UIColor
    let itemIdx: Int
    
    let (r, g, b, a): (CGFloat, CGFloat, CGFloat, CGFloat)
    let (h, s_v, v): (CGFloat, CGFloat, CGFloat)
    let (_, s_l, l): (CGFloat, CGFloat, CGFloat)
    
    let scrollView: UIScrollView
    let stackView: UIStackView
    
    let threshold: Bool
    
    init(hex: String, colour: UIColor, baseColour: UIColor, outlineColour: UIColor, itemIdx: Int) {
        self.hex = hex
        self.colour = colour
        self.baseColour = baseColour
        self.outlineColour = outlineColour
        self.itemIdx = itemIdx
        
        self.scrollView = UIScrollView()
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.contentInset = UIEdgeInsets(top: 32, left: 16, bottom: 16, right: 16)
        
        self.stackView = UIStackView()
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        self.stackView.axis = .vertical
        self.stackView.distribution = .equalCentering
        self.stackView.alignment = .center
        self.stackView.spacing = 16
        
        var (r, g, b, a): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        colour.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        (self.r, self.g, self.b, self.a) = (r, g, b, a)
        (self.h, self.s_v, self.v) = getHSV(r: r, g: g, b: b)
        (_, self.s_l, self.l) = getHSLfromHSV(h: h, s: s_v, v: v)
        
        self.threshold = (r*0.299 + g*0.587 + b*0.114) > 150/255
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func dismissSheet() {
        self.dismiss(animated: true, completion: nil)
    }
    
    lazy var navBar = {
        let navBar = UINavigationBar()
        
        
        navBar.isTranslucent = false
        navBar.barTintColor = colour
        navBar.tintColor = self.threshold ? UIColor.black : UIColor.white
        
        let navItem = UINavigationItem(title: (itemIdx < 18 ? "Tint" : "Shade") + " \(itemIdx % 18 + 1) " + "for #\(hex.uppercased())")
        navBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : (self.threshold ? UIColor.black : UIColor.white)]
        navBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor : (self.threshold ? UIColor.black : UIColor.white)]
        
        #if !targetEnvironment(macCatalyst)
        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissSheet))
        navItem.rightBarButtonItem = doneItem
        #else
        if #available(macCatalyst 16.0, *) {
            navBar.preferredBehavioralStyle = .pad
        }
        #endif
        
        navBar.setItems([navItem], animated: false)
        navBar.translatesAutoresizingMaskIntoConstraints = false
        
        return navBar
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = colour
        self.view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        scrollView.indicatorStyle = self.threshold ? .black : .white
        self.view.addSubview(navBar)
        
        NSLayoutConstraint.activate([
            navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navBar.topAnchor.constraint(equalTo: view.topAnchor),
            navBar.heightAnchor.constraint(equalToConstant: 44),
            
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 44),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
        ])
        

        
        for info in infos {
            let block = makeBlock(with: info, info: {
                switch (info) {
                case "RGB [0-255]":
                    return "(\(Int(r*255)), \(Int(g*255)), \(Int(b*255)))"
                    
                case "RGB [0.0-1.0]":
                    return String(format: "(%.*f, %.*f, %.*f)", 2, r, 2, g, 2, b)
                    
                case "HEX":
                    return "#\(getHEX(r: r, g: g, b: b))"
                    
                case "HSB [360°]":
                    return String(format: "(%i°, %.2f, %.2f)", Int(360*h), s_v, v)
                    
                case "HSB [0.0-1.0]":
                    return String(format: "(%.2f, %.2f, %.2f)", h, s_v, v)
                    
                case "HSL [360°]":
                    return String(format: "(%i°, %.2f, %.2f)", Int(360*h), s_l, l)
                    
                case "HSL [0.0-1.0]":
                    return String(format: "(%.2f, %.2f, %.2f)", h, s_l, l)
                    
                case "SwiftUI Color":
                    return String(format: "Color(red: %.2f, green: %.2f, blue: %.2f, opacity: 1.0)", r, g, b)
                    
                case "UIColor":
                    return String(format: "UIColor(red: %.2f, green: %.2f, blue: %.2f, alpha: 1.0)", r, g, b)
                    
                case "CGColor":
                    return String(format: "UIColor(red: %.2f, green: %.2f, blue: %.2f, alpha: 1.0).cgColor", r, g, b)
                    
                case "CIColor":
                    return String(format: "CIColor(red: %.2f, green: %.2f, blue: %.2f)", r, g, b)
                    
                case "NSColor":
                    return String(format: "NSColor(red: %.2f, green: %.2f, blue: %.2f)", r, g, b)

                    
                default:
                    return "-"
                }
            }())
            
            block.translatesAutoresizingMaskIntoConstraints = false
            
            stackView.addArrangedSubview(block)
            
            NSLayoutConstraint.activate([
                block.widthAnchor.constraint(equalTo: stackView.widthAnchor),
                block.heightAnchor.constraint(equalToConstant: 70)
            ])
        }
        
            
        print("loaded")
    }
    
    @objc func clickBlock(_ tapGesture: UITapGestureRecognizer) {
        let tappedView: BlockView? = (tapGesture.view as? BlockView)
        guard let text = tappedView?.info else { return }
        UIPasteboard.general.string = text
        
        guard let label = tappedView?.label else { return }
        
        let configuration: ToastConfiguration = .init(
            direction: .bottom,
            enablePanToClose: true,
            displayTime: 3.5
        )
        
        let toast = Toast.default(
            image: UIImage(systemName: "checkmark.circle")!,
            title: "Copied \(label) to clipboard!",
            subtitle: text,
            config: configuration)
        
        toast.show(haptic: .success)
    }
    
    private func makeBlock(with title: String, info: String) -> BlockView {
        let block = BlockView()
        
        block.label = title
        block.info = info
        
        block.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(clickBlock)))
        
        block.layer.cornerCurve = .continuous
        block.layer.cornerRadius = 6
        
        block.backgroundColor = UIColor(white: self.threshold ? 0 : 1.0, alpha: 0.1)
        
        block.layer.shadowRadius = 4
        block.layer.shadowColor = UIColor.black.cgColor
        block.layer.shadowOpacity = 0.04
        
        
        let titleLabel = UILabel()
        let infoLabel = UILabel()
        let copyIcon = UIImageView(image: UIImage(systemName: "doc.on.doc")!)
       

        block.addSubview(infoLabel)
        block.addSubview(titleLabel)
        block.addSubview(copyIcon)
        
        titleLabel.text = title
        infoLabel.text = info.count > 20 ? "Copy to Clipboard" : info

        infoLabel.adjustsFontSizeToFitWidth = true
        infoLabel.numberOfLines = 1
        infoLabel.minimumScaleFactor = 0.1
        
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        infoLabel.font = UIFont.monospacedSystemFont(ofSize: 20, weight: .semibold)
        
        if (self.threshold) {
            titleLabel.textColor = .black
            infoLabel.textColor = .black
            copyIcon.tintColor = .black
        } else {
            titleLabel.textColor = .white
            infoLabel.textColor = .white
            copyIcon.tintColor = .white
        }
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        copyIcon.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: block.leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: block.topAnchor, constant: 12),
            
            infoLabel.leadingAnchor.constraint(equalTo: block.leadingAnchor, constant: 16),
            infoLabel.bottomAnchor.constraint(equalTo: block.bottomAnchor, constant: -12),
            

            copyIcon.centerYAnchor.constraint(equalTo: block.centerYAnchor),
            copyIcon.trailingAnchor.constraint(equalTo: block.trailingAnchor, constant: -16),
            
            infoLabel.trailingAnchor.constraint(equalTo: block.trailingAnchor, constant: -36),
        ])
        
        
        return block
    }
}
