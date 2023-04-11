//
//  iOSWidget.swift
//  iOSWidget
//
//  Created by Bryan Mitchell on 9/22/22.
//

import WidgetKit
import SwiftUI
import HeapSwiftCore

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []
        entries.append(SimpleEntry(date: Date()))
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct iOSWidgetEntryView : View {
    var entry: Provider.Entry
    
    func rendered() {
        
        Heap.shared.logLevel = .debug
        print("👍 Widget was rendered, and tracked")
        Heap.shared.startRecording("11")
        Heap.shared.track("Widget Rendered")
    }
    
    var body: some View {
        Text(entry.date, style: .time).onAppear { self.rendered() }
    }
}

@main
struct iOSWidget: Widget {
    let kind: String = "iOSWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            iOSWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

struct iOSWidget_Previews: PreviewProvider {
    static var previews: some View {
        iOSWidgetEntryView(entry: SimpleEntry(date: Date()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
