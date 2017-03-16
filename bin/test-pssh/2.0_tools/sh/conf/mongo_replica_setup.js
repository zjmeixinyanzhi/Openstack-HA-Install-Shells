config = { _id:"ceilometer", members: [{ _id: 0, host: "controller01:27017" }, { _id: 1, host: "controller02:27017" } , { _id: 2, host:
"controller03:27017" }]}
rs.initiate(config)
