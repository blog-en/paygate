package payments

import io.gatling.core.Predef._
import io.gatling.http.Predef._

trait Charges extends Headers{

  val charges_1= scenario("charges ok") // A scenario is a chain of requests and pauses
    .exec(
      http("charges requests") // Here's an example of a POST request
        .post("/payments/charge")
        .headers(sentHeaders)
        .body(
          StringBody(
            """{
                        "amount": 230,
                        "from": "2325215134",
                        "currency": "UGX"
                      }
               """)
        )
        .check(status.is(200))
    )
}
