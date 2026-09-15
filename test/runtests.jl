using TestItemRunner

if get(ENV, "CENSOBR_INTEGRATION_TESTS", "false") == "true"
    @run_package_tests
else
    @run_package_tests filter = ti -> !(:integration in ti.tags)
end