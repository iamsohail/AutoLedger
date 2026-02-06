import Foundation
import Vision
import UIKit

struct ScannedFuelData {
    var date: Date?
    var quantity: Double?
    var pricePerUnit: Double?
    var totalAmount: Double?
    var stationName: String?
    var fuelType: String?
    var scanMethod: ScanMethod = .none

    enum ScanMethod {
        case none, ai, onDevice
    }
}

class ReceiptScannerService {

    // MARK: - Public API

    /// Primary: GPT-4o vision. Fallback: on-device OCR.
    static func scanReceipt(image: UIImage) async -> ScannedFuelData {
        // Try AI vision first if API key is available
        if let apiKey = KeychainHelper.get(key: "openai_api_key"), !apiKey.isEmpty {
            if let aiResult = await scanWithAI(image: image, apiKey: apiKey) {
                return aiResult
            }
        }

        // Fallback to on-device OCR
        let lines = await performOCR(on: image)
        var data = parseReceiptText(lines)
        data.scanMethod = .onDevice
        return data
    }

    // MARK: - AI Vision (GPT-4o)

    private static func scanWithAI(image: UIImage, apiKey: String) async -> ScannedFuelData? {
        // Compress image for API (resize to max 1024px, JPEG 80%)
        let resized = resizeImage(image, maxDimension: 1024)
        guard let imageData = resized.jpegData(compressionQuality: 0.8) else { return nil }
        let base64 = imageData.base64EncodedString()

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let prompt = """
        Extract fuel receipt data from this image. Return ONLY a valid JSON object with these fields:
        {
          "date": "YYYY-MM-DD" or null,
          "quantity": number (in liters) or null,
          "pricePerUnit": number (price per liter) or null,
          "totalAmount": number or null,
          "stationName": string or null,
          "fuelType": "Petrol" or "Diesel" or "CNG" or "Premium" or null
        }
        Return ONLY the JSON object. No markdown, no explanation, no code fences.
        """

        let body: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": prompt
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64)",
                                "detail": "high"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 300,
            "temperature": 0
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else { return nil }
        request.httpBody = httpBody

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }

            return parseAIResponse(data)
        } catch {
            return nil
        }
    }

    private static func parseAIResponse(_ data: Data) -> ScannedFuelData? {
        // Parse the OpenAI chat completion response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            return nil
        }

        // Clean up response — remove markdown fences if present
        let cleaned = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleaned.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return nil
        }

        var result = ScannedFuelData()
        result.scanMethod = .ai

        if let dateStr = parsed["date"] as? String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            result.date = formatter.date(from: dateStr)
        }

        if let qty = parsed["quantity"] as? Double {
            result.quantity = qty
        } else if let qty = parsed["quantity"] as? Int {
            result.quantity = Double(qty)
        }

        if let rate = parsed["pricePerUnit"] as? Double {
            result.pricePerUnit = rate
        } else if let rate = parsed["pricePerUnit"] as? Int {
            result.pricePerUnit = Double(rate)
        }

        if let total = parsed["totalAmount"] as? Double {
            result.totalAmount = total
        } else if let total = parsed["totalAmount"] as? Int {
            result.totalAmount = Double(total)
        }

        result.stationName = parsed["stationName"] as? String
        result.fuelType = parsed["fuelType"] as? String

        return result
    }

    private static func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard max(size.width, size.height) > maxDimension else { return image }

        let scale = maxDimension / max(size.width, size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    // MARK: - On-Device OCR (Fallback)

    private static func performOCR(on image: UIImage) async -> [String] {
        guard let cgImage = image.cgImage else { return [] }

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                let strings = observations.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: strings)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-IN", "en-US", "hi-IN"]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: [])
            }
        }
    }

    // MARK: - Receipt Text Parsing (On-Device)

    private static func parseReceiptText(_ lines: [String]) -> ScannedFuelData {
        var data = ScannedFuelData()
        let fullText = lines.joined(separator: "\n")
        let upperFullText = fullText.uppercased()

        data.stationName = detectStation(from: upperFullText)
        data.fuelType = detectFuelType(from: upperFullText)

        for line in lines {
            let upper = line.uppercased()

            if data.pricePerUnit == nil && isRateLine(upper) {
                if let value = extractNumber(from: line) {
                    data.pricePerUnit = value
                }
            }

            if data.quantity == nil && isQuantityLine(upper) {
                if let value = extractNumber(from: line) {
                    data.quantity = value
                }
            }

            if data.totalAmount == nil && isAmountLine(upper) {
                if let value = extractNumber(from: line) {
                    data.totalAmount = value
                }
            }

            if data.date == nil {
                if let parsed = extractDate(from: line) {
                    data.date = parsed
                }
            }
        }

        if data.quantity == nil || data.pricePerUnit == nil || data.totalAmount == nil {
            parseTabularFormat(lines: lines, data: &data)
        }

        crossValidate(&data)
        return data
    }

    // MARK: - Keyword Detection

    private static func isRateLine(_ upper: String) -> Bool {
        let keywords = [
            "RATE", "PRICE", "/LTR", "/LITRE", "/LITER", "/L",
            "RS/L", "₹/L", "PER LITRE", "PER LITER", "PER LTR",
            "UNIT PRICE", "SELLING PRICE"
        ]
        return keywords.contains { upper.contains($0) }
    }

    private static func isQuantityLine(_ upper: String) -> Bool {
        let keywords = [
            "QUANTITY", "QTY", "VOLUME", "LTR", "LITRE", "LITER",
            "LITRES", "LITERS", "LTRS"
        ]
        if upper.contains("/LTR") || upper.contains("/LITRE") || upper.contains("/LITER") || upper.contains("/L)") {
            return false
        }
        return keywords.contains { upper.contains($0) }
    }

    private static func isAmountLine(_ upper: String) -> Bool {
        let keywords = [
            "AMOUNT", "TOTAL", "NET AMT", "NET AMOUNT", "SALE AMT",
            "SALE AMOUNT", "PAYABLE", "GRAND TOTAL"
        ]
        if upper.contains("PER") || upper.contains("/LTR") || upper.contains("/LITRE") {
            return false
        }
        return keywords.contains { upper.contains($0) }
    }

    private static func detectStation(from text: String) -> String? {
        let stations: [(keywords: [String], name: String)] = [
            (["INDIAN OIL", "IOCL", "INDANE"], "Indian Oil"),
            (["HINDUSTAN PETROLEUM", "HPCL", "HP PETROL"], "HP"),
            (["BHARAT PETROLEUM", "BPCL"], "Bharat Petroleum"),
            (["SHELL"], "Shell"),
            (["RELIANCE"], "Reliance"),
            (["NAYARA", "ESSAR"], "Nayara Energy"),
            (["TOTAL ENERGIES"], "Total Energies"),
        ]

        for station in stations {
            for keyword in station.keywords {
                if text.contains(keyword) {
                    return station.name
                }
            }
        }
        return nil
    }

    private static func detectFuelType(from text: String) -> String? {
        if text.contains("PREMIUM") || text.contains("XP95") || text.contains("XTRA PREMIUM") || text.contains("SPEED") || text.contains("V-POWER") {
            return "Premium"
        }
        if text.contains("DIESEL") || text.contains("HSD") || text.contains("HIGH SPEED DIESEL") {
            return "Diesel"
        }
        if text.contains("CNG") || text.contains("COMPRESSED NATURAL GAS") {
            return "CNG"
        }
        if text.contains("PETROL") || text.contains("MS ") || text.contains("MOTOR SPIRIT") || text.contains("(MS)") || text.contains("UNLEADED") {
            return "Petrol"
        }
        return nil
    }

    // MARK: - Number Extraction

    private static func extractNumber(from line: String) -> Double? {
        let cleaned = line
            .replacingOccurrences(of: "₹", with: "")
            .replacingOccurrences(of: "Rs", with: "")
            .replacingOccurrences(of: "RS", with: "")
            .replacingOccurrences(of: "rs", with: "")
            .replacingOccurrences(of: "INR", with: "")

        let pattern = #"(\d{1,3}(?:,\d{3})*(?:\.\d{1,4})?|\d+\.?\d*)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }

        let matches = regex.matches(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned))

        var bestNumber: Double?
        for match in matches.reversed() {
            if let range = Range(match.range(at: 1), in: cleaned) {
                let numStr = String(cleaned[range]).replacingOccurrences(of: ",", with: "")
                if let num = Double(numStr), num > 0.1 {
                    bestNumber = num
                    break
                }
            }
        }
        return bestNumber
    }

    // MARK: - Date Extraction

    private static func extractDate(from line: String) -> Date? {
        let patterns = [
            (#"(\d{2})[/\-](\d{2})[/\-](\d{4})"#, "dd/MM/yyyy"),
            (#"(\d{2})[/\-](\d{2})[/\-](\d{2})\b"#, "dd/MM/yy"),
            (#"(\d{4})-(\d{2})-(\d{2})"#, "yyyy-MM-dd"),
        ]

        for (pattern, format) in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(line.startIndex..., in: line)

            if let match = regex.firstMatch(in: line, range: range),
               let matchRange = Range(match.range, in: line) {
                let dateStr = String(line[matchRange])
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_IN")

                let normalized = dateStr.replacingOccurrences(of: "-", with: "/")
                formatter.dateFormat = format.replacingOccurrences(of: "-", with: "/")

                if let date = formatter.date(from: normalized) {
                    let now = Date()
                    let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: now) ?? now
                    if date <= now && date >= oneYearAgo {
                        return date
                    }
                }
            }
        }
        return nil
    }

    // MARK: - Tabular Format

    private static func parseTabularFormat(lines: [String], data: inout ScannedFuelData) {
        for line in lines {
            let numbers = extractAllNumbers(from: line)
            if numbers.count == 3 {
                let (a, b, c) = (numbers[0], numbers[1], numbers[2])
                if isApproximatelyEqual(a * b, c) {
                    if data.quantity == nil { data.quantity = a }
                    if data.pricePerUnit == nil { data.pricePerUnit = b }
                    if data.totalAmount == nil { data.totalAmount = c }
                    return
                }
                if isApproximatelyEqual(b * a, c) {
                    if data.pricePerUnit == nil { data.pricePerUnit = a }
                    if data.quantity == nil { data.quantity = b }
                    if data.totalAmount == nil { data.totalAmount = c }
                    return
                }
            }
        }
    }

    private static func extractAllNumbers(from line: String) -> [Double] {
        let cleaned = line
            .replacingOccurrences(of: "₹", with: "")
            .replacingOccurrences(of: "Rs", with: "")
            .replacingOccurrences(of: ",", with: "")

        let pattern = #"\d+\.?\d*"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

        let matches = regex.matches(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned))
        return matches.compactMap { match in
            if let range = Range(match.range, in: cleaned) {
                return Double(cleaned[range])
            }
            return nil
        }.filter { $0 > 0.1 }
    }

    private static func isApproximatelyEqual(_ a: Double, _ b: Double, tolerance: Double = 1.0) -> Bool {
        abs(a - b) <= tolerance
    }

    // MARK: - Cross-Validation

    private static func crossValidate(_ data: inout ScannedFuelData) {
        if let qty = data.quantity, let rate = data.pricePerUnit, data.totalAmount == nil {
            data.totalAmount = qty * rate
        } else if let total = data.totalAmount, let rate = data.pricePerUnit, data.quantity == nil, rate > 0 {
            data.quantity = total / rate
        } else if let total = data.totalAmount, let qty = data.quantity, data.pricePerUnit == nil, qty > 0 {
            data.pricePerUnit = total / qty
        }
    }
}

// MARK: - Keychain Helper

enum KeychainHelper {
    static func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)

        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        SecItemAdd(attributes as CFDictionary, nil)
    }

    static func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
