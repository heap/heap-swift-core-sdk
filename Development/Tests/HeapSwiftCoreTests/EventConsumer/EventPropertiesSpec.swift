import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore
@testable import HeapSwiftCoreTestSupport

final class EventConsumer_EventPropertiesSpec: HeapSpec {

    override func spec() {
        
        var dataStore: InMemoryDataStore!
        var consumer: EventConsumer<InMemoryDataStore, InMemoryDataStore>!

        beforeEach {
            dataStore = InMemoryDataStore()
            consumer = EventConsumer(stateStore: dataStore, dataStore: dataStore)
            HeapLogger.shared.logLevel = .trace
        }
        
        afterEach {
            HeapLogger.shared.logLevel = .info
        }
        
        describe("EventConsumer.addEventProperties") {
            
            it("doesn't do anything before `startRecording` is called") {
                
                consumer.addEventProperties(["a": 1])
                consumer.startRecording("11")

                expect(consumer.eventProperties).to(equal([:]))
            }
            
            it("doesn't do anything after `stopRecording` is called") {
                
                consumer.startRecording("11")
                consumer.stopRecording()
                consumer.addEventProperties(["a": 1])
                consumer.startRecording("11")

                expect(consumer.eventProperties).to(equal([:]))
            }

            it("stores values") {
                
                consumer.startRecording("11")
                consumer.addEventProperties([
                    "a": 1,
                    "b": "Hello 🗺",
                    "c": false,
                ])

                expect(consumer.eventProperties).to(equal([
                    "a": .init(value: "1"),
                    "b": .init(value: "Hello 🗺"),
                    "c": .init(value: "false"),
                ]))
            }
            
            it("sanitizes properties using [String: HeapPropertyValue].sanitized") {

                consumer.startRecording("11")
                consumer.addEventProperties([
                    "a": String(repeating: "あ", count: 1030),
                    "b": "    ",
                    " ": "test",
                    String(repeating: "あ", count: 513): "?",
                ])

                expect(consumer.eventProperties).to(equal([
                    "a": .init(value: String(repeating: "あ", count: 1024)),
                ]))
            }

            it("persists data") {

                consumer.startRecording("11")
                consumer.addEventProperties([
                    "a": String(repeating: "あ", count: 1030),
                    "b": "Hello 🗺",
                    "c": false,
                ])

                let state = dataStore.loadState(for: "11")

                expect(state.properties).to(equal(consumer.eventProperties))
            }

            it("overwrites existing values") {

                consumer.startRecording("11")
                consumer.addEventProperties([
                    "a": "a",
                    "b": false,
                ])
                consumer.addEventProperties([
                    "b": "b",
                    "c": "c",
                ])

                expect(consumer.eventProperties).to(equal([
                    "a": .init(value: "a"),
                    "b": .init(value: "b"),
                    "c": .init(value: "c"),
                ]))
            }
        }

        describe("EventConsumer.removeEventProperty") {

            var originalState: EnvironmentState!

            beforeEach {
                originalState = dataStore.loadState(for: "11")
                originalState.userID = "123"
                originalState.properties = [
                    "a": .init(value: "1"),
                    "b": .init(value: "2"),
                ]
                dataStore.save(originalState)
            }
            
            it("doesn't do anything before `startRecording` is called") {

                consumer.removeEventProperty("a")
                consumer.startRecording("11")

                expect(consumer.eventProperties).to(equal(originalState.properties))
            }
            
            it("doesn't do anything after `stopRecording` is called") {

                consumer.startRecording("11")
                consumer.stopRecording()
                consumer.removeEventProperty("a")
                consumer.startRecording("11")

                expect(consumer.eventProperties).to(equal(originalState.properties))
            }

            it("does nothing if the property doesn't exist") {

                consumer.startRecording("11")
                consumer.removeEventProperty("c")

                expect(consumer.eventProperties).to(equal(originalState.properties))
            }

            it("removes the property with that name") {

                consumer.startRecording("11")
                consumer.removeEventProperty("a")

                expect(consumer.eventProperties).to(equal([
                    "b": .init(value: "2"),
                ]))
            }

            it("persists data") {

                consumer.startRecording("11")
                consumer.removeEventProperty("a")

                let state = dataStore.loadState(for: "11")

                expect(state.properties).to(equal(consumer.eventProperties))
            }
        }

        describe("EventConsumer.clearEventProperties") {

            var originalState: EnvironmentState!

            beforeEach {
                originalState = dataStore.loadState(for: "11")
                originalState.userID = "123"
                originalState.properties = [
                    "a": .init(value: "1"),
                    "b": .init(value: "2"),
                ]
                dataStore.save(originalState)
            }
            
            it("doesn't do anything before `startRecording` is called") {

                consumer.clearEventProperties()
                consumer.startRecording("11")

                expect(consumer.eventProperties).to(equal(originalState.properties))
            }
            
            it("doesn't do anything after `stopRecording` is called") {

                consumer.startRecording("11")
                consumer.stopRecording()
                consumer.clearEventProperties()
                consumer.startRecording("11")

                expect(consumer.eventProperties).to(equal(originalState.properties))
            }

            it("removes all event properties") {

                consumer.startRecording("11")
                consumer.clearEventProperties()

                expect(consumer.eventProperties).to(beEmpty())
            }

            it("persists data") {

                consumer.startRecording("11")
                consumer.clearEventProperties()

                let state = dataStore.loadState(for: "11")

                expect(state.properties).to(equal(consumer.eventProperties))
            }
        }
    }
}
