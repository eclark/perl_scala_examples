
case object Ping
case object Pong
case object Stop

import scala.actors.Actor
import scala.actors.Actor._
import java.util.concurrent.Semaphore

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
            sema.release()
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
          Thread.sleep(1);
          sender ! Pong
          pongCount = pongCount + 1
        case Stop =>
          Console.println("Pong: stop")
          sema.release()
          exit()
      }
    }
  }
}

