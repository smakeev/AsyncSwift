# AsyncSwift
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

In case of resolved future can provide the result.
```result``` property is a read only property of generic type, and it can be nil.
Futurw could be resolved with ```nil``` result. 
So to determine if future is resolved you should check ```resolved``` property.

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
  await(SomeFuture.wait([future1, future2]))
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
  
  You may use functions to obtain futures and observe it's states.
  To bserve future states you may use several ways:
  
  ```onResolved``` method. It will be called after the future been resolved.
  If call ```onResolved``` to resolved future, it will be called immediately.
  
  ```swift
  		future.onResolved { result in
        print(" Future resolved with:\(result)")
		}
  ```
  
  ```then``` is close to ```onResolved``` but returns the future wich waits for first future been resolved.
  This allows you to create future's chain
  Then has an argument of type which it will embade to it's future.
  
  ```swift
 		let future = findEntryPoint().then(EntryPoint.self) { entryPoint in
			guard let validEntryPoint = entryPoint else { fatalError()}
			return self.runFromEnryPoint(validEntryPoint)
		}.then(Void.self, finishChainWithOptinalParameter)
 ```
 ```always``` is close to ```onResolved``` but also works in case of errors. Will be added in future releases.
 
 The last example could be recreated with ```async await``` constractions
 
 ```swift
 	  let entryPoint = await(findEntryPoint())
		guard let validEntryPoint = entryPoint else { fatalError() /*to test exceptions*/}
		let result = await(validEntryPoint, self.runFromEnryPoint)
 ```
 
 If you don't whant your thread to be waiting in ```await``` make sure you call it insude ```async```
 ```async``` will return future you may subscribe on.
 
 
 ## note: future does not keep ref. to itself. It means you should always keep ref.to future before it finished it's work.
 
 

  
