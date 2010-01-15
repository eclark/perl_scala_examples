
package Linux

class ProcessInfo(val pid: Int) {
    def this() = this(-1)
}

object ProcessInfo {
    def tree(pid: Int) = new ProcessInfo(pid) 
}
