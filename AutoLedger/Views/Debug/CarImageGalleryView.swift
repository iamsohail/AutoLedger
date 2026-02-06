import SwiftUI

/// Temporary debug view to audit all car images
struct CarImageGalleryView: View {

    struct CarEntry: Identifiable {
        let id = UUID()
        let make: String
        let model: String
    }

    @State private var cars: [CarEntry] = []
    @State private var searchText = ""

    private var filteredCars: [CarEntry] {
        if searchText.isEmpty { return cars }
        return cars.filter {
            "\($0.make) \($0.model)".localizedCaseInsensitiveContains(searchText)
        }
    }

    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(filteredCars) { car in
                        VStack(spacing: 8) {
                            CarImageView(make: car.make, model: car.model, size: 120, cornerRadius: 12)

                            Text("\(car.make)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.primaryPurple)

                            Text(car.model)
                                .font(.system(size: 10))
                                .foregroundColor(.textSecondary)
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.cardBackground)
                        )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 20)
            }
            .background(Color.darkBackground.ignoresSafeArea())
            .navigationTitle("Car Images (\(filteredCars.count))")
            .searchable(text: $searchText, prompt: "Search cars...")
        }
        .preferredColorScheme(.dark)
        .onAppear { loadCars() }
    }

    private func loadCars() {
        guard let url = Bundle.main.url(forResource: "IndianVehicleData", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let makes = json["makes"] as? [[String: Any]] else { return }

        var entries: [CarEntry] = []
        for make in makes {
            guard let makeName = make["name"] as? String,
                  let models = make["models"] as? [[String: Any]] else { continue }
            for model in models {
                guard let modelName = model["name"] as? String else { continue }
                entries.append(CarEntry(make: makeName, model: modelName))
            }
        }
        cars = entries
    }
}
