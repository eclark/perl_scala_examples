
package Linux

class ProcessInfo(val pid: Int) {
}

object ProcessInfo {
    def tree(val pid: Int) = new ProcessInfo(pid) 
}

// vim: set ts=4 sw=4 et:
