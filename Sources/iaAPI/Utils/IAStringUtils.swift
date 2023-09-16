//
//  IAStringUtils.swift
//  iaAPI
//
//  Created by Hunter Lee Brown
//

import Foundation
import UIKit


public struct IAStringUtils {

    //                       date: "2014-10-15T00:00:00Z",
    public static let IAArchiveDateFormat = "yyyy'-'MM'-'dd'T'HH:mm:ss'Z'"
    public static let IAShortDateFormat = "M/d/YYYY"
    
    public static func shortDateFromDateString(_ dateString: String) ->String
    {
        let df = IAStringUtils.formatter
        df.dateFormat = IAStringUtils.IAArchiveDateFormat
        if let sDate = df.date(from: dateString) {
            
            let showDateFormat = IAStringUtils.formatter
            //            showDateFormat.dateFormat = StringUtils.ShortDateFormat
            showDateFormat.dateStyle = DateFormatter.Style.medium
            return showDateFormat.string(from: sDate)
        } else {
            return ""
        }
        
    }
    
    public static func timeFormatter(timeString:String) -> String {
        
        let timeComponents = timeString.components(separatedBy: ":")
        guard timeComponents.count > 1 && timeComponents.count < 3 else {
            
            if let time = Float(timeString) {
                return IAStringUtils.timeFormatted(Int(time.rounded()))
            }
            return timeString
        }
        
        let seconds = Int(timeComponents.last!)
        let minutes = Int(timeComponents[0])
        
        let secs = String(format: "%02d", arguments: [seconds!])
        
        if minutes! <= 60 {
            let mins = String(format: "%02d", arguments: [minutes!])
            return "\(mins):\(secs)"
        }
        
        let hours = minutes! / 60
        let minutesRemainder = minutes! % 60
        
        let h = String(format: "%02d", hours)
        let m = String(format: "%02d", minutesRemainder)
        
        return "\(h):\(m):\(secs)"
    }
    
    public static func timeFormatted(_ totalSeconds:Int) ->String {
        
        let seconds: Int = totalSeconds % 60
        let minutes: Int = (totalSeconds / 60) % 60
        let hours : Int = totalSeconds / 3600
        
        let secs = String(format: "%02d", arguments: [seconds])
        let mins = String(format: "%02d", arguments: [minutes])
        
        if hours > 0 {
            let hs = String(format: "%02d", arguments: [hours])
            return "\(hs):\(mins):\(secs)"
        } else {
            return "\(mins):\(secs)"
        }
    }
    
    
    fileprivate static var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        return formatter
    }()
    
    public static var numberFormatter:NumberFormatter {
        return NumberFormatter()
    }
    
    public static func sizeString(size:Int)->String {
        let numberFormatter = self.numberFormatter
        numberFormatter.numberStyle = .decimal
//        numberFormatter.roundingMode = .up
        numberFormatter.maximumFractionDigits = 2
        let calc: Double  = Double(size) / Double(1000000)
        return numberFormatter.string(from: NSNumber(value:Double(calc)))!
    }

}




extension NSMutableAttributedString {
    public class func IAMutableAttributedTextWithFontFromHTML(_ textWithFont:String, font:UIFont)->NSMutableAttributedString {
        
        do {
//            let attString =  try NSAttributedString(data: textWithFont.utf8Data!, options:[NSFontAttributeName: font, NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue], documentAttributes: nil)

            let attString = try NSAttributedString(data: textWithFont.utf8Data!, options: [
                NSAttributedString.DocumentReadingOptionKey.documentType : NSAttributedString.DocumentType.html,
                NSAttributedString.DocumentReadingOptionKey.characterEncoding: String.Encoding.utf8
                ], documentAttributes: nil)

            return NSMutableAttributedString(attributedString: attString)
            
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        return NSMutableAttributedString(string: "")
    }
    
    public class func IAMutableAttributedString(_ text:String, font:UIFont)->NSMutableAttributedString {
        
        do {
            let attString = try NSAttributedString(data: text.utf8Data!, options: [
                NSAttributedString.DocumentReadingOptionKey.documentType : NSAttributedString.DocumentType.html,
                NSAttributedString.DocumentReadingOptionKey.characterEncoding: String.Encoding.utf8
                ], documentAttributes: nil)

            return NSMutableAttributedString(attributedString: attString)
            
        } catch _ as NSError {
            //print(error.localizedDescription)
        }
        
        return NSMutableAttributedString(string: "")
        
    }
    
    public class func IABodyMutableAttributedString(_ html:String, font:UIFont)->NSMutableAttributedString? {
        let italicFontName: String = font.with(.traitItalic).fontName 
        let boldFontName: String = font.with(.traitBold).fontName 
        let boldItalicFontName: String = font.with([.traitItalic, .traitBold]).fontName 
        let pointSize: String = String(describing: font.pointSize)
        
        var htmlCss: String = "<html><head><style type=\"text/css\">"
        htmlCss += "body {backgroundColor:transparent !important; color:#000000; font-family: '\(font.fontName)'; font-size:\(pointSize)px; line-height:1em;}"
        htmlCss += "p:first-child:first-letter {color:#FF0000;}"
        htmlCss += "em,i {font-family: '\(italicFontName)'}"
        htmlCss += "b,strong {font-family: '\(boldFontName)'}"
        htmlCss += "b em,b i,em b,i b,strong em,strong i,em strong,i strong {font-family: '\(boldItalicFontName)'}"
        htmlCss += "</style></head><body>\(html)</body></html>"



        let data = Data(htmlCss.utf8)


        var attString: NSAttributedString? {
            do {
                return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)
            } catch {
                return nil
            }
        }

//        let attString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
//            yourLabel.attributedText = attributedString

//        let attString = NSMutableAttributedString.mutableAttributedString(htmlCss, font: font)
//        let paragraph = NSMutableParagraphStyle()
//        paragraph.lineSpacing = 2.25
//        paragraph.paragraphSpacing = font.lineHeight * 0.75
//        attString.addAttribute(NSAttributedStringKey.paragraphStyle, value: paragraph, range: NSMakeRange(0, attString.length))

//        let hunter = "hi".replacingOccurrences(of: <#T##String#>, with: <#T##String#>, options: <#T##String.CompareOptions#>, range: <#T##Range<String.Index>?#>)

        guard let aString = attString else {
            return nil;
        }

        return NSMutableAttributedString(attributedString: aString)
    }
    
}



extension Data {
    public var attributedString: NSAttributedString? {
        do {
            //            return try NSAttributedString(data: self, options:[NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: String.Encoding.utf8.rawValue], documentAttributes: nil)

            return try NSAttributedString(data: self, options: [
                NSAttributedString.DocumentReadingOptionKey.documentType : NSAttributedString.DocumentType.html,
                NSAttributedString.DocumentReadingOptionKey.characterEncoding: String.Encoding.utf8
            ], documentAttributes: nil)

        } catch let error as NSError {
            print(error.localizedDescription)
        }
        return nil
    }
}

extension String {
    public var utf8Data: Data? {
        return data(using: .utf8)
    }
    
    public func remove(htmlTag tag:String)->String {
        return self.replacingOccurrences(of:"(?i)<\(tag)\\b[^<]*>|</\(tag)\\b[^<]*>", with: "", options:.regularExpression, range: nil)
    }
    
    public func removeAttribute(htmlAttribute attribute:String)->String {
        return self.replacingOccurrences(of:"(?i)\\s*\(attribute)=\\S*[^<']*'|\"*", with: "", options:.regularExpression, range: nil)
    }
}

extension UIFont {

    public func with(_ traits: UIFontDescriptor.SymbolicTraits...) -> UIFont {
        guard let descriptor = self.fontDescriptor.withSymbolicTraits(UIFontDescriptor.SymbolicTraits(traits).union(self.fontDescriptor.symbolicTraits)) else {
            return self
        }
        return UIFont(descriptor: descriptor, size: 0)
    }
}
