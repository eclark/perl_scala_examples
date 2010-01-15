
import java.util.concurrent._

class CondVar[A] {
    private[this] val totalPermits = 50
    private[this] var beginEndPermits = 0;
    private[this] val lock: Semaphore = new Semaphore (totalPermits)
    var it: Option[A] = None

    lock.acquire(totalPermits);

    def begin = {
        beginEndPermits += 1
    }

    def end = {
        beginEndPermits -= 1
        if (beginEndPermits == 0) {
            send()
        }
    }

    def recv() = {
        lock.acquire(totalPermits);
        lock.release(totalPermits);
        it 
    }

    def send() = {
        lock.release(totalPermits - beginEndPermits);
        it = None
    }

    def send(thing: A) = {
        lock.release(totalPermits - beginEndPermits);
        it = Some(thing)
    }
}

