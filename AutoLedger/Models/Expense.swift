import Foundation
import SwiftData

@Model
final class Expense {
    var id: UUID
    var date: Date
    var category: ExpenseCategory
    var customCategoryName: String?
    var amount: Double
    var vendor: String?
    var expenseDescription: String?
    var notes: String?
    var receiptImageData: Data?
    var isRecurring: Bool
    var recurringInterval: RecurringInterval?
    var createdAt: Date

    var vehicle: Vehicle?

    init(
        date: Date = Date(),
        category: ExpenseCategory,
        customCategoryName: String? = nil,
        amount: Double,
        vendor: String? = nil,
        description: String? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.category = category
        self.customCategoryName = customCategoryName
        self.amount = amount
        self.vendor = vendor
        self.expenseDescription = description
        self.notes = notes
        self.isRecurring = false
        self.createdAt = Date()
    }

    var displayCategory: String {
        if category == .other, let customName = customCategoryName {
            return customName
        }
        return category.displayName
    }
}

enum ExpenseCategory: String, Codable, CaseIterable {
    case insurance = "insurance"
    case registration = "registration"
    case parking = "parking"
    case tolls = "tolls"
    case carWash = "car_wash"
    case accessories = "accessories"
    case modifications = "modifications"
    case tickets = "tickets"
    case towing = "towing"
    case roadside = "roadside"
    case subscription = "subscription"
    case loan = "loan"
    case lease = "lease"
    case tax = "tax"
    case inspection = "inspection"
    case other = "other"

    var displayName: String {
        switch self {
        case .insurance: return "Insurance"
        case .registration: return "Registration"
        case .parking: return "Parking"
        case .tolls: return "Tolls"
        case .carWash: return "Car Wash"
        case .accessories: return "Accessories"
        case .modifications: return "Modifications"
        case .tickets: return "Tickets/Fines"
        case .towing: return "Towing"
        case .roadside: return "Roadside Assistance"
        case .subscription: return "Subscription"
        case .loan: return "Loan Payment"
        case .lease: return "Lease Payment"
        case .tax: return "Vehicle Tax"
        case .inspection: return "Inspection Fee"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .insurance: return "shield.fill"
        case .registration: return "doc.text.fill"
        case .parking: return "p.square.fill"
        case .tolls: return "road.lanes"
        case .carWash: return "drop.fill"
        case .accessories: return "bag.fill"
        case .modifications: return "wrench.and.screwdriver.fill"
        case .tickets: return "exclamationmark.triangle.fill"
        case .towing: return "truck.box.fill"
        case .roadside: return "phone.fill"
        case .subscription: return "repeat"
        case .loan: return "dollarsign.circle.fill"
        case .lease: return "signature"
        case .tax: return "building.columns.fill"
        case .inspection: return "checkmark.seal.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

enum RecurringInterval: String, Codable, CaseIterable {
    case weekly = "Weekly"
    case biweekly = "Bi-weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case semiannually = "Semi-annually"
    case annually = "Annually"
}
