
import org.perl.inline.java._

class HelpMePerl {
    val pi = new InlineJavaPerlCaller

    def xmatch(target: String, pattern: String): Boolean = {
        val b = pi.eval("'" + target + "' =~ /" + pattern + "/", classOf[Boolean])
        return b.asInstanceOf[Boolean]
    }
}

