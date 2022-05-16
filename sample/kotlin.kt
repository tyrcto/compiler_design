fun main() {
    cases("Hello")
    cases(1)
    cases(0L)
    cases(MyClass())
    cases("hello")
}

fun cases(obj: Any) {                                
    when (obj) {                                     // 1   
        1 -> println("One")                          // 2
        "Hello" -> println("Greeting")               // 3
        is Long -> println("Long")                   // 4
        !is String -> println("Not a \"string\"")        // 5
        else -> println("Unknown")                   // 6
    }   
}

fun Float.toExactDouble(): Double = 
    this.toString().toDouble()

val myDouble = 123.456f.toExactDouble()
