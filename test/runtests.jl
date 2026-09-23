using TestItemRunner

@run_package_tests verbose=true filter=ti -> (
  !(:integration in ti.tags) || get(ENV, "CENSOBR_INTEGRATION_TESTS", "false") == "true"
)
