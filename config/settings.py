"""Application settings.

ORCA-DEMO: every credential in this file is FAKE (random, non-functional values
in the provider's format). They exist only so Orca Secret Detection has
something to find. Rotate-then-remove is the talk track; see DEMO.md.
"""

APP_NAME = "orca-appsec-demo"

# ORCA-DEMO: Secret – FAKE AWS access key ID + secret access key hardcoded in source
AWS_ACCESS_KEY_ID = "AKIAR7FWYUO5CPT2TPL2"
AWS_SECRET_ACCESS_KEY = "v/RG4jkeol9w8zjxF1AD514Ss61G6xeZQRqSGe5t"
AWS_REGION = "us-east-1"

# ORCA-DEMO: Secret – FAKE GitHub personal access token (classic, ghp_ format)
GITHUB_TOKEN = "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"

# ORCA-DEMO: Secret – FAKE RSA private key (freshly generated, never used anywhere)
JWT_SIGNING_KEY = """\
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAz1NIpykrjFUs9QZmmQhwg31nVHFHOND6X9y6bATnSO5DktAs
nONklvxIbjjYXb3+144PXt29B66VP1qlYVqfIzLrOCheSKMXx18QkSchLYb48kEC
0bnA41zGZImHr7eK2PkI6IJNQCLdPyM52kpw9kP3f1gD3PGvHc7lsjWQqIdsEVNE
UiApa16nIir7n2pS0GagoX/+hvqi4sf/aS7qZC1oMHQ/ThXSWpoX+7KpPAMPK7NO
exHg10L7tpEP5A/kL2BXuAVt1u4APObjFhBKbWZHNeMtccDU/mkLHepdDhz8vhBF
FqgEvihDWwLnjpFtvd3ZvYo8SzbVIgxDZFdcTQIDAQABAoIBAAocSaK9Qz5ouPSK
B17XJoWDDBL2Iz8GEe+y1/SEmLLZy7nRJRvRiwpB61ZUt1h6936TkvRRY/KH9QdN
6FrDDJeu2AG5Fj/8lCBI5ontmpSZzHIj8XtAz8NGtvYYLuHG1aKXInQURqgmCxwV
H7EhiDi6P8uaAzY3Iw8VE+aI7jEJsw9rq4/On+aSuDmYXWCam5+vUmjzEHcOGhwt
dXq9gPKEI2kmBWsOupeyNgbXov/FxXzrwTqQL4lyLXDhkG6alfqyHx9B1emwGVDs
/zMoeYzzEEMYBRidzOS8bS7VdttYcK8TDmcRhR/GOG1GGoVh1jwG9qbmMPhNF67q
9j/d/oECgYEA/EXvcJMDYNOWfOULpftawncCQb/zd3ZM4NPQ+67L5Y8NUciR2PRJ
v4qnnNeulkbsiZu7gyBq6fGphGlxq6xCTIvXU2TjnRID0MLLMP9/yhxKWYSmF9GZ
m8UoSFAQ9ap8Qj33v2JWN04eYA5/q04KWBLQa55841UnPYAIn2x6JPkCgYEA0mNc
ihimQj/IQuJm3bvFiHnWQ/IXd9YpBNbt6R5u5hKOJqSlUXA2onpV/NGKLKMA9DSN
49bas3to2rNo+njsTdgSpLwlkQwz9RT/K4HsuEXYjB4m9izlvaqRqydZbbt5USCj
IyvVysVRUjKti26i/X0jpMK1kXjwg8Rn1RVSSvUCgYEAnHmcfM0TSVm0fB9tzDRO
JVS/95xiHXUpVkLL23CeU/MZJeMsY8+SdtZABM7bIac4TFpmQn03E4irxs/Ii906
+lO66aUocWKdLz3D3s57qxdFHqViiF+f0bjGtaPEAT0P+d6J7xHFvGQd/yK/Gbg8
PkjdMgOKH0/QGRtzPb+BO7ECgYAR5Z/uo3ApPJHFlsrXW+zO0kZ22zZB3Hb60WnF
pfAbJELxaJojll8fbTa5Xf3aFDe1jm7vjcxm7j2aNR7eB8FaUeIsH1E2yIn29EVM
py3C8zYbnUkFMgaNHuBrZdqGqicEzrjx+f2i1Sw4yNTYgp3c4HNSxbl6WYZkPyXy
C3FHrQKBgB95IDU3Bho89NnzNW9jj0N1Rh8N2+ESWycY9u76AZ7bR7ciLNA+BrGd
NtrtJKeQiY/7OrKO2n1msadBQcKhSE+Z1sTrcxFhvlmG/ZkeiRbvW8q/cNGoWnhj
VjoGGk+T9vs5yXOiJAULSCAtxes45tyMyGXtYy0Zxj+IOs4gCHkw
-----END RSA PRIVATE KEY-----
"""
