package payments

import io.gatling.core.Predef._
import io.gatling.http.Predef._

import scala.concurrent.duration._

class CollectingFailedTransfersSimulation extends Simulation with Charges with Transfers with HttpProtocol {

  //tag::CollectingFailedTransfersSimulation[]
      setUp(
        transfers_1
          .inject(constantUsersPerSec(6).during(4.minutes))
          .protocols(httpProtocol)
          .throttle(
            reachRps(5).in(10.seconds), // <1>
            holdFor(10.seconds), // <2>
            jumpToRps(6), // <3>
            holdFor(3.minutes), // <4>
            jumpToRps(4), // <5>
            holdFor(40.seconds) // <6>
          )
      )
        .assertions(
          details("transfers requests")
            .failedRequests
            .count
            .between(177, 183, inclusive = true) // <7>
        )
  // end::CollectingFailedTransfersSimulation[]

}
