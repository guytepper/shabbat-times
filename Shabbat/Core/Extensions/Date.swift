import Foundation

extension Date {
  
  func hebrewDateString(from timeZone: TimeZone) -> (hebrewDay: String, month: String) {
    var calendar = Calendar(identifier: .hebrew)
    calendar.timeZone = timeZone
    
    let components = calendar.dateComponents([.day], from: self)
    let day = components.day ?? 1
    
    let formattedDay: String = Locale.current.identifier.hasPrefix("he") ? hebrewCalendarDay(from: day) : String(day)
    
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.timeZone = timeZone
    formatter.dateFormat = "MMMM"
    let month = formatter.string(from: self)
    
    return (formattedDay, month)
  }
  
}

private extension Date {
  
  func hebrewCalendarDay(from number: Int) -> String {
    if number <= 0 || number > 31 { return "" }
    if number == 15 { return "ט״ו" }
    if number == 16 { return "ט״ז" }

    let letters: [(Int, String)] = [
        (30, "ל"), (20, "כ"), (10, "י"), (9, "ט"), (8, "ח"),
        (7, "ז"), (6, "ו"), (5, "ה"), (4, "ד"), (3, "ג"),
        (2, "ב"), (1, "א")
    ]

    var num = number
    var components = [String]()

    for (value, letter) in letters where num >= value {
        let count = num / value
        components.append(String(repeating: letter, count: count))
        num %= value
        if num == 0 { break }
    }

    let joined = components.joined()
    return joined.count > 1
        ? joined.dropLast() + "״" + joined.suffix(1)
        : joined + "׳"
  }
}
