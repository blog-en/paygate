import Config

config :paygate,
       PaygateWeb.Endpoint,
       http: [
         transport_options: [
           socket_opts: [:inet6]
         ]
       ],
       server: true,
       check_origin: false
