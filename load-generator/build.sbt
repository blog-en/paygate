import Dependencies._

enablePlugins(GatlingPlugin)

lazy val root = (project in file("."))
  .settings(
    inThisBuild(List(
      organization := "org.load",
      scalaVersion := "2.13.8",
      version := "0.1.0-SNAPSHOT"
    )),
    name := "load-generator",
    libraryDependencies ++= gatling
  )

addCommandAlias("r", ";gatling:testOnly payments.CircuitBreakerSimulation")
addCommandAlias("r2", ";gatling:testOnly payments.CollectingFailedTransfersAndChargesSimulation")
// grafana:
addCommandAlias("rate_limiting_showcase", ";gatling:testOnly payments.CollectingFailedTransfersSimulation")
addCommandAlias("r4", ";gatling:testOnly payments.OkLimitSimulation")
addCommandAlias("rl", ";reload")
addCommandAlias("c", ";compile")
