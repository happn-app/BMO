# BMO
Linking any local database (CoreData, Realm, etc.) to any API (REST, SOAP, etc.)

## For Maintainers
The `XCODE_XCCONFIG_FILE` part of the command line below is optional; it allows dependencies
to be compiled as static Frameworks instead of dynamic ones. As we’re not building an executable
here and the dependencies will be compiled by the clients anyway, it won’t change much how the
dependencies are compiled.
```
XCODE_XCCONFIG_FILE="$(pwd)/Xcode Supporting Files/StaticCarthageBuild.xcconfig" carthage update --use-ssh
```
