package snyk
orgs := ["d0138106-2e76-4174-980b-e31daac65cc6","10f6c201-a59a-4a87-8aa8-a8f576567b76"]
default workload_events = false
workload_events {
    input.metadata.namespace == "default"
}
