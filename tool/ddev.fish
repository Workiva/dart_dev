function __fish_ddev_needs_command
  set cmd (commandline -opc)
  if [ (count $cmd) -eq 1 -a $cmd[1] = 'ddev' ]
    return 0
  end
  return 1
end

function __fish_ddev_using_command
  set cmd (commandline -opc)
    if [ (count $cmd) -gt 1 ]
      if [ $argv[1] = $cmd[2] ]
        return 0
      end
    end
  return 1
end

## ddev
complete -fc ddev -n '__fish_ddev_needs_command' -l help
complete -fc ddev -n '__fish_ddev_needs_command' -l quiet
complete -fc ddev -n '__fish_ddev_needs_command' -l version
complete -fc ddev -n '__fish_ddev_needs_command' -l color
complete -fc ddev -n '__fish_ddev_needs_command' -l no-color

## ddev init
complete -fc ddev -n '__fish_ddev_needs_command' -a init

## ddev copy-license
complete -fc ddev -n '__fish_ddev_needs_command' -a copy-license

## ddev analyze
complete -fc ddev -n '__fish_ddev_needs_command' -a analyze
complete -fc ddev -n '__fish_ddev_using_command analyze' -l help
complete -fc ddev -n '__fish_ddev_using_command analyze' -l fatal-warnings -d 'Treat non-type warnings as fatal'
complete -fc ddev -n '__fish_ddev_using_command analyze' -l no-fatal-warnings -d 'Do not treat non-type warnings as fatal'
complete -fc ddev -n '__fish_ddev_using_command analyze' -l fatal-hints -d 'Treat hints as fatal'
complete -fc ddev -n '__fish_ddev_using_command analyze' -l no-fatal-hints -d 'Do not treat hints as fatal'
complete -fc ddev -n '__fish_ddev_using_command analyze' -l strong -d 'Enable strong static checks (https://goo.gl/DqcBsw)'
complete -fc ddev -n '__fish_ddev_using_command analyze' -l no-strong -d 'Do not enable strong static checks (https://goo.gl/DqcBsw)'

## ddev coverage
complete -fc ddev -n '__fish_ddev_needs_command' -a coverage
complete -fc ddev -n '__fish_ddev_using_command coverage' -l help
complete -fc ddev -n '__fish_ddev_using_command coverage' -l unit -d 'Include the unit test suite'
complete -fc ddev -n '__fish_ddev_using_command coverage' -l no-unit -d 'Do not include the unit test suite'
complete -fc ddev -n '__fish_ddev_using_command coverage' -l integration -d 'Include the integration test suite'
complete -fc ddev -n '__fish_ddev_using_command coverage' -l no-integration -d 'Do not include the integration test suite'
complete -fc ddev -n '__fish_ddev_using_command coverage' -l functional -d 'Include the functional test suite'
complete -fc ddev -n '__fish_ddev_using_command coverage' -l no-functional -d 'Do not include the functional test suite'
complete -fc ddev -n '__fish_ddev_using_command coverage' -l html -d 'Generate and open an HTML report'
complete -fc ddev -n '__fish_ddev_using_command coverage' -l no-html -d 'Do not generate and open an HTML report'
complete -fc ddev -n '__fish_ddev_using_command coverage' -l pub-serve -d 'Serve browser tests using a Pub server'
complete -fc ddev -n '__fish_ddev_using_command coverage' -l no-pub-serve -d 'Do not serve browser tests using a Pub server'
complete -fc ddev -n '__fish_ddev_using_command coverage' -l open -d 'Open the HTML report automatically'
complete -fc ddev -n '__fish_ddev_using_command coverage' -l no-open -d 'Open the HTML report automatically'

## ddev docs
complete -fc ddev -n '__fish_ddev_needs_command' -a docs
complete -fc ddev -n '__fish_ddev_using_command docs' -l help
complete -fc ddev -n '__fish_ddev_using_command docs' -l open -d 'Open the docs site after being generated'
complete -fc ddev -n '__fish_ddev_using_command docs' -l no-open -d 'Do not open the docs site after being generated'

## ddev examples
complete -fc ddev -n '__fish_ddev_needs_command' -a examples
complete -fc ddev -n '__fish_ddev_using_command examples' -l help
complete -fc ddev -n '__fish_ddev_using_command examples' -l hostname -d 'The host name to listen on'
complete -fc ddev -n '__fish_ddev_using_command examples' -l port -d 'The base port to listen on'

## ddev format
complete -fc ddev -n '__fish_ddev_needs_command' -a format
complete -fc ddev -n '__fish_ddev_using_command format' -l help
complete -fc ddev -n '__fish_ddev_using_command format' -l check -d 'Dry-run; checks if formatter needs to be run and sets exit code accordingly'
complete -fc ddev -n '__fish_ddev_using_command format' -s l -l line-length -d 'Wrap lines longer than this'

## ddev test
complete -fc ddev -n '__fish_ddev_needs_command' -a test
complete -fc ddev -n '__fish_ddev_using_command test' -l help
complete -fc ddev -n '__fish_ddev_using_command test' -l unit -d 'Include the unit test suite'
complete -fc ddev -n '__fish_ddev_using_command test' -l no-unit -d 'Do not include the unit test suite'
complete -fc ddev -n '__fish_ddev_using_command test' -l integration -d 'Include the integration test suite'
complete -fc ddev -n '__fish_ddev_using_command test' -l no-integration -d 'Do not include the integration test suite'
complete -fc ddev -n '__fish_ddev_using_command test' -l functional -d 'Include the functional test suite'
complete -fc ddev -n '__fish_ddev_using_command test' -l no-functional -d 'Do not include the functional test suite'
complete -fc ddev -n '__fish_ddev_using_command test' -s j -l concurrency -d 'The number of concurrent test suites run'
complete -fc ddev -n '__fish_ddev_using_command test' -l pub-serve -d 'Serve browser tests using a Pub server'
complete -fc ddev -n '__fish_ddev_using_command test' -l no-pub-serve -d 'Do not serve browser tests using a Pub server'
complete -fc ddev -n '__fish_ddev_using_command test' -s p -l platform -d 'The platform(s) on which to run the tests.\n[vm (default), dartium, content-shell, chrome, phantomjs, firefox, safari]'
complete -fc ddev -n '__fish_ddev_using_command test' -s n -l name -d 'A substring of the name of the test to run (Regular expression syntax is supported)'
