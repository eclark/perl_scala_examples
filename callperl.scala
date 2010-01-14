
import org.perl.inline.java._

object HelpMePerl extends Application {
    val pi = InlineJavaPerlInterpreter.create()

    def matches(target: String, pattern: String): Boolean = {
        val b = pi.eval("'" + target + "' =~ /" + pattern + "/", classOf[Boolean])
        return b.asInstanceOf[Boolean]
    }

    val target = "aaabbbccc"
    val pattern = "ab+"
    val ret = matches(target, pattern)

    println(target + (if(ret) " matches " else " doesn't match ") + pattern)
}

