//
//  Extentions.swift
//  Novee
//
//  Created by Nick on 2022-12-26.
//

import Foundation
import SwiftUI
import SwiftSoup
import CommonCrypto

func ??<T>(lhs: Binding<Optional<T>>, rhs: T) -> Binding<T> {
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0 }
    )
}

extension URL {
    func getFinalURL() -> URL? {
        var request = URLRequest(url: self)
        request.httpMethod = "HEAD"
        var finalURL: URL? = nil
        let semaphore = DispatchSemaphore(value: 0)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                finalURL = httpResponse.url
            }
            semaphore.signal()
        }
        task.resume()
        _ = semaphore.wait(timeout: .distantFuture)
        return finalURL
    }
}

extension View {
    private func newWindowInternal(with title: String) -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 20, y: 20, width: 1000, height: 625),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false)
        window.center()
        window.isReleasedWhenClosed = false
        window.title = title
        window.makeKeyAndOrderFront(nil)
        return window
    }
    
    func openNewWindow(with title: String = "new Window") {
        self.newWindowInternal(with: title).contentView = NSHostingView(rootView: self)
    }
}

extension Status {
    func getStatusColor() -> Color {
        switch self {
        case .completed:
            return Color.green
        case .dropped:
            return Color.red
        case .viewing:
            return Color.orange
        case .waiting:
            return Color.yellow
        case .toView:
            return Color.purple
        }
    }
}

extension MediaType {
    func getColor() -> Color {
        switch self {
        case .anime:
            return .orange
        case .manga:
            return .indigo
        case .novel:
            return .pink
        }
    }
}

extension LoadingState? {
    func getColor() -> Color {
        switch self {
        case .loading:
            return Color.yellow
        case .success:
            return Color.green
        case .failed:
            return Color.red
        default:
            return Color.blue
        }
    }
}

extension NSImage {
    func pngData() -> Data? {
        if let tiffRepresentation = self.tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) {
            return bitmapImage.representation(using: .png, properties: [:])
        }
        
        return nil
    }
}

extension String {
    func sanitized() -> String {
        let invalidCharacters = CharacterSet(charactersIn: "\\/:*?\"<>|")
            .union(.newlines)
            .union(.illegalCharacters)
            .union(.controlCharacters)
        
        return self
            .components(separatedBy: invalidCharacters)
            .joined(separator: "")
    }
    
    mutating func sanitize() -> Void {
        self = self.sanitized()
    }
}

extension String {
    var sanitizedFileName: String {
        return components(separatedBy: .init(charactersIn: "/:?%*|\"<>")).joined()
    }
}

extension [String] {
    func filteredDS_Store() -> [String] {
        return self.filter { $0 != ".DS_Store" }
    }
}

extension URL {
    static let applicationSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    static let mangaListStorageUrl = applicationSupportDirectory.appendingPathComponent("mangalist", conformingTo: .json)
    static let animeListStorageUrl = applicationSupportDirectory.appendingPathComponent("animelist", conformingTo: .json)
    static let novelListStorageUrl = applicationSupportDirectory.appendingPathComponent("novellist", conformingTo: .json)
    static let mangaStorageUrl = applicationSupportDirectory.appendingPathComponent("manga", conformingTo: .folder)
    static let animeStorageUrl = applicationSupportDirectory.appendingPathComponent("anime", conformingTo: .folder)
    static let novelStorageUrl = applicationSupportDirectory.appendingPathComponent("novel", conformingTo: .folder)
}

extension Array {
    mutating func rearrange(fromIndex: Int, toIndex: Int){
        let element = self.remove(at: fromIndex)
        self.insert(element, at: toIndex)
    }
}

extension Element {
    func untilNext(_ nodeName: String) throws -> Elements {
        var currentElement = self
        var result: [Element] = [currentElement]
        
        while try currentElement.nextElementSibling()?.nodeName() != nodeName
                && currentElement.nextElementSibling() != nil {
            result.append(try currentElement.nextElementSibling()!)
            currentElement = try currentElement.nextElementSibling()!
        }
        
        return Elements(result)
    }
    
    func getSeparatedText(lineBreakAmount: Int = 2) throws -> String {
        var result = ""
        
        for line in self.children().array() {
            if try !line.text().isEmpty {
                result += "\(try line.text())\(String(repeating: "\n", count: lineBreakAmount))"
            }
        }
        
        return result
    }
}

extension Elements {
    func getSeparatedText(lineBreakAmount: Int = 2) throws -> String {
        var result = ""
        
        for line in self.array() {
            if try !line.text().isEmpty {
                result += "\(try line.text())\(String(repeating: "\n", count: lineBreakAmount))"
            }
        }
        
        return result
    }
}

fileprivate extension Color {
    typealias SystemColor = NSColor
    
    var colorComponents: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        SystemColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        // Note that non RGB color will raise an exception, that I don't now how to catch because it is an Objc exception.
        
        return (r, g, b, a)
    }
}

extension Color: Codable {
    enum CodingKeys: String, CodingKey {
        case red, green, blue, alpha
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let r = try container.decode(Double.self, forKey: .red)
        let g = try container.decode(Double.self, forKey: .green)
        let b = try container.decode(Double.self, forKey: .blue)
        let alpha = try container.decode(Double.self, forKey: .alpha)
        
        self.init(red: r, green: g, blue: b, opacity: alpha)
    }

    public func encode(to encoder: Encoder) throws {
        guard let colorComponents = self.colorComponents else {
            return
        }
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(colorComponents.red, forKey: .red)
        try container.encode(colorComponents.green, forKey: .green)
        try container.encode(colorComponents.blue, forKey: .blue)
        try container.encode(colorComponents.alpha, forKey: .alpha)
    }
}

extension Theme {
    static var themes = [defaultTheme, calmTheme, focusTheme]
    
    static let defaultTheme = Theme(
        name: "Default",
        lightBackgroundColor: .clear,
        darkBackgroundColor: .clear,
        lightTextColor: .black,
        darkTextColor: .white,
        fontName: "Times New Roman"
    )
    static let calmTheme = Theme(
        name: "Calm",
        lightBackgroundColor: Color(red: 241/255, green: 225/255, blue: 199/255),
        darkBackgroundColor: Color(red: 67/255, green: 59/255, blue: 48/255),
        lightTextColor: Color(red: 55/255, green: 44/255, blue: 36/255),
        darkTextColor: Color(red: 247/255, green: 236/255, blue: 217/255),
        fontName: "Baskerville"
    )
    static let focusTheme = Theme(
        name: "Focus",
        lightBackgroundColor: Color(red: 255/255, green: 252/255, blue: 244/255),
        darkBackgroundColor: Color(red: 26/255, green: 22/255, blue: 12/255),
        lightTextColor: Color(red: 20/255, green: 18/255, blue: 1/255),
        darkTextColor: Color(red: 255/255, green: 249/255, blue: 236/255),
        fontName: "Calibri"
    )
}

extension Date {
    func toString(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = style
        
        return formatter.string(from: self)
    }
}

public extension String {
    func aesEncrypt(key: String, iv: String) -> String? {
        guard
            let data = self.data(using: .utf8),
            let key = key.data(using: .utf8),
            let iv = iv.data(using: .utf8),
            let encrypt = data.encryptAES256(key: key, iv: iv)
            else { return nil }
        let base64Data = encrypt.base64EncodedData()
        return String(data: base64Data, encoding: .utf8)
    }

    func aesDecrypt(key: String, iv: String) -> String? {
        guard
            let data = Data(base64Encoded: self),
            let key = key.data(using: .utf8),
            let iv = iv.data(using: .utf8),
            let decrypt = data.decryptAES256(key: key, iv: iv)
            else { return nil }
        return String(data: decrypt, encoding: .utf8)
    }
}

/// @see http://www.splinter.com.au/2019/06/09/pure-swift-common-crypto-aes-encryption/
public extension Data {
    /// Encrypts for you with all the good options turned on: CBC, an IV, PKCS7
    /// padding (so your input data doesn't have to be any particular length).
    /// Key can be 128, 192, or 256 bits.
    /// Generates a fresh IV for you each time, and prefixes it to the
    /// returned ciphertext.
    func encryptAES256(key: Data, iv: Data, options: Int = kCCOptionPKCS7Padding) -> Data? {
        // No option is needed for CBC, it is on by default.
        return aesCrypt(operation: kCCEncrypt,
                        algorithm: kCCAlgorithmAES,
                        options: options,
                        key: key,
                        initializationVector: iv,
                        dataIn: self)
    }

    /// Decrypts self, where self is the IV then the ciphertext.
    /// Key can be 128/192/256 bits.
    func decryptAES256(key: Data, iv: Data, options: Int = kCCOptionPKCS7Padding) -> Data? {
        guard count > kCCBlockSizeAES128 else { return nil }
        return aesCrypt(operation: kCCDecrypt,
                        algorithm: kCCAlgorithmAES,
                        options: options,
                        key: key,
                        initializationVector: iv,
                        dataIn: self)
    }

    // swiftlint:disable:next function_parameter_count
    private func aesCrypt(operation: Int,
                          algorithm: Int,
                          options: Int,
                          key: Data,
                          initializationVector: Data,
                          dataIn: Data) -> Data? {
        return initializationVector.withUnsafeBytes { ivUnsafeRawBufferPointer in
            return key.withUnsafeBytes { keyUnsafeRawBufferPointer in
                return dataIn.withUnsafeBytes { dataInUnsafeRawBufferPointer in
                    // Give the data out some breathing room for PKCS7's padding.
                    let dataOutSize: Int = dataIn.count + kCCBlockSizeAES128 * 2
                    let dataOut = UnsafeMutableRawPointer.allocate(byteCount: dataOutSize, alignment: 1)
                    defer { dataOut.deallocate() }
                    var dataOutMoved: Int = 0
                    let status = CCCrypt(CCOperation(operation),
                                         CCAlgorithm(algorithm),
                                         CCOptions(options),
                                         keyUnsafeRawBufferPointer.baseAddress, key.count,
                                         ivUnsafeRawBufferPointer.baseAddress,
                                         dataInUnsafeRawBufferPointer.baseAddress, dataIn.count,
                                         dataOut, dataOutSize,
                                         &dataOutMoved)
                    guard status == kCCSuccess else { return nil }
                    return Data(bytes: dataOut, count: dataOutMoved)
                }
            }
        }
    }
}

public func randomGenerateBytes(count: Int) -> Data? {
    let bytes = UnsafeMutableRawPointer.allocate(byteCount: count, alignment: 1)
    defer { bytes.deallocate() }
    let status = CCRandomGenerateBytes(bytes, count)
    guard status == kCCSuccess else { return nil }
    return Data(bytes: bytes, count: count)
}
