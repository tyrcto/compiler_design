/*
 * Example with Functions
 */

class example {
  // constants
  val a = 5

  // variables
  var c : int

  // function declaration
  fun add (a: int, b: int) : int {
    return a+b
  }

  fun sub5(a: int) : int{
    var c = 5
    var d : int
    d = 9
    return a-c
  }
  
  // main statements
  fun main() {
    c = add(a, 11)
    c = sub5(c)
    if (c > 10)
      print -c
    else
      print c
    println ("Hello World")
  }
}
