# AsyncSwift

Framework for async tasks in Swift using futures and async-await syntax.

## How to use:
1) You may get the source directly.
2) Using cocoa pods
	```
	pod "SomeAsyncSwift"	
	```
	and in your swift files:
	```swift
	import SomeAsyncSwift
	```

## Asynchronous programming: futures, async, await

Asynchronous operations let your program complete work while waiting for another operation to finish. Here are some common asynchronous operations:
  * Fetching data over a network.
  * Writing to a database.
  * Reading data from a file.
  
AsyncSwift allows you to use ```AsyncAwaitFuture``` class and ```async``` ```await``` keywords.

For simplicity ```AsyncAwaitFuture``` has a simple name ```AFuture```

# ```AFuture```

```AFuture``` is a generic class with parameter ```result``` of a generic type.
```AFuture<Void>``` could be called as ```SomeFuture```

Future is an instance of ```AFuture``` class with some result type.
A future represents the result of an asynchronous operation, and can have two states: ```resolved == true``` , ```resolved == false```
Also it provides substate ```hasError``` due to future could be resolved not only with success but also woth error.

In case of resolved future can provide the result.
```result``` property is a read only property of generic type, and it can be nil.
Future could be resolved with ```nil``` result. This does not mean somthing is wrong. 
So to determine if future is resolved you should check ```resolved``` property.
In case of error ```resolved``` property shows ```true``` but also ```hasError``` property shows ```true```
Exactly error could be found in ```Error``` property. It has an ```Any?``` type and could be nil.


# Examples:
```swift
    let future1 = SomeFuture.delay(3)
```
  Here ```future1``` is a ```AsyncAwaitFuture<Void>``` and it will be resolved after 3 seconds.
  
  ```swift
  	let future2: AFuture<Int> = async {
		for _ in 1...1000000 {
			//do something
		}
		return 10 //resolve with 10
	}
  ```
  
  The special constraction ```async``` returns a future. Will be described in details later.
  
  here ```future2``` is a ```AsyncAwaitFuture<Int>``` and it will be resolved with 10 after the cicle finished.
  
  ```swift
    let future3 = SomeFuture.wait([future1, future2])
  ```
  
  Here ```future3``` is a ```AsyncAwaitFuture<Void>``` and it will be resolved after ```future1``` and ```future2``` be resolved.
  
  To wait for ```future1``` and ```future2``` you could use ```await``` keyword wich is just a function in this realization.
  
  ```swift
  try! await(SomeFuture.wait([future1, future2]))
  ```
  
  In this case your current thread will be waiting for ```future1``` and ```future2```
  
  
  # Working with futures: async and await
  
  The ```async``` and ```await``` keywords provide a declarative way to define asynchronous functions and use their results. 
  
  If the function has a declared return type, then update the type to be ```AFuture<T>```, where T is the type of the value that the function returns. If the function doesn’t explicitly return a value, then the return type is ```AFuture<void>``` or ```SomeFuture```
  The function should use ```async``` keyword inside it's body:
  
  ```swift
  func f0() -> AFuture<Int> {
	async {
		sleep(2) //to imitate some work in BG.
		return 1
	}
}
  ```
  
  This function could have parameters:
  
  ```swift
    func f1(_ a: Int) -> AFuture<Int> {
    	async {
		sleep(2)
		return a
       }
    }
  ```
  For such functions you may directly use ```await``` to make your code wait future to be resolved
  ```swift
	let result = try! await(f1(5))
  ```
  
  You may use functions to obtain futures and observe it's states.
  To bserve future states you may use several ways:
  
  ```onSuccess``` method. It will be called after the future been resolved.
  If call ```onSuccess``` to resolved future, it will be called immediately.
  
```swift
 future.onResolved { result in
	print(" Future resolved with:\(result)")
}
```
  
  ```then``` is close to ```onSuccess``` but returns the future wich waits for first future been resolved.
  This allows you to create future's chain
  Then has an argument of type which it will embade to it's future.
  
```swift
let future = findEntryPoint().then(EntryPoint.self) { entryPoint in
	guard let validEntryPoint = entryPoint else { fatalError()}
	return self.runFromEnryPoint(validEntryPoint)
}.then(Void.self, finishChainWithOptinalParameter)
```
 In this example all functions return future objects, so are async functions.
 
 ```always``` is close to ```onSuccess``` but also works in case of errors. 
 
 The last example could be recreated with ```async await``` constractions
```swift
 	  let entryPoint = await(findEntryPoint())
		guard let validEntryPoint = entryPoint else { fatalError() /*to test exceptions*/}
		let result = await(self.runFromEnryPoint(validEntryPoint))
```
 
 If you don't whant your thread to be waiting in ```await``` make sure you call it inside ```async```
 ```async``` will return future you may subscribe on.
 
 
 ## note: future does not keep ref. to itself. It means you should always keep ref.to future before it finished it's work.
 
 
# ```await```

```await``` is a function wich makes your current thread be waiting for future been resolved.
It throws an AFutureErrors.FutureError if future has been resolved with an error.

In case of using functions not returning future you may use ```await``` variants which takes arguments and function.
it takes arguments (from 0 up to 10)* and a function not returning ```AFuture``` and produces an ```AFuture<Type>``` where ```Type``` is your function return type.
 
* if you need more then 10 arguments you need create ```await``` yourself.
 
 # Handling errors:
 
 ## How to produce error:
Future can produce an error in case of it's async function throws an exception
	
```swift
let future: AFuture<Int> = async {
	for i in 1...1000000 {
		if i == 10000 {
			throw(TestErrors.testExcepton(howMany: i))
		}
	}
	return 10
}
```  
In this example future will not return 10. Instead it will have an error of type ```TestErrors```
Here is error type:
```swift
	enum TestErrors: Error {
		case testExcepton(howMany: Int)
	}
```
  
## How to handle errors in future:

```await``` throws in case of error in future.
So the first way is regular exceptions handling. 

But you may use ```try!``` before ```Future.wait``` due to it never thows.

Take a look at this example:

```swift
func testException() {
	let future: AFuture<Int> = async {
		for i in 1...1000000 {
			if i == 10000 {
				throw(TestErrors.testExcepton(howMany: i))
			}
		}
		return 10
	}
	
	try! await(SomeFuture.wait([future]))
	XCTAssert(future.resolved)
	XCTAssert(future.hasError)
	let error = future.error
	if let validError = error as? TestErrors {
		switch validError {
		case .testExcepton(let howMany): XCTAssert(howMany == 10000)
		}
	} else {
		XCTAssert(false)
	}
}
```
So as you can see ```SomeFuture.wait([future])``` works as if future has been resolved with value.
But it will have an error instead.

You also may use ```onError``` handler.
It works in the same way as ```onSuccess``` but in case of error.

If you want to fix the problem use ```catchError```

Example of future chaining:
```swift
func testChain() {
	var gotThenBlock = false
	var wasInThen    = false
	var wasInAlways  = false
	let future: AFuture<String> = async { () -> Int in
		for i in 1...1000000 {
			if i == 10000 {
				throw(TestErrors.testExcepton(howMany: i))
			}
		}
		return 10
	}.then(String.self) { result in
		gotThenBlock = true
		return async {
			wasInThen = true
			return "Ten"
		}
	}.catchError { _ in
		return "10000"
	}.always {
		wasInAlways = true
	}

	let result = await(future)
	XCTAssert(result == "10000")
	XCTAssert(wasInAlways)
	XCTAssert(!gotThenBlock)
	XCTAssert(!wasInThen)
}
```

In this test we have the first future provides ```Int``` result and next future provides ```String```
But the first future provides an error. We catch it by ```catchError``` and provides fixed value here.
Note: ```catchError``` is a new future itself. It means it also could have ```then``` and could provides error.
So you could have several ```catchError```s one after another. 

```Always``` will be called in any case.

## Handling errors in ```await```

1st variant is to use standard ```try-catch``` as ```await``` trhows in case of ```Future``` has an error.

Due to ```await``` takes ```AFuture``` you may produce ```catchError``` to the future
If ```catchError``` produces the value always you may just use ```try!```
This is not recommended way due to ```catchError``` may also returns an error.
Here this is done for simplicity.

```swift
func testExceptionsInAwait() {
	let future: AFuture<Int> = async {
		for i in 1...1000000 {
			if i == 10000 {
				throw(TestErrors.testExcepton(howMany: i))
			}
		}
		return 10
	}
	let result = try! await(future.catchError { error in
		if let validError = error as? TestErrors {
			switch validError {
			case .testExcepton(let howMany): XCTAssert(howMany == 10000)
			}
		} else {
			XCTAssert(false)
		}
		
		return 20
	})
	
	XCTAssert(result == 20)
}
```

If you use ```await``` to function wich does not provide future you don't have such oportunity but first way ```try-catch``` is awailable.

## Streams and Async observable properties 

Take a look at `AsyncObservablesTests` and `StreamTests` for examples.


