package payments

import io.gatling.core.Predef._
import io.gatling.http.Predef._

import scala.concurrent.duration._

class CollectingFailedTransfersAndChargesSimulation extends Simulation with HttpProtocol with Transfers {

  // tag::CollectingFailedTransfersAndChargesSimulation[]
  setUp(

    transfers_1
      .inject(constantUsersPerSec(4).during(4.minutes))
      .protocols(httpProtocol)
      .throttle(
        reachRps(3).in(10.seconds),
        holdFor(10.seconds),
        jumpToRps(4),
        holdFor(3.minutes),
        jumpToRps(2),
        holdFor(40.seconds)
      ),
//    charges_1
//      .inject(constantUsersPerSec(3).during(4.minutes))
//      .protocols(httpProtocol)
//      .throttle(
//        reachRps(2).in(10.seconds),
//        holdFor(10.seconds),
//        jumpToRps(2),
//        holdFor(3.minutes),
//        jumpToRps(2),
//        holdFor(40.seconds)
//      ),
  )
    .assertions(
      global
        .failedRequests
        .count
        .between(177, 183, inclusive = true)
    )
  // end::CollectingFailedTransfersAndChargesSimulation[]
}

