import Foundation
import SwiftData

@Model
final class Document {
    var id: UUID
    var name: String
    var documentType: DocumentType
    var imageData: Data?
    var pdfData: Data?
    var expirationDate: Date?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    var vehicle: Vehicle?

    init(
        name: String,
        documentType: DocumentType,
        expirationDate: Date? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.documentType = documentType
        self.expirationDate = expirationDate
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var isExpired: Bool {
        guard let expirationDate = expirationDate else { return false }
        return expirationDate < Date()
    }

    var isExpiringSoon: Bool {
        guard let expirationDate = expirationDate else { return false }
        let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        return expirationDate <= thirtyDaysFromNow && !isExpired
    }

    var daysUntilExpiration: Int? {
        guard let expirationDate = expirationDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: expirationDate)
        return components.day
    }
}

enum DocumentType: String, Codable, CaseIterable {
    case insuranceCard = "insurance_card"
    case registration = "registration"
    case title = "title"
    case driversLicense = "drivers_license"
    case maintenanceReceipt = "maintenance_receipt"
    case purchaseReceipt = "purchase_receipt"
    case warranty = "warranty"
    case loanDocument = "loan_document"
    case leaseAgreement = "lease_agreement"
    case inspectionReport = "inspection_report"
    case emissionsCertificate = "emissions_certificate"
    case fasTag = "fas_tag"
    case other = "other"

    var displayName: String {
        switch self {
        case .insuranceCard: return "Insurance Card"
        case .registration: return "Registration"
        case .title: return "Title"
        case .driversLicense: return "Driver's License"
        case .maintenanceReceipt: return "Maintenance Receipt"
        case .purchaseReceipt: return "Purchase Receipt"
        case .warranty: return "Warranty"
        case .loanDocument: return "Loan Document"
        case .leaseAgreement: return "Lease Agreement"
        case .inspectionReport: return "Inspection Report"
        case .emissionsCertificate: return "PUC Certificate"
        case .fasTag: return "FASTag"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .insuranceCard: return "shield.fill"
        case .registration: return "doc.text.fill"
        case .title: return "scroll.fill"
        case .driversLicense: return "person.text.rectangle.fill"
        case .maintenanceReceipt: return "doc.plaintext.fill"
        case .purchaseReceipt: return "receipt.fill"
        case .warranty: return "checkmark.seal.fill"
        case .loanDocument: return "dollarsign.circle.fill"
        case .leaseAgreement: return "signature"
        case .inspectionReport: return "checklist"
        case .emissionsCertificate: return "leaf.fill"
        case .fasTag: return "antenna.radiowaves.left.and.right"
        case .other: return "doc.fill"
        }
    }

    var hasExpiration: Bool {
        switch self {
        case .insuranceCard, .registration, .driversLicense, .warranty, .inspectionReport, .emissionsCertificate, .fasTag:
            return true
        default:
            return false
        }
    }
}
