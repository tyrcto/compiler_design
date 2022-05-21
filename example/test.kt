class test{
    var a: int [10]
    var d: int = 1
    fun sayHi(){
        var i: int
        for(i in 0..4)
            print "Hi!\n"
    }
    
    fun main(){
        sayHi()
        a[1] = 1
    }
}
