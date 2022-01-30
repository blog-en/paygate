package payments

import io.gatling.core.Predef._
import io.gatling.http.Predef._
import scala.concurrent.duration._

class CircuitBreakerSimulation extends Simulation with Headers with HttpProtocol {

  val feeder_server_errors = jsonFile("feeds_server_errors.json").random

  //tag::CircuitBreakerSimulation[]
  val transfers_errors_1 = scenario("transfers server errors")
    .feed(feeder_server_errors)
    .exec(
      http("transfers request 1")
        .post("/payments/transfer")
        .headers(sentHeaders)
        .body(
          StringBody( // <1>
            """
                   {
                    "amount": 4230,
                    "to": "${to}",
                    "currency": "UGX"
                   }
               """)
        )
        .check(status.is(200))
    )
    .exec(
      http("transfers request 2")
        .post("/payments/transfer")
        .headers(sentHeaders)
        .body(
          StringBody( // <2>
            """
                   {
                    "amount": 4230,
                    "to": "${to}",
                    "currency": "UGX"
                   }
               """)
        )
        .check(status.is(200))
    )
    .exec(
      http("transfers request 3")
        .post("/payments/transfer")
        .headers(sentHeaders)
        .body(
          StringBody( // <3>
            """
                   {
                    "amount": 4230,
                    "to": "${to}",
                    "currency": "UGX"
                   }
               """)
        )
        .check(status.is(200))
    )
    .exec(
      http("transfers request 4")
        .post("/payments/transfer")
        .headers(sentHeaders)
        .body(
          StringBody(
            """
                   {
                    "amount": 4230,
                    "to": "${to}",
                    "currency": "UGX"
                   }
               """)
        )
        .check(status.is(502)) // <4>
    )
    .exec(
      http("transfers request 5")
        .post("/payments/transfer")
        .headers(sentHeaders)
        .body(
          StringBody(
            """
                   {
                    "amount": 4230,
                    "to": "${to}",
                    "currency": "UGX"
                   }
               """)
        )
        .check(status.is(502)) // <5>
    )
    .pause(6.seconds) // <6>
    .exec(
      http("transfers request 6")
        .post("/payments/transfer")
        .headers(sentHeaders)
        .body(
          StringBody(
            """
                   {
                    "amount": 4230,
                    "to": "${to}",
                    "currency": "UGX"
                   }
               """)
        )
        .check(status.is(200)) // <7>
    )
    .exec(
      http("transfers request 7")
        .post("/payments/transfer")
        .headers(sentHeaders)
        .body(
          StringBody(
            """
                   {
                    "amount": 4230,
                    "to": "${to}",
                    "currency": "UGX"
                   }
               """)
        )
        .check(status.is(502)) // <8>
    )
  // end::CircuitBreakerSimulation[]

  //tag::CircuitBreakerSimulation2[]
  setUp(
    transfers_errors_1
      .inject(atOnceUsers(1))
      .protocols(httpProtocol)
  )
  // end::CircuitBreakerSimulation2[]

}
