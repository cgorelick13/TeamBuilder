import SwiftUI

/// A labeled horizontal stat bar colored by value range.
/// Red = 0–49, Yellow = 50–79, Green = 80+
struct StatBar: View {
    let label: String
    let value: Int
    let maxValue: Int

    private var fillFraction: Double {
        Double(value) / Double(maxValue)
    }

    private var barColor: Color {
        switch value {
        case 0...49:  return .red
        case 50...79: return .yellow
        default:      return .green
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .trailing)

            Text("\(value)")
                .font(.caption.monospacedDigit())
                .frame(width: 32, alignment: .trailing)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.systemFill))
                    Capsule()
                        .fill(barColor)
                        .frame(width: geo.size.width * fillFraction)
                }
            }
            .frame(height: 8)
        }
    }
}
