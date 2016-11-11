resource "datadog_timeboard" "concourse-jobs" {
  title       = "${format("%s job runtime difference", var.env) }"
  description = "vs previous hour"
  read_only   = false

  graph {
    title = "Runtime changes vs hour ago"
    viz   = "change"

    request {
      q = "${format("avg:concourse.build.finished{bosh-deployment:%s} by {job}", var.env)}"
    }
  }

  graph {
    title = "CF pipeline run time"
    viz   = "timeseries"

    request {
      q = "${format("avg:concourse.pipeline_time{bosh-deployment:%s,pipeline_name:create-bosh-cloudfoundry}", var.env)}"
    }
  }

  graph {
    title = "Continuous smoke tests"
    viz   = "timeseries"

    request {
      q    = "${format("count_nonzero(avg:concourse.build.finished{build_status:failed,bosh-deployment:%s,bosh-job:continuous-smoke-tests})", var.env)}"
      type = "bars"

      style {
        palette = "warm"
      }
    }

    request {
      q    = "${format("count_nonzero(avg:concourse.build.finished{build_status:succeeded,bosh-deployment:%s,bosh-job:continuous-smoke-tests})", var.env)}"
      type = "bars"

      style {
        palette = "cool"
      }
    }
  }
}
