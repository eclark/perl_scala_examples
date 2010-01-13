
object Hello {
  def main(args: Array[String]) {
    println("Hello, dudes! " + args.toList)
  }
}

class Semaphore {
    var count = 0;
    val lock: AnyRef = new Object()

//    def count(): Int = lock.synchronized {
//        count
//    }
    def incr(): Int = lock.synchronized {
        count += 1
        count
    }
    def decr(): Int = lock.synchronized {
        count -= 1
        count
    }
}

case object Ping
case object Pong
case object Stop

import scala.actors.Actor
import scala.actors.Actor._

class Ping(sema: Semaphore, count: Int, pong: Actor) extends Actor {
  def act() {
    var pingsLeft = count - 1
    pong ! Ping
    loop {
      react {
        case Pong =>
          if (pingsLeft % 1000 == 0)
            Console.println("Ping: pong")
          if (pingsLeft > 0) {
            pong ! Ping
            pingsLeft -= 1
          } else {
            Console.println("Ping: stop")
            pong ! Stop
            sema.decr()
            exit()
          }
      }
    }
  }
}

class Pong(sema: Semaphore) extends Actor {
  def act() {
    var pongCount = 0
    loop {
      react {
        case Ping =>
          if (pongCount % 1000 == 0)
            Console.println("Pong: ping "+pongCount)
          sender ! Pong
          pongCount = pongCount + 1
        case Stop =>
          Console.println("Pong: stop")
          sema.decr()
          exit()
      }
    }
  }
}

