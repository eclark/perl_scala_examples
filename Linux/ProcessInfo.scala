
package Linux

class ProcessInfo(val pid: Int) {
}

object ProcessInfo {
    def tree(val pid: Int) = new ProcessInfo(pid) 
}
