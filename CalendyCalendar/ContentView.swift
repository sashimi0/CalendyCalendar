//
//  ContentView.swift
//  CalendyCalendar
//
//  Created by sasha on 7/3/25.
//

import SwiftUI

struct CalendarView: View {
    let calendar = Calendar.current
    @State private var date = Date()
    let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    
    @State private var selectedDay: Int? = nil
    @State private var events: [String: [String]] = [:]  // Store events keyed by "yyyy-MM-dd"
    @State private var newEventText: String = ""

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .highPriorityGesture(
                    TapGesture().onEnded {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                )
            GeometryReader { geometry in
                VStack {
                    // Navigation buttons and month title
                    HStack {
                        Button(action: {
                            date = previousMonth(from: date)
                            selectedDay = nil
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                        }
                        
                        Spacer()
                        
                        Text(monthYearString(from: date))
                            .font(.title)
                            .padding()
                        
                        Spacer()
                        
                        Button(action: {
                            date = nextMonth(from: date)
                            selectedDay = nil
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.title2)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Days of week headers
                    HStack {
                        ForEach(daysOfWeek, id: \.self) { day in
                            Text(day)
                                .frame(maxWidth: .infinity)
                                .font(.headline)
                        }
                    }
                    
                    // Grid of days
                    let days = generateDays()
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                        ForEach(days, id: \.self) { day in
                            if day == 0 {
                                Text("")
                                    .frame(maxWidth: .infinity, minHeight: 40)
                            } else {
                                Button(action: {
                                    selectedDay = day
                                }) {
                                    VStack(spacing: 2) {
                                        Text("\(day)")
                                            .frame(maxWidth: .infinity, minHeight: 40)
                                            .background(day == currentDay() ? Color.blue.opacity(0.3) :
                                                        (day == selectedDay ? Color.green.opacity(0.3) : Color.clear))
                                            .cornerRadius(5)
                                        if events[dateKey(for: day)] != nil {
                                            Circle()
                                                .fill(Color.red)
                                                .frame(width: 6, height: 6)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Selected date events section
                    if let selected = selectedDay {
                        VStack(alignment: .leading, spacing: 8) {
                            let selectedDateKey = dateKey(for: selected)
                            Text("Events for \(selectedDateKey):")
                                .font(.headline)
                            
                            if let dayEvents = events[selectedDateKey], !dayEvents.isEmpty {
                                List {
                                    ForEach(dayEvents, id: \.self) { event in
                                        Text(event)
                                    }
                                    .onDelete { indexSet in
                                        events[selectedDateKey]?.remove(atOffsets: indexSet)
                                        saveEvents()
                                    }
                                }
                                .frame(height: 200)
                            } else {
                                Text("No events yet.")
                                    .italic()
                                    .padding(.leading, 8)
                            }
                            
                            HStack {
                                TextField("Add event...", text: $newEventText)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                Button("Add") {
                                    if !newEventText.isEmpty {
                                        events[selectedDateKey, default: []].append(newEventText)
                                        saveEvents()
                                        newEventText = ""
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                        .padding()
                    }
                }
                .padding()
                .frame(maxHeight: .infinity, alignment: .top)
            }
        }
        .onAppear {
            loadEvents()
        }
    }
    
    func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }
    
    func currentDay() -> Int {
        let components = calendar.dateComponents([.day], from: date)
        return components.day ?? 0
    }
    
    func generateDays() -> [Int] {
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let firstOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        var days: [Int] = Array(repeating: 0, count: firstWeekday - 1)
        days += Array(range)
        
        return days
    }
    
    func previousMonth(from date: Date) -> Date {
        calendar.date(byAdding: .month, value: -1, to: date) ?? date
    }
    
    func nextMonth(from date: Date) -> Date {
        calendar.date(byAdding: .month, value: 1, to: date) ?? date
    }
    
    func dateKey(for day: Int) -> String {
        let components = calendar.dateComponents([.year, .month], from: date)
        var dateComponents = components
        dateComponents.day = day
        let selectedDate = calendar.date(from: dateComponents) ?? Date()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: selectedDate)
    }
    
    func saveEvents() {
        if let data = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(data, forKey: "savedEvents")
        }
    }
    
    func loadEvents() {
        if let data = UserDefaults.standard.data(forKey: "savedEvents"),
           let saved = try? JSONDecoder().decode([String: [String]].self, from: data) {
            events = saved
        }
    }
}

#Preview {
    CalendarView()
}
