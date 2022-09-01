import XCTest
import Quick
import Nimble
@testable import HeapSwiftCore

private enum MyEnum: String {
    case val1 = "VALUE 1"
    case val2 = "VALUE 2"
}

extension MyEnum: HeapPropertyValue {
    var heapValue: String { rawValue }
}


final class EventConsumer_EventPropertiesSpec: HeapSpec {

    override func spec() {
        describe("EventConsumer.addEventProperties") {

            var dataStore: InMemoryDataStore!
            var consumer: EventConsumer<InMemoryDataStore>!

            beforeEach {
                dataStore = InMemoryDataStore()
                consumer = EventConsumer(dataStore: dataStore)
            }
            
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

            it("stores Int values") {
                
                consumer.startRecording("11")
                consumer.addEventProperties([
                    "a": 1,
                    "b": 0,
                    "c": -1,
                ])

                expect(consumer.eventProperties).to(equal([
                    "a": .init(value: "1"),
                    "b": .init(value: "0"),
                    "c": .init(value: "-1"),
                ]))
            }

            it("stores Double values") {

                consumer.startRecording("11")
                consumer.addEventProperties([
                    "a": 7.5,
                    "b": 0.0,
                    "c": -7.25,
                ])

                expect(consumer.eventProperties).to(equal([
                    "a": .init(value: "7.5"),
                    "b": .init(value: "0.0"),
                    "c": .init(value: "-7.25"),
                ]))
            }

            it("stores boolean values") {

                consumer.startRecording("11")
                consumer.addEventProperties([
                    "a": true,
                    "b": false,
                    "c": true,
                ])

                expect(consumer.eventProperties).to(equal([
                    "a": .init(value: "true"),
                    "b": .init(value: "false"),
                    "c": .init(value: "true"),
                ]))
            }

            it("stores string values") {

                consumer.startRecording("11")
                consumer.addEventProperties([
                    "a": "😀",
                    "b": "🤨",
                    "c": "😫",
                ])

                expect(consumer.eventProperties).to(equal([
                    "a": .init(value: "😀"),
                    "b": .init(value: "🤨"),
                    "c": .init(value: "😫"),
                ]))
            }

            it("stores custom values") {

                consumer.startRecording("11")
                consumer.addEventProperties([
                    "a": MyEnum.val1,
                    "b": MyEnum.val2,
                    "c": MyEnum.val1,
                ])

                expect(consumer.eventProperties).to(equal([
                    "a": .init(value: "VALUE 1"),
                    "b": .init(value: "VALUE 2"),
                    "c": .init(value: "VALUE 1"),
                ]))
            }

            it("persists data") {

                consumer.startRecording("11")
                consumer.addEventProperties([
                    "a": MyEnum.val1,
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

            var dataStore: InMemoryDataStore!
            var consumer: EventConsumer<InMemoryDataStore>!
            var originalState: EnvironmentState!

            beforeEach {
                dataStore = InMemoryDataStore()
                consumer = EventConsumer(dataStore: dataStore)

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

            var dataStore: InMemoryDataStore!
            var consumer: EventConsumer<InMemoryDataStore>!
            var originalState: EnvironmentState!

            beforeEach {
                dataStore = InMemoryDataStore()
                consumer = EventConsumer(dataStore: dataStore)

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
